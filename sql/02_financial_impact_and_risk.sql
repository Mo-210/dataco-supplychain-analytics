-- DataCo Supply Chain Analytics | SQLite
-- Financial metrics use the order-item grain.

-- 1. Executive financial KPIs.
SELECT
    COUNT(*) AS order_items,
    COUNT(DISTINCT "Order Id") AS orders,
    ROUND(SUM("Sales"), 2) AS total_sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS total_profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct,
    SUM(CASE WHEN "Order Profit Per Order" < 0 THEN 1 ELSE 0 END) AS loss_making_order_items,
    ROUND(100.0 * AVG(CASE WHEN "Order Profit Per Order" < 0 THEN 1.0 ELSE 0.0 END), 2) AS loss_making_item_rate_pct
FROM shipments;

-- 2. Financial performance by delivery result (non-canceled items only).
SELECT
    CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 'Delayed' ELSE 'Not delayed' END AS delivery_result,
    COUNT(*) AS order_items,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct,
    ROUND(100.0 * AVG(CASE WHEN "Order Profit Per Order" < 0 THEN 1.0 ELSE 0.0 END), 2) AS loss_making_item_rate_pct
FROM shipments
WHERE "Delivery Status" <> 'Shipping canceled'
GROUP BY delivery_result
ORDER BY profit ASC;

-- 3. Markets with the largest absolute losses from loss-making items.
SELECT
    "Market" AS market,
    COUNT(*) AS loss_making_order_items,
    ROUND(SUM("Sales"), 2) AS sales_on_loss_making_items,
    ROUND(SUM("Order Profit Per Order"), 2) AS total_loss,
    ROUND(AVG("Order Profit Per Order"), 2) AS avg_loss_per_item
FROM shipments
WHERE "Order Profit Per Order" < 0
GROUP BY "Market"
ORDER BY total_loss ASC;

-- 4. Categories contributing most to losses.
SELECT
    "Category Name" AS category_name,
    COUNT(*) AS loss_making_order_items,
    ROUND(SUM("Order Profit Per Order"), 2) AS total_loss,
    ROUND(SUM("Sales"), 2) AS affected_sales
FROM shipments
WHERE "Order Profit Per Order" < 0
GROUP BY "Category Name"
ORDER BY total_loss ASC
LIMIT 15;

-- 5. Order-status risk profile.
SELECT
    "Order Status" AS order_status,
    COUNT(*) AS order_items,
    COUNT(DISTINCT "Order Id") AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_items,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit
FROM shipments
GROUP BY "Order Status"
ORDER BY order_items DESC;

-- 6. Cancellation exposure by department (sales are exposure, not proven lost sales).
SELECT
    "Department Name" AS department_name,
    SUM(CASE WHEN "Delivery Status" = 'Shipping canceled' THEN 1 ELSE 0 END) AS canceled_order_items,
    ROUND(100.0 * AVG(CASE WHEN "Delivery Status" = 'Shipping canceled' THEN 1.0 ELSE 0.0 END), 2) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN "Delivery Status" = 'Shipping canceled' THEN "Sales" ELSE 0 END), 2) AS canceled_sales_exposure
FROM shipments
GROUP BY "Department Name"
ORDER BY canceled_sales_exposure DESC;

