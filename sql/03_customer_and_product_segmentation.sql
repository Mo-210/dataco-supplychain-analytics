-- DataCo Supply Chain Analytics | SQLite

-- 1. Customer-segment scorecard.
SELECT
    "Customer Segment" AS customer_segment,
    COUNT(*) AS order_items,
    COUNT(DISTINCT "Order Id") AS orders,
    COUNT(DISTINCT "Customer Id") AS customers,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct,
    ROUND(100.0 * AVG(CASE WHEN "Delivery Status" <> 'Shipping canceled' AND "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 WHEN "Delivery Status" <> 'Shipping canceled' THEN 0.0 END), 2) AS delay_rate_pct_non_canceled
FROM shipments
GROUP BY "Customer Segment"
ORDER BY sales DESC;

-- 2. Top customers by sales, with profitability context.
SELECT
    "Customer Id" AS customer_id,
    TRIM(COALESCE("Customer Fname", '') || ' ' || COALESCE("Customer Lname", '')) AS customer_name,
    "Customer Segment" AS customer_segment,
    COUNT(DISTINCT "Order Id") AS orders,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct
FROM shipments
GROUP BY "Customer Id", customer_name, "Customer Segment"
ORDER BY sales DESC
LIMIT 20;

-- 3. Product portfolio: volume, revenue, profit, and delay rate.
SELECT
    "Product Name" AS product_name,
    "Category Name" AS category_name,
    SUM("Order Item Quantity") AS units,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct,
    ROUND(100.0 * AVG(CASE WHEN "Delivery Status" <> 'Shipping canceled' AND "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 WHEN "Delivery Status" <> 'Shipping canceled' THEN 0.0 END), 2) AS delay_rate_pct_non_canceled
FROM shipments
GROUP BY "Product Card Id", "Product Name", "Category Name"
ORDER BY sales DESC
LIMIT 20;

-- 4. Products requiring attention: meaningful sales but negative total profit.
SELECT
    "Product Name" AS product_name,
    "Category Name" AS category_name,
    COUNT(*) AS order_items,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit
FROM shipments
GROUP BY "Product Card Id", "Product Name", "Category Name"
HAVING SUM("Sales") >= 10000 AND SUM("Order Profit Per Order") < 0
ORDER BY profit ASC;

-- 5. Country opportunity matrix.
SELECT
    "Order Country" AS order_country,
    COUNT(DISTINCT "Order Id") AS orders,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct,
    ROUND(100.0 * AVG(CASE WHEN "Delivery Status" <> 'Shipping canceled' AND "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 WHEN "Delivery Status" <> 'Shipping canceled' THEN 0.0 END), 2) AS delay_rate_pct_non_canceled
FROM shipments
GROUP BY "Order Country"
HAVING COUNT(DISTINCT "Order Id") >= 100
ORDER BY sales DESC;

