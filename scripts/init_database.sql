/* =========================================================
   STEP 1 : IMPORTANT NOTE (MySQL)
   ---------------------------------------------------------
   - In MySQL, SCHEMA and DATABASE are the SAME thing
   - CREATE SCHEMA = CREATE DATABASE
   - MySQL does NOT support schemas inside a database
   ========================================================= */


/* =========================================================
   STEP 2 : Create Bronze, Silver, and Gold layers
   (Each layer is implemented as a SEPARATE DATABASE)
   ========================================================= */

CREATE DATABASE IF NOT EXISTS bronze
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

CREATE DATABASE IF NOT EXISTS silver
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

CREATE DATABASE IF NOT EXISTS gold
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;
