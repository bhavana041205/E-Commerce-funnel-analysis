-- 02_load_data.sql
-- Loads the CSV files into the tables.
-- Run this inside the sqlite3 shell from the project root folder:
--     sqlite3 funnel.db
--     .read sql/01_schema.sql
--     .read sql/02_load_data.sql

.mode csv
.import --skip 1 data/products.csv       products
.import --skip 1 data/customers.csv      customers
.import --skip 1 data/sessions.csv       sessions
.import --skip 1 data/funnel_events.csv  funnel_events
.import --skip 1 data/orders.csv         orders
.import --skip 1 data/order_items.csv    order_items
.import --skip 1 data/substitutions.csv  substitutions

-- quick check
SELECT 'products',      COUNT(*) FROM products
UNION ALL SELECT 'customers',     COUNT(*) FROM customers
UNION ALL SELECT 'sessions',      COUNT(*) FROM sessions
UNION ALL SELECT 'funnel_events', COUNT(*) FROM funnel_events
UNION ALL SELECT 'orders',        COUNT(*) FROM orders
UNION ALL SELECT 'order_items',   COUNT(*) FROM order_items
UNION ALL SELECT 'substitutions', COUNT(*) FROM substitutions;
