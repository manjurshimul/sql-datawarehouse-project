/* =========================================================
   STEP 1 : Switch to Silver database
   Purpose : Create cleaned and standardized tables for Silver layer
   ========================================================= */

USE silver;


/* =========================================================
   STEP 2 : Create CRM Customer Information table (Silver)
   ========================================================= */

DROP TABLE IF EXISTS crm_cust_info;

CREATE TABLE crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* =========================================================
   STEP 3 : Create CRM Product Information table (Silver)
   ========================================================= */

DROP TABLE IF EXISTS crm_prd_info;

CREATE TABLE crm_prd_info (
    prd_id       INT,
    cat_id		 VARCHAR(50),
    prd_key      VARCHAR(50),
    prd_nm       VARCHAR(50),
    prd_cost     INT,
    prd_line     VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt   DATE,
    dwh_create_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* =========================================================
   STEP 4 : Create CRM Sales Details table (Silver)
   ========================================================= */

DROP TABLE IF EXISTS crm_sales_details;

CREATE TABLE crm_sales_details (
    sls_ord_num  VARCHAR(50),
    sls_prd_key  VARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt date,
    sls_ship_dt  date,
    sls_due_dt   date,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT,
    dwh_create_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* =========================================================
   STEP 5 : Create ERP Location table (Silver)
   ========================================================= */

DROP TABLE IF EXISTS erp_loc_a101;

CREATE TABLE erp_loc_a101 (
    cid    VARCHAR(50),
    cntry  VARCHAR(50),
    dwh_create_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* =========================================================
   STEP 6 : Create ERP Customer Demographics table (Silver)
   ========================================================= */

DROP TABLE IF EXISTS erp_cust_az12;

CREATE TABLE erp_cust_az12 (
    cid    VARCHAR(50),
    bdate  DATE,
    gen    VARCHAR(50),
    dwh_create_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* =========================================================
   STEP 7 : Create ERP Product Category table (Silver)
   ========================================================= */

DROP TABLE IF EXISTS erp_px_cat_g1v2;

CREATE TABLE erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50),
    dwh_create_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

/* =========================================================
   End of Silver Layer Table Creation Script
   ========================================================= */
