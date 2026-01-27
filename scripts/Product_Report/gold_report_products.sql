/*
===============================================================================
Product Report Logic
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors to provide 
      a comprehensive view of inventory performance.
    - Supports category management, pricing strategies, and stock optimization.

Highlights:
    1. Dimensions: Product details (Name, Category, Subcategory, Cost).
    2. Segmentation: Classifies products by revenue (High, Mid, Low Performers).
    3. Aggregates: Total orders, sales, quantity, and unique customer reach.
    4. KPIs: Sale Recency, Lifespan, Avg Order Revenue (AOR), and Avg Monthly Revenue.
===============================================================================
*/

CREATE OR REPLACE VIEW gold.report_products AS

WITH base_query AS (
    /* 1) Base Query: Retrieve core transactional data joined with product details
    */
    SELECT 
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p 
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),

product_aggregations AS (
    /* 2) Product Aggregation: Summarizes transactional metrics at the product level 
    */
    SELECT 
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        MAX(order_date) AS last_sale_date,
        MIN(order_date) AS first_sale_date,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(sales_amount / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY 
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

/* 3) Final Query: Calculate derived KPIs and business segments 
*/
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    /* Recency: Months since the product was last sold */
    TIMESTAMPDIFF(MONTH, last_sale_date, CURDATE()) AS recency_in_months,
    /* Segmentation: Performance classification based on revenue */
    CASE 
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    /* KPI: Average Order Revenue (AOR) */
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders 
    END AS avg_order_revenue,
    /* KPI: Average Monthly Revenue */
    CASE 
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue
FROM product_aggregations;
