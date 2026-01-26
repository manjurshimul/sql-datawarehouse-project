/*
===============================================================================
DDL Script: Create Gold Layer Views
===============================================================================
Script Purpose:
    This script defines the views for the Gold layer in the Data Warehouse.
    The Gold layer represents the final, presentation-ready Star Schema 
    designed for BI reporting.

Usage Notes:
    - Run this script after the Silver layer load is complete.
    - These views create Surrogate Keys using ROW_NUMBER() to decouple 
      the Data Warehouse from source system changes.
===============================================================================
*/

-- =============================================================================
-- 1. VIEW: gold.dim_customers
-- =============================================================================
/*
Script Purpose:
    Creates a unified "Golden Record" for customers by merging cleaned CRM 
    and ERP data.
Usage Notes:
    - Surrogate Key: 'customer_key' is generated for stable joins.
    - Logic: CRM is master for gender; ERP is used as a fallback.
*/

CREATE OR REPLACE VIEW gold.dim_customers AS
SELECT 
    -- 1. SURROGATE KEY
    ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key,

    -- 2. BUSINESS KEYS
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,

    -- 3. ATTRIBUTES
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,

    -- 4. CONSOLIDATED GENDER LOGIC
    CASE 
        WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'N/A')
    END AS gender,

    -- 5. LINEAGE
    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci 
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


-- =============================================================================
-- 2. VIEW: gold.dim_products
-- =============================================================================
/*
Script Purpose:
    Creates a unified Product Dimension by joining CRM product info 
    with ERP categories.
Usage Notes:
    - Surrogate Key: 'product_key' generated for Fact table joins.
    - Filtering: Includes only 'Active' products (prd_end_dt is NULL).
*/

CREATE OR REPLACE VIEW gold.dim_products AS
SELECT 
    -- 1. SURROGATE KEY
    ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,

    -- 2. BUSINESS KEYS
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,

    -- 3. ATTRIBUTES
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,

    -- 4. LINEAGE
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc 
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;


-- =============================================================================
-- 3. VIEW: gold.fact_sales
-- =============================================================================
/*
Script Purpose:
    Creates the central Fact table linking sales transactions to Gold 
    dimensions via Surrogate Keys.
Usage Notes:
    - Metrics: Pulls Sales, Quantity, and Price cleaned in Silver.
    - Joins: Uses LEFT JOINs to Gold dimensions to map business keys to SKs.
*/

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT 
    -- 1. BUSINESS KEY
    sd.sls_ord_num AS order_number,

    -- 2. SURROGATE KEY LOOKUPS
    pr.product_key,
    cu.customer_key,

    -- 3. DATES
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,

    -- 4. MEASURES
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
