/*
===============================================================================
Customer Report Logic
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors into a 
      single "Customer 360" view.
    - Supports marketing segmentation, churn analysis, and financial reporting.

Highlights:
    1. Dimensions: Basic info (Name, Age) and derived groupings (Age Groups).
    2. Segmentation: Classifies customers into VIP, Regular, and New segments.
    3. Aggregates: Total orders, sales, quantity, and product diversity.
    4. KPIs: Recency, Lifespan, Average Order Value (AOV), and Monthly Spend.
===============================================================================
*/

CREATE OR REPLACE VIEW gold.report_customers AS

WITH base_query AS (
    /* 1) Base Query: Retrieve core transactional columns and join with dimensions 
    */
    SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c 
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
    /* 2) Customer Aggregation: Summarizes metrics at the individual customer level 
    */
    SELECT 
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        MIN(order_date) AS first_order_date, -- Useful for sanity checks
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY 
        customer_key, 
        customer_number, 
        customer_name, 
        age
)

SELECT 
    customer_key,
    customer_number,
    customer_name,
    age,
    /* Grouping: Age Segmentation */
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    /* Grouping: Customer Value Segmentation */
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    /* Recency: Months since the last purchase */
    TIMESTAMPDIFF(MONTH, last_order_date, CURDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products, 
    lifespan,
    /* KPI: Average Order Value (AOV) */
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders 
    END AS avg_order_value,
    /* KPI: Average Monthly Spending */
    CASE 
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spending
FROM customer_aggregation;
