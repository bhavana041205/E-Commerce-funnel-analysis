-- 05_substitution_analysis.sql
-- What happens when an item is out of stock and a swap is offered.

-- Q1. How many swaps were offered and how many were accepted?
SELECT
    COUNT(*) AS substitutions_offered,
    SUM(is_accepted) AS accepted,
    ROUND(100.0 * SUM(is_accepted) / COUNT(*), 1) AS acceptance_rate_pct
FROM substitutions;


-- Q2. THE KEY QUERY.
-- Cancel rate for orders with a rejected swap, an accepted swap, and no swap.
SELECT
    CASE
        WHEN o.order_id IN (SELECT order_id FROM substitutions WHERE is_accepted = 0) THEN 'B. swap rejected'
        WHEN o.order_id IN (SELECT order_id FROM substitutions WHERE is_accepted = 1) THEN 'C. swap accepted'
        ELSE 'A. no swap offered'
    END AS swap_group,
    COUNT(*) AS orders,
    SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(100.0 * SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM orders o
GROUP BY swap_group
ORDER BY swap_group;


-- Q3. Does the price of the swap decide if the customer says yes?
SELECT
    CASE
        WHEN price_difference <= 0  THEN 'A. cheaper or same price'
        WHEN price_difference <= 50 THEN 'B. up to 50 costlier'
        ELSE 'C. more than 50 costlier'
    END AS price_gap_band,
    COUNT(*) AS swaps_offered,
    ROUND(100.0 * SUM(is_accepted) / COUNT(*), 1) AS acceptance_rate_pct
FROM substitutions
GROUP BY price_gap_band
ORDER BY price_gap_band;


-- Q4. Which categories run out of stock the most?
SELECT
    p.category,
    COUNT(*) AS items_ordered,
    SUM(CASE WHEN i.item_status IN ('substituted', 'rejected_substitution', 'out_of_stock_removed')
             THEN 1 ELSE 0 END) AS stock_problem_items,
    ROUND(100.0 * SUM(CASE WHEN i.item_status IN ('substituted', 'rejected_substitution', 'out_of_stock_removed')
             THEN 1 ELSE 0 END) / COUNT(*), 1) AS stock_problem_pct
FROM order_items i
JOIN products p ON p.product_id = i.product_id
GROUP BY p.category
ORDER BY stock_problem_pct DESC;


-- Q5. Top products that force a swap the most (fix these first).
SELECT
    p.product_name,
    p.category,
    COUNT(*) AS times_swap_offered,
    SUM(s.is_accepted) AS accepted,
    ROUND(100.0 * SUM(s.is_accepted) / COUNT(*), 1) AS acceptance_rate_pct
FROM substitutions s
JOIN products p ON p.product_id = s.original_product_id
GROUP BY p.product_name, p.category
ORDER BY times_swap_offered DESC
LIMIT 10;


-- Q6. Best replacement items (the ones customers accept most often).
SELECT
    p.product_name AS substitute_offered,
    COUNT(*) AS times_used,
    ROUND(100.0 * SUM(s.is_accepted) / COUNT(*), 1) AS acceptance_rate_pct
FROM substitutions s
JOIN products p ON p.product_id = s.substitute_product_id
GROUP BY p.product_name
HAVING COUNT(*) >= 5
ORDER BY acceptance_rate_pct DESC
LIMIT 10;


-- Q7. Items that could not be swapped at all (no alternative allowed).
SELECT
    p.category,
    COUNT(*) AS items_removed_from_cart
FROM order_items i
JOIN products p ON p.product_id = i.product_id
WHERE i.item_status = 'out_of_stock_removed'
GROUP BY p.category
ORDER BY items_removed_from_cart DESC;
