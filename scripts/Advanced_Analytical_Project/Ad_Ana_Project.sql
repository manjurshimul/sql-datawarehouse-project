/*
===============================================================================
Advanced Analytics Script
===============================================================================
Script Purpose:
    - Change Over Time: Analyzes trends, seasonality, and cumulative growth.
    - Performance Analysis: Benchmarks current sales against historical averages.
    - Part-to-Whole: Evaluates category contributions to total revenue.
    - Data Segmentation: Groups products and customers based on value and cost.
===============================================================================
*/

-- =============================================================================
-- 1. CHANGE OVER TIME ANALYSIS
-- =============================================================================
/* Goal: Track high-level strategic growth and seasonal fluctuations.
*/

-- Yearly Performance: Revenue and Customer Acquisition
SELECT 
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year;

-- Monthly Performance: Seasonality discovery
SELECT 
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- =============================================================================
-- 2. CUMULATIVE & MOVING AVERAGE ANALYSIS
-- =============================================================================
/* Goal: Understand if the business trajectory is accelerating or declining.
*/

SELECT 
    order_year,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_year) AS running_total_sales,
    AVG(avg_price) OVER (ORDER BY order_year) AS moving_avg_price
FROM (
    SELECT 
        DATE_FORMAT(order_date, '%Y') AS order_year,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY order_year
) AS yearly_summary;

-- =============================================================================
-- 3. PERFORMANCE ANALYSIS (Benchmarking)
-- =============================================================================
/* Goal: Compare product performance against its own average and previous years.
*/

WITH yearly_product_sales AS (
    SELECT 
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f 
    LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT 
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
        ELSE 'Average'
    END AS performance_status,
    /* Year-over-Year (YoY) Growth */
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS prev_year_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS yoy_diff,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS yoy_trend
FROM yearly_product_sales
ORDER BY product_name, order_year;

-- =============================================================================
-- 4. PART-TO-WHOLE ANALYSIS (Proportional)
-- =============================================================================
/* Goal: Identify which categories drive the most revenue for the business.
*/

WITH category_sales AS ( 
    SELECT 
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    GROUP BY p.category
) 
SELECT 
    category,
    total_sales,
    SUM(total_sales) OVER() AS global_sales,
    CONCAT(ROUND(total_sales / SUM(total_sales) OVER() * 100, 2), '%') AS pct_contribution
FROM category_sales
ORDER BY total_sales DESC;

-- =============================================================================
-- 5. DATA SEGMENTATION
-- =============================================================================
/* Goal: Categorize data based on value and behavior thresholds.
*/

-- Product Cost Range Segmentation
SELECT 
    cost_range,
    COUNT(product_key) AS product_count
FROM (
    SELECT 
        product_key,
        CASE
            WHEN cost < 100 THEN 'Budget (<100)'
            WHEN cost BETWEEN 100 AND 500 THEN 'Mid-Tier (100-500)'
            WHEN cost BETWEEN 500 AND 1000 THEN 'Premium (500-1000)'
            ELSE 'Luxury (>1000)'
        END AS cost_range
    FROM gold.dim_products
) AS segmented_products
GROUP BY cost_range 
ORDER BY product_count DESC;

-- Customer Value Segmentation (RFM-Lite)
WITH customer_spending AS (
    SELECT 
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM gold.fact_sales f 
    LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
    GROUP BY c.customer_key
)
SELECT 
    segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT 
        customer_key,
        CASE 
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS segment
    FROM customer_spending
) AS classified_customers
GROUP BY segment
ORDER BY total_customers DESC;
