# 🌟 Data Catalog: Gold Layer (MySQL)

## 📖 Overview
The **Gold Layer** represents the presentation-ready tier of our data warehouse. It is structured using a **Star Schema** design, optimized for BI tools and complex analytical queries. It transforms technical "Silver" data into business-friendly dimensions and facts.



---

### 1. 👥 `gold.dim_customers`
**Purpose:** Serves as the "Golden Record" for customer information. It integrates CRM demographics with ERP geographic data.

| Column Name | MySQL Data Type | Description |
| :--- | :--- | :--- |
| **customer_key** | `INT` | **Surrogate Key:** Unique identifier for the Gold layer (Generated via `ROW_NUMBER`). |
| **customer_id** | `INT` | Unique numerical identifier from the source CRM system. |
| **customer_number** | `VARCHAR(50)` | Alphanumeric tracking ID (e.g., 'NAS12345'). |
| **first_name** | `VARCHAR(50)` | Cleaned first name of the customer. |
| **last_name** | `VARCHAR(50)` | Cleaned last name/family name. |
| **country** | `VARCHAR(50)` | Standardized country name (e.g., 'United States'). |
| **marital_status** | `VARCHAR(50)` | Standardized status: 'Married', 'Single', or 'N/A'. |
| **gender** | `VARCHAR(50)` | Standardized gender: 'Male', 'Female', or 'N/A'. |
| **birthdate** | `DATE` | Customer date of birth (YYYY-MM-DD). |
| **create_date** | `DATE` | Original account creation date in CRM. |

---

### 2. 📦 `gold.dim_products`
**Purpose:** A unified catalog of all active products, enriched with high-level categories and maintenance metadata.

| Column Name | MySQL Data Type | Description |
| :--- | :--- | :--- |
| **product_key** | `INT` | **Surrogate Key:** Unique identifier for the Gold layer. |
| **product_id** | `INT` | Internal numerical ID assigned to the product. |
| **product_number** | `VARCHAR(50)` | Alphanumeric SKU or product code (e.g., 'AR-5381'). |
| **product_name** | `VARCHAR(50)` | Full descriptive name of the product. |
| **category_id** | `VARCHAR(50)` | Identifier linking to the product category. |
| **category** | `VARCHAR(50)` | High-level classification (e.g., 'Bikes', 'Components'). |
| **subcategory** | `VARCHAR(50)` | Detailed classification (e.g., 'Mountain Bikes'). |
| **maintenance** | `VARCHAR(50)` | Maintenance requirement flag: 'Yes', 'No', or 'N/A'. |
| **cost** | `INT` | Base manufacturing or acquisition cost. |
| **product_line** | `VARCHAR(50)` | Series designation (e.g., 'Road', 'Touring'). |
| **start_date** | `DATE` | Date when this product version became active. |

---

### 3. 💰 `gold.fact_sales`
**Purpose:** The central transaction table containing sales metrics. It links to dimensions via surrogate keys.



| Column Name | MySQL Data Type | Description |
| :--- | :--- | :--- |
| **order_number** | `VARCHAR(50)` | Unique identifier for the sales order (e.g., 'SO54496'). |
| **product_key** | `INT` | **Foreign Key:** Links to `gold.dim_products`. |
| **customer_key** | `INT` | **Foreign Key:** Links to `gold.dim_customers`. |
| **order_date** | `DATE` | Date the order was placed. |
| **shipping_date** | `DATE` | Date the order was shipped. |
| **due_date** | `DATE` | Date the payment was due. |
| **sales_amount** | `INT` | Total value of the transaction ($Qty \times Price$). |
| **quantity** | `INT` | Number of units sold. |
| **price** | `INT` | Unit price at the time of transaction. |

---

## 🛠 Usage
These tables are designed to be queried together. For example, to find total sales by country:
```sql
SELECT 
    c.country, 
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country;
