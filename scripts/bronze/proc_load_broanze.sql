/*
===============================================================================
Script Name   : bronze_load.sql
Purpose       : Load data into the Bronze layer of the Data Warehouse.

Script Purpose:
    - Truncate all Bronze tables to prepare for fresh data load.
    - Load CSV files from source directories into Bronze tables.
    - Verify successful load by counting rows.

Notes:
    - LOAD DATA LOCAL INFILE cannot be executed inside a stored procedure in MySQL.
    - CSVs must be placed in a directory accessible by MySQL client.
    - Run this script from MySQL CLI with --local-infile=1
      Example: "mysql -u root -p --local-infile=1 < bronze_load.sql"
===============================================================================
*/

-- ===========================================================================
-- Step 1: Select the Bronze database
-- ===========================================================================
USE bronze;

-- ===========================================================================
-- Step 2: Create stored procedure to truncate all Bronze tables
-- ===========================================================================
DELIMITER $$

CREATE PROCEDURE bronze.truncate_bronze_tables()
BEGIN
    -- Error handler in case truncation fails
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR OCCURRED DURING TRUNCATING TABLES' AS error_message;
    END;

    -- Truncate CRM Tables
    TRUNCATE TABLE bronze.crm_cust_info;
    TRUNCATE TABLE bronze.crm_prd_info;
    TRUNCATE TABLE bronze.crm_sales_details;

    -- Truncate ERP Tables
    TRUNCATE TABLE bronze.erp_loc_a101;
    TRUNCATE TABLE bronze.erp_cust_az12;
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    -- Confirmation message
    SELECT 'All bronze tables truncated successfully' AS status;
END $$

DELIMITER ;

-- ===========================================================================
-- Step 3: Call the procedure to truncate all Bronze tables
-- ===========================================================================
CALL bronze.truncate_bronze_tables();

-- ===========================================================================
-- Step 4: Load CSV files into Bronze tables
-- ===========================================================================
-- CRM Tables
LOAD DATA LOCAL INFILE 'E:/Skill/sql-data-warehouse-project-main/datasets/source_crm/cust_info.csv'
INTO TABLE bronze.crm_cust_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/Skill/sql-data-warehouse-project-main/datasets/source_crm/prd_info.csv'
INTO TABLE bronze.crm_prd_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/Skill/sql-data-warehouse-project-main/datasets/source_crm/sales_details.csv'
INTO TABLE bronze.crm_sales_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ERP Tables
LOAD DATA LOCAL INFILE 'E:/Skill/sql-data-warehouse-project-main/datasets/source_erp/loc_a101.csv'
INTO TABLE bronze.erp_loc_a101
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/Skill/sql-data-warehouse-project-main/datasets/source_erp/cust_az12.csv'
INTO TABLE bronze.erp_cust_az12
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/Skill/sql-data-warehouse-project-main/datasets/source_erp/px_cat_g1v2.csv'
INTO TABLE bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ===========================================================================
-- Step 5: Verify loaded data (row counts)
-- ===========================================================================
SELECT COUNT(*) AS crm_cust_info_rows FROM bronze.crm_cust_info;
SELECT COUNT(*) AS crm_prd_info_rows FROM bronze.crm_prd_info;
SELECT COUNT(*) AS crm_sales_details_rows FROM bronze.crm_sales_details;
SELECT COUNT(*) AS erp_loc_a101_rows FROM bronze.erp_loc_a101;
SELECT COUNT(*) AS erp_cust_az12_rows FROM bronze.erp_cust_az12;
SELECT COUNT(*) AS erp_px_cat_g1v2_rows FROM bronze.erp_px_cat_g1v2;

-- ===========================================================================
-- End of Bronze Load Script
-- ===========================================================================
