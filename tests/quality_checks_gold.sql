/*
===============================================================================
Quality Check Script: quality_checks_gold
===============================================================================
Script Purpose:
    This script performs final data validation on the Gold Layer tables. 
    It focuses on:
    - Data Exploration: Reviewing the consolidated customer and product records.
    - Integrity Checks: Ensuring that the Star Schema relationships (Fact to 
      Dimensions) are intact and no "orphaned" sales exist.
    - Standardization: Verifying that columns like 'gender' have been correctly 
      unified from multiple sources.

Usage Notes:
    - Execute this script after refreshing the Gold Views.
    - The Foreign Key Integrity check should return ZERO results. If rows appear, 
      it indicates sales tied to missing or inactive products/customers.
===============================================================================
*/

-- =============================================================================
-- 1. DATA EXPLORATION: Customers
-- =============================================================================

-- View the full "Golden Record" for customers
SELECT * FROM gold.dim_customers;

-- Verify Gender Standardization: Ensure logic correctly handled CRM and ERP sources
SELECT DISTINCT gender FROM gold.dim_customers;

-- =============================================================================
-- 2. DATA EXPLORATION: Products
-- =============================================================================

-- View the consolidated product catalog (Active records only)
SELECT * FROM gold.dim_products;

-- =============================================================================
-- 3. INTEGRITY CHECK: Star Schema Relationships
-- =============================================================================

/* Logic: Perform a LEFT JOIN from Fact to Dimensions. 
   If a sale exists but its product_key is NULL in the result, 
   it means the sale is an "orphan" (missing its dimension link).
*/

-- Check for unmatched Sales records (Foreign Key Integrity)
SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL; -- Expectation: No result
