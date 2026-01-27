/*
===============================================================================
Exploratory Data Analysis (EDA) - Gold Layer
===============================================================================
Script Purpose:
    This script performs a comprehensive analysis of the Gold Layer. 
    It covers database metadata, data profiling (min/max/averages), 
    and business metric aggregations to ensure the warehouse is accurate 
    and ready for reporting.

Usage Notes:
    - Run these queries to understand the data distribution and quality.
    - These queries provide the foundation for building dashboards (KPIs).
===============================================================================
*/

-- =============================================================================
-- 1. DATABASE METADATA EXPLORATION
-- =============================================================================

-- List all tables and views in the project schemas
SELECT table_schema, table_name, table_type 
FROM information_schema.tables 
WHERE table_schema IN ('bronze', 'silver', 'gold');

-- Verify Gold layer naming conventions and data types
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'gold'
ORDER BY table_name, ordinal_position;

-- =============================================================================
-- 2. DIMENSION PROFILING (Customers & Products)
-- =============================================================================

-- Identify geographic reach
SELECT DISTINCT country FROM gold.dim_customers;

-- Map the "Major Divisions" of the product catalog
SELECT DISTINCT category, subcategory, product_name 
FROM gold.dim_products
ORDER BY 1, 2, 3;

-- Profile customer age demographics
SELECT 
    MIN(birthdate) AS oldest_birthdate,
    MAX(birthdate) AS youngest_birthdate,
    TIMESTAMPDIFF(YEAR, MIN(birthdate), CURDATE()) AS oldest_age,
    TIMESTAMPDIFF(YEAR, MAX(birthdate), CURDATE()) AS youngest_age
FROM gold.dim_customers;

-- =============================================================================
-- 3. FACT PROFILING (Sales & Timeline)
-- =============================================================================

-- Determine the total timespan of sales data
SELECT 
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    TIMESTAMPDIFF(YEAR, MIN(order_date), MAX(order_date)) AS years_of_data
FROM gold.fact_sales;

-- Check high-level sales metrics
SELECT 
    SUM(sales_amount) AS total_revenue,
    SUM(quantity) AS total_items_sold,
    AVG(price) AS avg_unit_price,
    COUNT(order_number) AS total_orders,
    COUNT(DISTINCT order_number) AS unique_orders -- Compare to check for duplicates
FROM gold.fact_sales;

-- =============================================================================
-- 4. BUSINESS KPI REPORT (Unified View)
-- =============================================================================

-- Generate a single report for all primary business measures
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL 
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Unique Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Products', COUNT(product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;

-- =============================================================================
-- 5. CATEGORY & GEOGRAPHIC ANALYSIS (Low Cardinality)
-- =============================================================================

-- Group customers by Country
SELECT country, COUNT(customer_key) AS customer_count
FROM gold.dim_customers
GROUP BY country ORDER BY customer_count DESC;

-- Group products by Category
SELECT category, COUNT(product_key) AS product_count, AVG(cost) AS avg_category_cost
FROM gold.dim_products
GROUP BY category ORDER BY product_count DESC;

-- Revenue by Category (Joining Fact to Products)
SELECT p.category, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f 
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key 
GROUP BY p.category ORDER BY total_revenue DESC;

-- =============================================================================
-- 6. PRODUCT PERFORMANCE (Ranking)
-- =============================================================================

-- Top 5 products by revenue (Standard Limit)
SELECT p.product_name, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f 
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key 
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Top 5 products by revenue (CTE + Window Function for cleaner logic)
WITH product_rankings AS (
    SELECT 
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) DESC) AS rank_desc
    FROM gold.fact_sales f 
    LEFT JOIN gold.dim_products p ON f.product_key = p.product_key 
    GROUP BY p.product_name
)
SELECT * FROM product_rankings WHERE rank_desc <= 5;

-- 5 Worst performing products by revenue
SELECT p.product_name, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f 
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key 
GROUP BY p.product_name
ORDER BY total_revenue ASC
LIMIT 5;
