"""
Generates the synthetic dataset for the e-commerce funnel project.
Deterministic: random.seed(42) -> same CSVs every run.
"""
import csv, os, random
from datetime import datetime, timedelta

random.seed(42)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(OUT, exist_ok=True)

START = datetime(2025, 1, 1)
DAYS = 180

CITIES = ["Hyderabad", "Bengaluru", "Mumbai", "Delhi", "Pune", "Chennai"]
CHANNELS = ["organic", "paid_ads", "email", "social", "direct"]
DEVICES = ["mobile_app", "mobile_web", "desktop"]

CATEGORIES = {
    "Fruits & Vegetables": (30, 260, 0.74),
    "Dairy & Eggs":        (25, 320, 0.80),
    "Bakery":              (20, 180, 0.78),
    "Beverages":           (35, 450, 0.93),
    "Snacks":              (20, 350, 0.95),
    "Personal Care":       (60, 900, 0.96),
    "Household":           (45, 700, 0.94),
    "Packaged Staples":    (50, 1200, 0.90),
}

NOUNS = ["Fresh", "Daily", "Gold", "Classic", "Pure", "Farm", "Prime", "Value",
         "Select", "Natural", "Everyday", "Choice", "Green", "Royal", "Super"]
ITEMS = {
    "Fruits & Vegetables": ["Bananas", "Tomatoes", "Onions", "Apples", "Spinach", "Potatoes",
                            "Carrots", "Grapes", "Lemons", "Capsicum", "Cucumber", "Papaya"],
    "Dairy & Eggs": ["Toned Milk", "Curd", "Paneer", "Butter", "Cheese Slices", "Brown Eggs",
                     "Ghee", "Buttermilk", "Fresh Cream"],
    "Bakery": ["Brown Bread", "White Bread", "Bun Pack", "Croissant", "Rusk", "Cake Slice",
               "Multigrain Bread", "Pizza Base"],
    "Beverages": ["Orange Juice", "Cola 750ml", "Green Tea", "Coffee Powder", "Mango Drink",
                  "Mineral Water", "Energy Drink", "Lemon Iced Tea", "Coconut Water"],
    "Snacks": ["Potato Chips", "Namkeen Mix", "Choco Cookies", "Salted Peanuts", "Popcorn",
               "Chocolate Bar", "Wafers", "Dry Fruit Pack", "Instant Noodles"],
    "Personal Care": ["Shampoo 340ml", "Face Wash", "Toothpaste", "Bath Soap", "Hand Wash",
                      "Body Lotion", "Deodorant", "Hair Oil", "Razor Pack"],
    "Household": ["Dish Wash Gel", "Floor Cleaner", "Detergent Powder", "Garbage Bags",
                  "Toilet Cleaner", "Air Freshener", "Mosquito Repellent", "Kitchen Towel"],
    "Packaged Staples": ["Basmati Rice 5kg", "Atta 5kg", "Toor Dal 1kg", "Sunflower Oil 1L",
                         "Sugar 1kg", "Salt 1kg", "Besan 500g", "Poha 500g", "Masala Pack"],
}

# ---------------------------------------------------------------- products
products = []
pid = 1000
for cat, (lo, hi, reliability) in CATEGORIES.items():
    for base in ITEMS[cat]:
        for brand in random.sample(NOUNS, 2):
            pid += 1
            price = round(random.uniform(lo, hi), 0)
            rel = min(0.99, max(0.62, random.gauss(reliability, 0.05)))
            products.append({
                "product_id": pid,
                "product_name": f"{brand} {base}",
                "category": cat,
                "unit_price": price,
                "is_substitutable": 1 if random.random() < 0.72 else 0,
                "in_stock_rate": round(rel, 2),
            })
random.shuffle(products)
by_cat = {}
for p in products:
    by_cat.setdefault(p["category"], []).append(p)

# popularity weights (a few products dominate views)
weights = []
for i, p in enumerate(products):
    weights.append(max(1.0, 100.0 / (i + 4) ** 0.85 + random.uniform(0, 1.5)))

# ---------------------------------------------------------------- customers
customers = []
for i in range(1, 1201):
    signup = START - timedelta(days=random.randint(0, 900))
    customers.append({
        "customer_id": i,
        "city": random.choices(CITIES, weights=[25, 24, 18, 14, 10, 9])[0],
        "signup_date": signup.strftime("%Y-%m-%d"),
        "customer_segment": random.choices(["new", "returning", "loyal"],
                                           weights=[30, 45, 25])[0],
    })

SEG_LIFT = {"new": 0.85, "returning": 1.00, "loyal": 1.22}
CHN_LIFT = {"organic": 1.05, "paid_ads": 0.82, "email": 1.15, "social": 0.78, "direct": 1.20}
DEV_LIFT = {"mobile_app": 1.12, "mobile_web": 0.86, "desktop": 1.00}

# ---------------------------------------------------------------- sessions + events
sessions, events, orders, order_items, subs = [], [], [], [], []
eid = oid = iid = sid_sub = 0

N_SESSIONS = 14000
for s in range(1, N_SESSIONS + 1):
    cust = random.choice(customers)
    ch = random.choices(CHANNELS, weights=[28, 26, 12, 18, 16])[0]
    dev = random.choices(DEVICES, weights=[55, 27, 18])[0]
    ts = START + timedelta(days=random.randint(0, DAYS - 1),
                           hours=random.randint(6, 23), minutes=random.randint(0, 59))
    sessions.append({
        "session_id": s, "customer_id": cust["customer_id"],
        "session_date": ts.strftime("%Y-%m-%d"),
        "channel": ch, "device": dev,
    })
    lift = SEG_LIFT[cust["customer_segment"]] * CHN_LIFT[ch] * DEV_LIFT[dev]

    def ev(stage, prod, minute):
        global eid
        eid += 1
        events.append({
            "event_id": eid, "session_id": s, "stage": stage,
            "product_id": prod if prod else "",
            "event_time": (ts + timedelta(minutes=minute)).strftime("%Y-%m-%d %H:%M:%S"),
        })

    ev("session_start", None, 0)

    if random.random() > min(0.95, 0.72 * lift):
        continue
    viewed = random.choices(products, weights=weights, k=random.randint(1, 6))
    m = 1
    for p in viewed:
        ev("product_view", p["product_id"], m); m += 1

    carted = []
    for p in viewed:
        p_cart = 0.33 * lift * (1.15 if p["category"] in ("Snacks", "Beverages") else 1.0)
        if random.random() < min(0.85, p_cart):
            carted.append(p)
            ev("add_to_cart", p["product_id"], m); m += 1
    if not carted:
        continue

    if random.random() > min(0.92, 0.66 * lift):
        continue
    ev("checkout_start", None, m); m += 1

    if random.random() > min(0.95, 0.78 * lift):
        continue
    ev("order_placed", None, m); m += 1

    # ------------------------------------------------------------ order
    oid += 1
    rejected_sub = 0
    items_rows = []
    for p in carted:
        iid += 1
        qty = random.choices([1, 2, 3], weights=[70, 22, 8])[0]
        status = "fulfilled"
        if random.random() > p["in_stock_rate"]:          # item out of stock
            if p["is_substitutable"] == 1:
                pool = [q for q in by_cat[p["category"]]
                        if q["product_id"] != p["product_id"]]
                sub_p = random.choice(pool)
                price_gap = sub_p["unit_price"] - p["unit_price"]
                acc_p = 0.70 - min(0.30, max(0.0, price_gap / max(p["unit_price"], 1)) * 0.55)
                accepted = 1 if random.random() < acc_p else 0
                sid_sub += 1
                subs.append({
                    "substitution_id": sid_sub, "order_id": oid, "order_item_id": iid,
                    "original_product_id": p["product_id"],
                    "substitute_product_id": sub_p["product_id"],
                    "price_difference": round(price_gap, 2),
                    "is_accepted": accepted,
                })
                if accepted:
                    status = "substituted"
                else:
                    status = "rejected_substitution"; rejected_sub += 1
            else:
                status = "out_of_stock_removed"
        items_rows.append({
            "order_item_id": iid, "order_id": oid, "product_id": p["product_id"],
            "quantity": qty, "item_price": p["unit_price"],
            "line_amount": round(qty * p["unit_price"], 2),
            "item_status": status,
        })

    billable = [r for r in items_rows
                if r["item_status"] in ("fulfilled", "substituted")]
    order_value = round(sum(r["line_amount"] for r in billable), 2)

    cancel_p = 0.055
    if rejected_sub >= 1: cancel_p += 0.42
    if rejected_sub >= 2: cancel_p += 0.15
    if not billable:      cancel_p = 0.97
    if any(r["item_status"] == "out_of_stock_removed" for r in items_rows): cancel_p += 0.10
    if cust["customer_segment"] == "new": cancel_p += 0.04
    if ch in ("paid_ads", "social"): cancel_p += 0.03

    if random.random() < min(0.97, cancel_p):
        status = "cancelled"
        if rejected_sub >= 1 and random.random() < 0.80:
            reason, by = "substitute_rejected", "customer"
        elif not billable:
            reason, by = "items_unavailable", "system"
        else:
            reason, by = random.choices(
                [("changed_mind", "customer"), ("late_delivery", "customer"),
                 ("payment_failed", "system"), ("address_issue", "seller"),
                 ("items_unavailable", "seller")],
                weights=[30, 22, 18, 14, 16])[0]
        delivered = ""
    else:
        status, reason, by = "delivered", "", ""
        delivered = (ts + timedelta(minutes=m + random.randint(25, 90))).strftime("%Y-%m-%d %H:%M:%S")

    orders.append({
        "order_id": oid, "session_id": s, "customer_id": cust["customer_id"],
        "order_date": ts.strftime("%Y-%m-%d"),
        "order_value": order_value, "order_status": status,
        "cancel_reason": reason, "cancelled_by": by,
        "delivered_time": delivered,
    })
    order_items.extend(items_rows)


def dump(name, rows):
    path = os.path.join(OUT, name + ".csv")
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    print(f"{name:15s} {len(rows):>7,} rows")


dump("products", products)
dump("customers", customers)
dump("sessions", sessions)
dump("funnel_events", events)
dump("orders", orders)
dump("order_items", order_items)
dump("substitutions", subs)
