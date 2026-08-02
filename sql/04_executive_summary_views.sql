-- DataCo Supply Chain Analytics | SQLite
-- DROP + CREATE guarantees that rerunning this file refreshes view definitions.

DROP VIEW IF EXISTS vw_executive_kpis;
CREATE VIEW vw_executive_kpis AS
SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT "Order Id") AS total_orders,
    ROUND(SUM("Sales"), 2) AS total_sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS total_profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct,
    SUM(CASE WHEN "Order Profit Per Order" < 0 THEN 1 ELSE 0 END) AS loss_making_order_items,
    SUM(CASE WHEN "Delivery Status" = 'Shipping canceled' THEN 1 ELSE 0 END) AS canceled_order_items,
    SUM(CASE WHEN "Delivery Status" <> 'Shipping canceled' THEN 1 ELSE 0 END) AS non_canceled_order_items,
    SUM(CASE WHEN "Delivery Status" <> 'Shipping canceled' AND "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END) AS delayed_order_items,
    ROUND(100.0 * SUM(CASE WHEN "Delivery Status" <> 'Shipping canceled' AND "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN "Delivery Status" <> 'Shipping canceled' THEN 1 ELSE 0 END), 0), 2) AS delay_rate_pct
FROM shipments;

DROP VIEW IF EXISTS vw_shipping_mode_performance;
CREATE VIEW vw_shipping_mode_performance AS
SELECT
    "Shipping Mode" AS shipping_mode,
    COUNT(*) AS non_canceled_order_items,
    SUM(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1 ELSE 0 END) AS delayed_order_items,
    ROUND(100.0 * AVG(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 ELSE 0.0 END), 2) AS delay_rate_pct,
    ROUND(AVG("Days for shipping (real)" - "Days for shipment (scheduled)"), 2) AS avg_schedule_variance_days
FROM shipments
WHERE "Delivery Status" <> 'Shipping canceled'
GROUP BY "Shipping Mode";

DROP VIEW IF EXISTS vw_regional_performance;
CREATE VIEW vw_regional_performance AS
SELECT
    "Market" AS market,
    "Order Region" AS order_region,
    COUNT(*) AS order_items,
    ROUND(SUM("Sales"), 2) AS sales,
    ROUND(SUM("Order Profit Per Order"), 2) AS profit,
    ROUND(100.0 * SUM("Order Profit Per Order") / NULLIF(SUM("Sales"), 0), 2) AS profit_margin_pct,
    ROUND(100.0 * AVG(CASE WHEN "Delivery Status" <> 'Shipping canceled' AND "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 WHEN "Delivery Status" <> 'Shipping canceled' THEN 0.0 END), 2) AS delay_rate_pct_non_canceled
FROM shipments
GROUP BY "Market", "Order Region";

DROP VIEW IF EXISTS vw_department_cancellations;
CREATE VIEW vw_department_cancellations AS
SELECT
    "Department Name" AS department_name,
    COUNT(*) AS order_items,
    SUM(CASE WHEN "Delivery Status" = 'Shipping canceled' THEN 1 ELSE 0 END) AS canceled_order_items,
    ROUND(100.0 * AVG(CASE WHEN "Delivery Status" = 'Shipping canceled' THEN 1.0 ELSE 0.0 END), 2) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN "Delivery Status" = 'Shipping canceled' THEN "Sales" ELSE 0 END), 2) AS canceled_sales_exposure
FROM shipments
GROUP BY "Department Name";

-- Dashboard-ready outputs.
SELECT * FROM vw_executive_kpis;
SELECT * FROM vw_shipping_mode_performance ORDER BY delay_rate_pct DESC;
SELECT * FROM vw_regional_performance ORDER BY sales DESC;
SELECT * FROM vw_department_cancellations ORDER BY canceled_sales_exposure DESC;

