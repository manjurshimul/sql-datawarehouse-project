/*
===============================================================================
Stored Procedure: Load Silver Layer (ETL Process)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process 
    to populate the Silver layer tables from the Bronze layer.
	
    Validation & Cleaning performed:
    - Standardizes Gender and Marital Status (using REGEXP).
    - Cleans country names and product lines.
    - Handles invalid '0000-00-00' dates by converting them to NULL.
    - Deduplicates customer data using ROW_NUMBER().
    - Recalculates Sales/Price logic to ensure mathematical integrity.

Parameters:
    None

Usage:
    CALL silver_load_silver();

===============================================================================
*/
DROP PROCEDURE IF EXISTS silver_load_silver;
DELIMITER $$

CREATE PROCEDURE silver_load_silver()
BEGIN
    -- 1. DECLARE VARIABLES FOR TIMING
    DECLARE start_time_total DATETIME;
    DECLARE end_time_total DATETIME;
    DECLARE start_time_step DATETIME;
    DECLARE end_time_step DATETIME;

    -- 2. ERROR HANDLING (TRY-CATCH EQUIVALENT)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            @sqlstate_val = RETURNED_SQLSTATE, 
            @errno_val = MYSQL_ERRNO, 
            @text_val = MESSAGE_TEXT;
        SELECT 'ERROR' AS Status, @sqlstate_val AS SQL_State, @errno_val AS Error_No, @text_val AS Error_Message;
    END;

    SET start_time_total = NOW();
    SELECT '--- STARTING SILVER LAYER LOAD ---' AS Info;

    -- =============================================================================
    -- STEP 1: GLOBAL PREPARATION
    -- =============================================================================
    SELECT '>> Step 1: Global Preparation' AS Progress;
    SET SESSION sql_mode = '';
    ALTER TABLE silver.crm_cust_info MODIFY COLUMN cst_create_date DATE NULL;

    -- =============================================================================
    -- STEP 2: LOAD silver.crm_cust_info
    -- =============================================================================
    SET start_time_step = NOW();
    SELECT '>> Step 2: Loading silver.crm_cust_info' AS Progress;
    
    TRUNCATE TABLE silver.crm_cust_info;
    INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
    SELECT cst_id, cst_key, TRIM(cst_firstname), TRIM(cst_lastname),
        CASE WHEN cst_marital_status REGEXP '^M|Married' THEN 'Married'
             WHEN cst_marital_status REGEXP '^S|Single'  THEN 'Single' ELSE 'N/A' END,
        CASE WHEN cst_gndr REGEXP '^F|Female' THEN 'Female'
             WHEN cst_gndr REGEXP '^M|Male'   THEN 'Male' ELSE 'N/A' END,
        CASE WHEN cst_create_date = '0000-00-00' THEN NULL ELSE cst_create_date END
    FROM (
        SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL
    ) t WHERE flag_last = 1;
    
    SET end_time_step = NOW();
    SELECT CONCAT('Finished crm_cust_info. Duration: ', TIMEDIFF(end_time_step, start_time_step)) AS Step_Log;

    -- =============================================================================
    -- STEP 3: LOAD silver.crm_prd_info
    -- =============================================================================
    SET start_time_step = NOW();
    SELECT '>> Step 3: Loading silver.crm_prd_info' AS Progress;
    
    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
    SELECT prd_id, REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'), SUBSTRING(prd_key, 7, LENGTH(prd_key)),
        prd_nm, prd_cost,
        CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
             WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
             WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
             WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring' ELSE 'N/A' END,
        CAST(prd_start_dt AS DATE),
        CAST(DATE_SUB(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt), INTERVAL 1 DAY) AS DATE)
    FROM bronze.crm_prd_info;
    
    SET end_time_step = NOW();
    SELECT CONCAT('Finished crm_prd_info. Duration: ', TIMEDIFF(end_time_step, start_time_step)) AS Step_Log;

    -- =============================================================================
    -- STEP 4: LOAD silver.crm_sales_details
    -- =============================================================================
    SET start_time_step = NOW();
    SELECT '>> Step 4: Loading silver.crm_sales_details' AS Progress;
    
    TRUNCATE TABLE silver.crm_sales_details;
    INSERT INTO silver.crm_sales_details (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
    SELECT sls_ord_num, sls_prd_key, sls_cust_id,
        CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 THEN NULL ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d') END,
        CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 THEN NULL ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d') END,
        CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 THEN NULL ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d') END,
        sls_sales, sls_quantity,
        CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0) ELSE sls_price END
    FROM (
        SELECT sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_quantity, sls_price,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
                 THEN sls_quantity * ABS(sls_price) ELSE sls_sales END AS sls_sales
        FROM bronze.crm_sales_details
    ) t WHERE sls_sales > 0 AND sls_quantity > 0;
    
    SET end_time_step = NOW();
    SELECT CONCAT('Finished crm_sales_details. Duration: ', TIMEDIFF(end_time_step, start_time_step)) AS Step_Log;

    -- =============================================================================
    -- STEP 5: LOAD silver.erp_cust_az12
    -- =============================================================================
    SET start_time_step = NOW();
    SELECT '>> Step 5: Loading silver.erp_cust_az12' AS Progress;
    
    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) ELSE cid END,
        CASE WHEN bdate > NOW() THEN NULL ELSE bdate END,
        CASE WHEN gen REGEXP 'F|Female' THEN 'Female' WHEN gen REGEXP 'M|Male' THEN 'Male' ELSE 'N/A' END
    FROM bronze.erp_cust_az12;
    
    SET end_time_step = NOW();
    SELECT CONCAT('Finished erp_cust_az12. Duration: ', TIMEDIFF(end_time_step, start_time_step)) AS Step_Log;

    -- =============================================================================
    -- STEP 6: LOAD silver.erp_loc_a101
    -- =============================================================================
    SET start_time_step = NOW();
    SELECT '>> Step 6: Loading silver.erp_loc_a101' AS Progress;
    
    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT REPLACE(cid, '-', ''),
        CASE WHEN cntry REGEXP '^Australia' THEN 'Australia'
             WHEN cntry REGEXP '^Canada'    THEN 'Canada'
             WHEN cntry REGEXP '^France'    THEN 'France'
             WHEN cntry REGEXP '^Germany|^DE' THEN 'Germany'
             WHEN cntry REGEXP '^USA|^United S|^US' THEN 'United States'
             WHEN cntry REGEXP '^United K|^UK' THEN 'United Kingdom'
             WHEN cntry IS NULL OR TRIM(cntry) = '' OR cntry NOT REGEXP '[A-Za-z0-9]' THEN 'N/A' ELSE TRIM(cntry) END
    FROM bronze.erp_loc_a101;
    
    SET end_time_step = NOW();
    SELECT CONCAT('Finished erp_loc_a101. Duration: ', TIMEDIFF(end_time_step, start_time_step)) AS Step_Log;

    -- =============================================================================
    -- STEP 7: LOAD silver.erp_px_cat_g1v2
    -- =============================================================================
    SET start_time_step = NOW();
    SELECT '>> Step 7: Loading silver.erp_px_cat_g1v2' AS Progress;
    
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat,
        CASE WHEN maintenance REGEXP '^Y|^Yes' THEN 'Yes'
             WHEN maintenance REGEXP '^N|^No'  THEN 'No' ELSE 'N/A' END
    FROM bronze.erp_px_cat_g1v2;
    
    SET end_time_step = NOW();
    SELECT CONCAT('Finished erp_px_cat_g1v2. Duration: ', TIMEDIFF(end_time_step, start_time_step)) AS Step_Log;

    -- =============================================================================
    -- FINAL SUMMARY
    -- =============================================================================
    SET end_time_total = NOW();
    SELECT '--- SILVER LAYER LOAD COMPLETE ---' AS Info;
    SELECT CONCAT('Total Execution Time: ', TIMEDIFF(end_time_total, start_time_total)) AS Total_Duration;

END$$
DELIMITER ;
