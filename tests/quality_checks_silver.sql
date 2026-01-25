/*
===============================================================================
Script Name: Data Quality Validation for Silver Layer
Script Purpose: 
    This script performs various Quality Assurance (QA) checks on the Silver layer 
    to ensure data integrity, standardization, and mathematical accuracy.
Usage Notes:
    - Run these queries after executing the 'silver_load_silver' procedure.
    - Every query is designed with an "Expectation: No Result" goal.
    - Any returned rows indicate data quality issues that need to be investigated.
===============================================================================
*/

-- =============================================================================
-- 1. TABLE: silver.crm_cust_info
-- =============================================================================

-- Validate Primary Key (cst_id): Check for duplicates or NULLs
SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for remaining whitespace in string fields
SELECT cst_lastname FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Verify standardization of Marital Status
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;


-- =============================================================================
-- 2. TABLE: silver.crm_prd_info
-- =============================================================================

-- Validate Primary Key (prd_id)
SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for negative or missing product costs
SELECT prd_cost FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Ensure prd_line mapping is consistent
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- Check for logical date errors (Start Date must be before End Date)
SELECT prd_id, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- =============================================================================
-- 3. TABLE: silver.crm_sales_details
-- =============================================================================

-- Verify mathematical integrity: Sales = Quantity * Price
-- Also checks for NULLs or non-positive values
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL;


-- =============================================================================
-- 4. TABLE: silver.erp_cust_az12
-- =============================================================================

-- Identify improbable or future birthdates
SELECT bdate FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > NOW();

-- Verify Gender standardization
SELECT DISTINCT gen FROM silver.erp_cust_az12;


-- =============================================================================
-- 5. TABLE: silver.erp_loc_a101
-- =============================================================================

-- Ensure country names are standardized and clean
SELECT DISTINCT cntry FROM silver.erp_loc_a101;


-- =============================================================================
-- 6. TABLE: silver.erp_px_cat_g1v2
-- =============================================================================

-- Verify maintenance status standardization (Yes/No/N/A)
SELECT DISTINCT maintenance FROM silver.erp_px_cat_g1v2;
