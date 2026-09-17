-- 01_schema.sql
-- Creates the 7 tables used in this project.
-- Written for SQLite (also runs on MySQL / PostgreSQL with tiny changes).

DROP TABLE IF EXISTS substitutions;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS funnel_events;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;

-- Product master. in_stock_rate = how often the item is actually available.
CREATE TABLE products (
    product_id        INTEGER PRIMARY KEY,
    product_name      TEXT,
    category          TEXT,
    unit_price        REAL,
    is_substitutable  INTEGER,   -- 1 = a swap can be offered, 0 = cannot
    in_stock_rate     REAL
);

CREATE TABLE customers (
    customer_id       INTEGER PRIMARY KEY,
    city              TEXT,
    signup_date       TEXT,
    customer_segment  TEXT       -- new / returning / loyal
);

-- One row per app or website visit.
CREATE TABLE sessions (
    session_id        INTEGER PRIMARY KEY,
    customer_id       INTEGER,
    session_date      TEXT,
    channel           TEXT,      -- organic / paid_ads / email / social / direct
    device            TEXT
);

-- The funnel log. Stage tells you how far the visit went.
-- product_id is filled only for product_view and add_to_cart.
CREATE TABLE funnel_events (
    event_id          INTEGER PRIMARY KEY,
    session_id        INTEGER,
    stage             TEXT,      -- session_start, product_view, add_to_cart,
                                 -- checkout_start, order_placed
    product_id        INTEGER,
    event_time        TEXT
);

CREATE TABLE orders (
    order_id          INTEGER PRIMARY KEY,
    session_id        INTEGER,
    customer_id       INTEGER,
    order_date        TEXT,
    order_value       REAL,
    order_status      TEXT,      -- delivered / cancelled
    cancel_reason     TEXT,
    cancelled_by      TEXT,      -- customer / seller / system
    delivered_time    TEXT
);

CREATE TABLE order_items (
    order_item_id     INTEGER PRIMARY KEY,
    order_id          INTEGER,
    product_id        INTEGER,
    quantity          INTEGER,
    item_price        REAL,
    line_amount       REAL,
    item_status       TEXT       -- fulfilled / substituted /
                                 -- rejected_substitution / out_of_stock_removed
);

CREATE TABLE substitutions (
    substitution_id       INTEGER PRIMARY KEY,
    order_id              INTEGER,
    order_item_id         INTEGER,
    original_product_id   INTEGER,
    substitute_product_id INTEGER,
    price_difference      REAL,  -- substitute price minus original price
    is_accepted           INTEGER
);
