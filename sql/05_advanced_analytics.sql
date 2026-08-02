-- DataCo Supply Chain Analytics | SQLite 3.25+ (window functions)

-- 1. Regional risk ranking.
WITH regional AS (
    SELECT
        "Market" AS market,
        "Order Region" AS order_region,
        COUNT(*) AS non_canceled_order_items,
        ROUND(SUM("Order Profit Per Order"), 2) AS profit,
        ROUND(100.0 * AVG(CASE WHEN "Days for shipping (real)" > "Days for shipment (scheduled)" THEN 1.0 ELSE 0.0 END), 2) AS delay_rate_pct
    FROM shipments
    WHERE "Delivery Status" <> 'Shipping canceled'
    GROUP BY "Market", "Order Region"
)
SELECT *,
    RANK() OVER (ORDER BY delay_rate_pct DESC) AS delay_risk_rank,
    DENSE_RANK() OVER (PARTITION BY market ORDER BY delay_rate_pct DESC) AS rank_within_market
FROM regional
ORDER BY delay_risk_rank, non_canceled_order_items DESC;

-- 2. Pareto analysis of absolute losses by category.
WITH category_loss AS (
    SELECT "Category Name" AS category_name,
           -SUM("Order Profit Per Order") AS absolute_loss
    FROM shipments
    WHERE "Order Profit Per Order" < 0
    GROUP BY "Category Name"
), cumulative AS (
    SELECT category_name, absolute_loss,
           SUM(absolute_loss) OVER (ORDER BY absolute_loss DESC) AS running_loss,
           SUM(absolute_loss) OVER () AS total_loss
    FROM category_loss
)
SELECT category_name,
       ROUND(absolute_loss, 2) AS absolute_loss,
       ROUND(100.0 * running_loss / NULLIF(total_loss, 0), 2) AS cumulative_loss_pct,
       CASE WHEN running_loss - absolute_loss < 0.80 * total_loss THEN 'Top loss driver' ELSE 'Secondary' END AS pareto_class
FROM cumulative
ORDER BY absolute_loss DESC;

-- 3. Delayed-item severity quartiles (ties may span quartiles).
WITH delayed AS (
    SELECT "Order Item Id" AS order_item_id,
           "Order Id" AS order_id,
           "Shipping Mode" AS shipping_mode,
           "Order Region" AS order_region,
           "Days for shipping (real)" - "Days for shipment (scheduled)" AS delay_days,
           "Sales" AS sales
    FROM shipments
    WHERE "Delivery Status" <> 'Shipping canceled'
      AND "Days for shipping (real)" > "Days for shipment (scheduled)"
)
SELECT *, NTILE(4) OVER (ORDER BY delay_days DESC, sales DESC) AS severity_quartile
FROM delayed
ORDER BY severity_quartile, delay_days DESC;

-- 4. Monthly trend. Source dates are M/D/YYYY H:MM, so parse explicitly.
WITH parsed AS (
    SELECT
        substr("order date (DateOrders)", 1, instr("order date (DateOrders)", '/') - 1) AS month_num,
        substr(
            "order date (DateOrders)",
            instr("order date (DateOrders)", '/') + 1,
            instr(substr("order date (DateOrders)", instr("order date (DateOrders)", '/') + 1), '/') - 1
        ) AS day_num,
        substr(
            "order date (DateOrders)",
            instr("order date (DateOrders)", '/') + instr(substr("order date (DateOrders)", instr("order date (DateOrders)", '/') + 1), '/') + 1,
            4
        ) AS year_num,
        "Sales" AS sales,
        "Order Profit Per Order" AS profit
    FROM shipments
), monthly AS (
    SELECT printf('%04d-%02d', CAST(year_num AS INTEGER), CAST(month_num AS INTEGER)) AS order_month,
           ROUND(SUM(sales), 2) AS sales,
           ROUND(SUM(profit), 2) AS profit
    FROM parsed
    GROUP BY order_month
)
SELECT order_month, sales, profit,
       ROUND(sales - LAG(sales) OVER (ORDER BY order_month), 2) AS sales_change,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY order_month)) / NULLIF(LAG(sales) OVER (ORDER BY order_month), 0), 2) AS sales_growth_pct
FROM monthly
ORDER BY order_month;

-- 5. First Class diagnostic.
SELECT
    "Shipping Mode" AS shipping_mode,
    "Days for shipment (scheduled)" AS scheduled_days,
    "Days for shipping (real)" AS actual_days,
    COUNT(*) AS order_items,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY "Shipping Mode"), 2) AS pct_within_mode
FROM shipments
WHERE "Delivery Status" <> 'Shipping canceled'
  AND "Shipping Mode" = 'First Class'
GROUP BY "Shipping Mode", scheduled_days, actual_days
ORDER BY scheduled_days, actual_days;

