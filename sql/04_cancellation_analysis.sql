-- 04_cancellation_analysis.sql
-- The cancellation side of the funnel: who cancels, why, and what it costs.

-- Q1. Overall cancel rate and money lost.
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(100.0 * SUM(CASE WHEN order_status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct,
    ROUND(SUM(CASE WHEN order_status = 'cancelled' THEN order_value ELSE 0 END), 0) AS value_lost
FROM orders;


-- Q2. Why do orders get cancelled?
SELECT
    cancel_reason,
    COUNT(*) AS cancelled_orders,
    ROUND(100.0 * COUNT(*) /
          (SELECT COUNT(*) FROM orders WHERE order_status = 'cancelled'), 1) AS pct_of_cancels,
    ROUND(SUM(order_value), 0) AS value_lost
FROM orders
WHERE order_status = 'cancelled'
GROUP BY cancel_reason
ORDER BY cancelled_orders DESC;


-- Q3. Who pulls the plug: customer, seller or system?
SELECT
    cancelled_by,
    COUNT(*) AS cancelled_orders,
    ROUND(AVG(order_value), 0) AS avg_order_value
FROM orders
WHERE order_status = 'cancelled'
GROUP BY cancelled_by
ORDER BY cancelled_orders DESC;


-- Q4. Cancel rate by city.
SELECT
    c.city,
    COUNT(*) AS orders,
    SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(100.0 * SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY cancel_rate_pct DESC;


-- Q5. Cancel rate by channel and customer type together.
SELECT
    s.channel,
    c.customer_segment,
    COUNT(*) AS orders,
    ROUND(100.0 * SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM orders o
JOIN sessions s  ON s.session_id  = o.session_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY s.channel, c.customer_segment
ORDER BY cancel_rate_pct DESC;


-- Q6. Does a bigger basket cancel more often?
SELECT
    CASE
        WHEN order_value < 500  THEN 'A. under 500'
        WHEN order_value < 1000 THEN 'B. 500-999'
        WHEN order_value < 2000 THEN 'C. 1000-1999'
        ELSE 'D. 2000 and above'
    END AS value_band,
    COUNT(*) AS orders,
    ROUND(100.0 * SUM(CASE WHEN order_status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM orders
GROUP BY value_band
ORDER BY value_band;
