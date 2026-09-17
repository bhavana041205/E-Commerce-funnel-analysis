-- 06_product_analysis.sql
-- The product side: which items pull traffic, which items convert,
-- and which items quietly damage the funnel.

-- Q1. Product level funnel: views, carts, and view-to-cart rate.
SELECT
    p.product_name,
    p.category,
    SUM(CASE WHEN e.stage = 'product_view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN e.stage = 'add_to_cart'  THEN 1 ELSE 0 END) AS carts,
    ROUND(100.0 * SUM(CASE WHEN e.stage = 'add_to_cart' THEN 1 ELSE 0 END) /
          SUM(CASE WHEN e.stage = 'product_view' THEN 1 ELSE 0 END), 1) AS view_to_cart_pct
FROM funnel_events e
JOIN products p ON p.product_id = e.product_id
GROUP BY p.product_name, p.category
ORDER BY views DESC
LIMIT 15;


-- Q2. High traffic but weak conversion: the fix-me list.
SELECT
    p.product_name,
    p.category,
    SUM(CASE WHEN e.stage = 'product_view' THEN 1 ELSE 0 END) AS views,
    ROUND(100.0 * SUM(CASE WHEN e.stage = 'add_to_cart' THEN 1 ELSE 0 END) /
          SUM(CASE WHEN e.stage = 'product_view' THEN 1 ELSE 0 END), 1) AS view_to_cart_pct
FROM funnel_events e
JOIN products p ON p.product_id = e.product_id
GROUP BY p.product_name, p.category
HAVING SUM(CASE WHEN e.stage = 'product_view' THEN 1 ELSE 0 END) >= 200
ORDER BY view_to_cart_pct ASC
LIMIT 10;


-- Q3. Category funnel.
SELECT
    p.category,
    SUM(CASE WHEN e.stage = 'product_view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN e.stage = 'add_to_cart'  THEN 1 ELSE 0 END) AS carts,
    ROUND(100.0 * SUM(CASE WHEN e.stage = 'add_to_cart' THEN 1 ELSE 0 END) /
          SUM(CASE WHEN e.stage = 'product_view' THEN 1 ELSE 0 END), 1) AS view_to_cart_pct
FROM funnel_events e
JOIN products p ON p.product_id = e.product_id
GROUP BY p.category
ORDER BY views DESC;


-- Q4. How much of all traffic do the top 10 products take?
SELECT
    ROUND(100.0 * SUM(t.views) /
          (SELECT COUNT(*) FROM funnel_events WHERE stage = 'product_view'), 1) AS top10_share_of_views
FROM (
    SELECT product_id, COUNT(*) AS views
    FROM funnel_events
    WHERE stage = 'product_view'
    GROUP BY product_id
    ORDER BY views DESC
    LIMIT 10
) t;


-- Q5. Cancel rate of orders that contain each category.
SELECT
    p.category,
    COUNT(DISTINCT o.order_id) AS orders_with_category,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_status = 'cancelled' THEN o.order_id END) /
          COUNT(DISTINCT o.order_id), 1) AS cancel_rate_pct
FROM orders o
JOIN order_items i ON i.order_id = o.order_id
JOIN products p    ON p.product_id = i.product_id
GROUP BY p.category
ORDER BY cancel_rate_pct DESC;


-- Q6. Revenue that actually got delivered, by category.
SELECT
    p.category,
    ROUND(SUM(i.line_amount), 0) AS billed_value,
    ROUND(SUM(CASE WHEN o.order_status = 'delivered' THEN i.line_amount ELSE 0 END), 0) AS delivered_value,
    ROUND(100.0 * SUM(CASE WHEN o.order_status = 'delivered' THEN i.line_amount ELSE 0 END) /
          SUM(i.line_amount), 1) AS delivered_pct
FROM order_items i
JOIN orders o   ON o.order_id = i.order_id
JOIN products p ON p.product_id = i.product_id
WHERE i.item_status IN ('fulfilled', 'substituted')
GROUP BY p.category
ORDER BY delivered_value DESC;


-- Q7. Stock reliability vs cancellation: the link in one table.
SELECT
    CASE
        WHEN p.in_stock_rate >= 0.92 THEN 'A. reliable (92%+)'
        WHEN p.in_stock_rate >= 0.82 THEN 'B. average (82-91%)'
        ELSE 'C. weak (under 82%)'
    END AS stock_band,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_status = 'cancelled' THEN o.order_id END) /
          COUNT(DISTINCT o.order_id), 1) AS cancel_rate_pct
FROM order_items i
JOIN products p ON p.product_id = i.product_id
JOIN orders o   ON o.order_id = i.order_id
GROUP BY stock_band
ORDER BY stock_band;
