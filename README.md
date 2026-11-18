# 🛒 Zepto Inventory Analysis

An end-to-end SQL analysis of Zepto's product inventory, covering data exploration, cleaning, and business-focused analysis using PostgreSQL. The project uses advanced SQL such as window functions, CTEs, and percentile analysis to answer pricing, discounting, and stock-availability questions.

## 📌 Project Overview

Quick-commerce platforms depend on pricing and inventory decisions. This project answers questions such as:
- Which categories drive the most revenue?
- Where are discounts deepest, and are they accurate?
- Which high-value products are going out of stock?
- Which products give the best value per gram?

## 📂 Dataset

| Column | Description |
|---|---|
| `category` | Product category (14 categories) |
| `name` | Product name |
| `mrp` | Maximum retail price (stored in paise, converted to ₹) |
| `discountPercent` | Discount offered on MRP |
| `availableQuantity` | Units available in stock |
| `discountedSellingPrice` | Selling price after discount |
| `weightInGms` | Product weight in grams |
| `outOfStock` | Stock availability flag |
| `quantity` | Pack quantity |

**Size:** 3,732 raw rows, 3,731 after cleaning, 1,680 unique product names.

## 🧹 Data Cleaning
- Checked for NULL values across all columns
- Found and removed rows with `mrp = 0`
- Converted `mrp` and `discountedSellingPrice` from paise to rupees
- Identified products listed under multiple SKUs (different pack sizes)
- Verified stated discount % against the discount calculated from MRP and selling price (0 mismatches)

## 🔍 Analysis Performed (22 queries)

| Area | Examples |
|---|---|
| **Pricing & Discounts** | Best-value products, high-MRP low-discount items, average discount by category, discount bands |
| **Revenue** | Estimated revenue per category, revenue share %, Pareto (cumulative revenue %) analysis |
| **Inventory** | Out-of-stock rate per category, high-MRP out-of-stock items, low-stock discounted items, total inventory weight |
| **Value Metrics** | Price per gram, cheapest price per 100g per category, weight segmentation (Low / Medium / Bulk) |
| **Data Quality** | Duplicate SKUs, discount-percentage validation |
| **Advanced SQL** | `ROW_NUMBER`, `SUM() OVER`, `DISTINCT ON`, `PERCENTILE_CONT`, `FILTER`, CTEs, subqueries |

## 📊 Key Findings
- **12.1%** of products (453 of 3,731) are out of stock
- **~₹22.4 lakh** estimated total revenue (selling price × available quantity)
- **Cooking Essentials and Munchies** each contribute about **15%** of revenue, making them the top 2 of 14 categories
- **Fruits & Vegetables** has the highest average discount (**~15.5%**)
- About **31.5%** of products carry no discount at all

## 🛠️ Tech Stack
- PostgreSQL
- SQL (window functions, CTEs, aggregate filters, percentile functions)
- pgAdmin / psql

## ▶️ How to Run
1. Create the database and run the `CREATE TABLE` statement from `Zepto_inventory_analysis.sql`.
2. Import the CSV:
   ```sql
   \copy zepto(category,name,mrp,discountPercent,availableQuantity,discountedSellingPrice,weightInGms,outOfStock,quantity)
   FROM 'zepto_v2.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
   ```
3. Run the cleaning section **once only**. The paise-to-rupee `UPDATE` is not idempotent, so running it twice divides prices by 100 again.
4. Run the analysis queries (Q1 to Q22).

## 📁 Repository Structure
```
├── Zepto_inventory_analysis.sql   # Schema, cleaning, and all 22 queries
├── zepto_v2.csv                   # Dataset
└── README.md
```
