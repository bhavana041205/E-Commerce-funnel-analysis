"""Builds funnel.db from the CSV files. Use this if you do not have the sqlite3 shell.
Run:  python setup_db.py
Then: sqlite3 funnel.db  ->  .read sql/03_funnel_analysis.sql
"""
import csv, os, sqlite3

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "funnel.db")
if os.path.exists(DB):
    os.remove(DB)

con = sqlite3.connect(DB)
cur = con.cursor()
cur.executescript(open(os.path.join(BASE, "sql", "01_schema.sql")).read())

TABLES = ["products", "customers", "sessions", "funnel_events",
          "orders", "order_items", "substitutions"]
for t in TABLES:
    rows = list(csv.reader(open(os.path.join(BASE, "data", t + ".csv"))))
    header = rows[0]
    marks = ",".join("?" * len(header))
    data = [[c if c != "" else None for c in r] for r in rows[1:]]
    cur.executemany(f"INSERT INTO {t} VALUES ({marks})", data)
    print(f"{t:15s} {len(data):>7,} rows loaded")
con.commit()
con.close()
print("\nDone -> funnel.db")
