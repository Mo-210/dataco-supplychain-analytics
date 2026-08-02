-- DataCo Supply Chain Analytics | SQLite
-- Grain: one row = one order item.
-- Delay KPIs exclude Delivery Status = 'Shipping canceled'.

-- 1. Executive logistics KPIs (expected: 172765 non-canceled items,
--    98977 delayed items, 57.29% delay rate).
SELECT
    COUNT(*) AS non_canceled_order_items,
    COUNT(DISTINCT "Order Id") AS non_canceled_orders,
    SUM(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END) AS delayed_order_items,
    SUM(CASE WHEN "Days for shipping (real)" <= "Days for shipment (scheduled)" THEN 1 ELSE 0 END) AS not_delayed_order_items,
    ROUND(100.0 * SUM(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS delay_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN "Days for shipping (real)" <= "Days for shipment (scheduled)" THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS not_delayed_rate_pct,
    ROUND(AVG("Days for shipping (real)" - "Days for shipment (scheduled)"), 2) AS avg_schedule_variance_days
FROM shipments
WHERE "Delivery Status" <> 'Shipping canceled'
  AND "Days for shipping (real)" IS NOT NULL
  AND "Days for shipment (scheduled)" IS NOT NULL;

-- 2. Performance by shipping mode.
SELECT
    "Shipping Mode" AS shipping_mode,
    COUNT(*) AS non_canceled_order_items,
    COUNT(DISTINCT "Order Id") AS orders,
    SUM(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END) AS delayed_order_items,
    ROUND(100.0 * AVG(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 ELSE 0.0 END), 2) AS delay_rate_pct,
    ROUND(AVG("Days for shipping (real)" - "Days for shipment (scheduled)"), 2) AS avg_schedule_variance_days,
    ROUND(AVG(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN "Days for shipping (real)" - "Days for shipment (scheduled)" END), 2) AS avg_delay_days_delayed_items
FROM shipments
WHERE "Delivery Status" <> 'Shipping canceled'
GROUP BY "Shipping Mode"
ORDER BY delay_rate_pct DESC, non_canceled_order_items DESC;

-- 3. Regional bottlenecks (minimum 500 order items avoids tiny samples).
SELECT
    "Market" AS market,
    "Order Region" AS order_region,
    COUNT(*) AS non_canceled_order_items,
    COUNT(DISTINCT "Order Id") AS orders,
    SUM(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END) AS delayed_order_items,
    ROUND(100.0 * AVG(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 ELSE 0.0 END), 2) AS delay_rate_pct,
    ROUND(AVG("Days for shipping (real)" - "Days for shipment (scheduled)"), 2) AS avg_schedule_variance_days
FROM shipments
WHERE "Delivery Status" <> 'Shipping canceled'
GROUP BY "Market", "Order Region"
HAVING COUNT(*) >= 500
ORDER BY delay_rate_pct DESC, delayed_order_items DESC;

-- 4. Category logistics performance.
SELECT
    "Category Name" AS category_name,
    COUNT(*) AS non_canceled_order_items,
    SUM(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END) AS delayed_order_items,
    ROUND(100.0 * AVG(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 ELSE 0.0 END), 2) AS delay_rate_pct
FROM shipments
WHERE "Delivery Status" <> 'Shipping canceled'
GROUP BY "Category Name"
HAVING COUNT(*) >= 500
ORDER BY delayed_order_items DESC, delay_rate_pct DESC
LIMIT 15;

-- 5. Delivery-result distribution, including cancellation as a separate class.
SELECT
    CASE
        WHEN "Delivery Status" = 'Shipping canceled' THEN 'Shipping canceled'
        WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 'Delayed'
        ELSE 'Not delayed'
    END AS delivery_result,
    COUNT(*) AS order_items,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_all_order_items
FROM shipments
GROUP BY delivery_result
ORDER BY order_items DESC;

