-- 03_funnel_analysis.sql
-- The main funnel: visit -> view -> cart -> checkout -> order.
-- Only simple commands: SELECT, JOIN, GROUP BY, CASE, COUNT, ROUND.

-- Q1. How many sessions reach each stage, and what share of all visits is that?
SELECT
    stage,
    COUNT(DISTINCT session_id) AS sessions_at_stage,
    ROUND(100.0 * COUNT(DISTINCT session_id) /
          (SELECT COUNT(*) FROM sessions), 1) AS pct_of_all_visits
FROM funnel_events
GROUP BY stage
ORDER BY sessions_at_stage DESC;


-- Q2. Drop-off between two neighbouring stages (cart -> checkout example).
SELECT
    (SELECT COUNT(DISTINCT session_id) FROM funnel_events WHERE stage = 'add_to_cart')    AS cart_sessions,
    (SELECT COUNT(DISTINCT session_id) FROM funnel_events WHERE stage = 'checkout_start') AS checkout_sessions,
    ROUND(100.0 *
        (SELECT COUNT(DISTINCT session_id) FROM funnel_events WHERE stage = 'checkout_start') /
        (SELECT COUNT(DISTINCT session_id) FROM funnel_events WHERE stage = 'add_to_cart'), 1)
        AS cart_to_checkout_pct;


-- Q3. Funnel by marketing channel. Which traffic actually buys?
SELECT
    s.channel,
    COUNT(DISTINCT s.session_id) AS visits,
    COUNT(DISTINCT o.order_id)   AS orders,
    ROUND(100.0 * COUNT(DISTINCT o.order_id) / COUNT(DISTINCT s.session_id), 1) AS visit_to_order_pct
FROM sessions s
LEFT JOIN orders o ON o.session_id = s.session_id
GROUP BY s.channel
ORDER BY visit_to_order_pct DESC;


-- Q4. Funnel by device.
SELECT
    s.device,
    COUNT(DISTINCT s.session_id) AS visits,
    COUNT(DISTINCT o.order_id)   AS orders,
    ROUND(100.0 * COUNT(DISTINCT o.order_id) / COUNT(DISTINCT s.session_id), 1) AS visit_to_order_pct
FROM sessions s
LEFT JOIN orders o ON o.session_id = s.session_id
GROUP BY s.device
ORDER BY visit_to_order_pct DESC;


-- Q5. Funnel by customer type.
SELECT
    c.customer_segment,
    COUNT(DISTINCT s.session_id) AS visits,
    COUNT(DISTINCT o.order_id)   AS orders,
    ROUND(100.0 * COUNT(DISTINCT o.order_id) / COUNT(DISTINCT s.session_id), 1) AS visit_to_order_pct
FROM sessions s
JOIN customers c ON c.customer_id = s.customer_id
LEFT JOIN orders o ON o.session_id = s.session_id
GROUP BY c.customer_segment
ORDER BY visit_to_order_pct DESC;


-- Q6. Month by month orders and money.
SELECT
    SUBSTR(order_date, 1, 7) AS month,
    COUNT(*) AS orders,
    ROUND(SUM(order_value), 0) AS gross_value,
    ROUND(SUM(CASE WHEN order_status = 'delivered' THEN order_value ELSE 0 END), 0) AS delivered_value
FROM orders
GROUP BY month
ORDER BY month;
