drop table if exists zepto;

create table zepto (
sku_id SERIAL PRIMARY KEY,
category VARCHAR(120),
name VARCHAR(150) NOT NULL,
mrp NUMERIC(8,2),
discountPercent NUMERIC(5,2),
availableQuantity INTEGER,
discountedSellingPrice NUMERIC(8,2),
weightInGms INTEGER,
outOfStock BOOLEAN,	
quantity INTEGER
);

--data exploration

--count of rows
select count(*) from zepto;

--sample data
SELECT * FROM zepto
LIMIT 10;

--null values
SELECT * FROM zepto
WHERE name IS NULL
OR
category IS NULL
OR
mrp IS NULL
OR
discountPercent IS NULL
OR
discountedSellingPrice IS NULL
OR
weightInGms IS NULL
OR
availableQuantity IS NULL
OR
outOfStock IS NULL
OR
quantity IS NULL;

--different product categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

--products in stock vs out of stock
SELECT outOfStock, COUNT(sku_id)
FROM zepto
GROUP BY outOfStock;

--product names present multiple times
SELECT name, COUNT(sku_id) AS "Number of SKUs"
FROM zepto
GROUP BY name
HAVING count(sku_id) > 1
ORDER BY count(sku_id) DESC;

--data cleaning

--products with price = 0
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;

--convert paise to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto;

--data analysis

-- Q1. Find the top 10 best-value products based on the discount percentage.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

--Q2.What are the Products with High MRP but Out of Stock

SELECT DISTINCT name,mrp
FROM zepto
WHERE outOfStock = TRUE and mrp > 300
ORDER BY mrp DESC;

--Q3.Calculate Estimated Revenue for each category
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
SELECT category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6. Find the price per gram for products above 100g and sort by best value.
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

--Q7.Group the products into categories like Low, Medium, Bulk.
SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto;

--Q8.What is the Total Inventory Weight Per Category 
SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight;

-- Q9. Which products are listed more than once (multiple SKUs / pack sizes)?
SELECT name,
       COUNT(*)                          AS sku_count,
       MIN(discountedsellingprice)       AS min_price,
       MAX(discountedsellingprice)       AS max_price
FROM zepto
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY sku_count DESC;

-- Q10. Each category's share of total estimated revenue (%)
SELECT category,
       SUM(discountedsellingprice * availablequantity)                 AS revenue,
       ROUND(100.0 * SUM(discountedsellingprice * availablequantity)
             / SUM(SUM(discountedsellingprice * availablequantity)) OVER (), 2) AS revenue_share_pct
FROM zepto
GROUP BY category
ORDER BY revenue DESC;

-- Q11. Out-of-stock rate for each category
SELECT category,
       COUNT(*)                                             AS total_products,
       COUNT(*) FILTER (WHERE outofstock)                   AS out_of_stock_products,
       ROUND(100.0 * COUNT(*) FILTER (WHERE outofstock) / COUNT(*), 2) AS oos_rate_pct
FROM zepto
GROUP BY category
ORDER BY oos_rate_pct DESC;

-- Q12. Top 3 highest-discount products within each category
SELECT *
FROM (
    SELECT category, name, mrp, discountpercent,
           ROW_NUMBER() OVER (PARTITION BY category
                              ORDER BY discountpercent DESC, mrp DESC) AS rn
    FROM zepto
) t
WHERE rn <= 3
ORDER BY category, rn;

-- Q13. Top 10 products by absolute savings per unit (MRP - selling price)
SELECT name, category, mrp, discountedsellingprice,
       (mrp - discountedsellingprice) AS savings_per_unit
FROM zepto
ORDER BY savings_per_unit DESC
LIMIT 10;

-- Q14. Categories whose average discount is above the overall average discount
SELECT category,
       ROUND(AVG(discountpercent), 2) AS avg_discount
FROM zepto
GROUP BY category
HAVING AVG(discountpercent) > (SELECT AVG(discountpercent) FROM zepto)
ORDER BY avg_discount DESC;

-- Q15. Data quality check: rows where stated discount % doesn't match MRP vs selling price
--      (tolerance of 1 percentage point for rounding)
SELECT name, category, mrp, discountedsellingprice, discountpercent,
       ROUND(100.0 * (mrp - discountedsellingprice) / NULLIF(mrp, 0), 2) AS calculated_discount
FROM zepto
WHERE ABS(discountpercent - 100.0 * (mrp - discountedsellingprice) / NULLIF(mrp, 0)) > 1
ORDER BY ABS(discountpercent - 100.0 * (mrp - discountedsellingprice) / NULLIF(mrp, 0)) DESC;

-- Q16. Distribution of products across discount bands
SELECT CASE
           WHEN discountpercent = 0               THEN '0% (No discount)'
           WHEN discountpercent BETWEEN 1  AND 10 THEN '1-10%'
           WHEN discountpercent BETWEEN 11 AND 20 THEN '11-20%'
           WHEN discountpercent BETWEEN 21 AND 30 THEN '21-30%'
           ELSE '30%+'
       END AS discount_band,
       COUNT(*) AS product_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_products
FROM zepto
GROUP BY discount_band
ORDER BY MIN(discountpercent);

-- Q17. Median and 90th percentile selling price per category
SELECT category,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY discountedsellingprice) AS median_price,
       PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY discountedsellingprice) AS p90_price
FROM zepto
GROUP BY category
ORDER BY median_price DESC;

-- Q18. Pareto analysis: cumulative revenue % by category (which categories drive ~80% of revenue?)
WITH cat_rev AS (
    SELECT category, SUM(discountedsellingprice * availablequantity) AS revenue
    FROM zepto
    GROUP BY category
)
SELECT category, revenue,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
             / SUM(revenue) OVER (), 2) AS cumulative_revenue_pct
FROM cat_rev
ORDER BY revenue DESC;

-- Q19. In-stock products running low (1-2 units left) that carry a discount of 15% or more
SELECT name, category, availablequantity, discountpercent, discountedsellingprice
FROM zepto
WHERE outofstock = FALSE
  AND availablequantity BETWEEN 1 AND 2
  AND discountpercent >= 15
ORDER BY discountpercent DESC, availablequantity;

-- Q20. Cheapest product per 100g in each category (products of 100g or more)
SELECT DISTINCT ON (category)
       category, name, weightingms, discountedsellingprice,
       ROUND(discountedsellingprice * 100.0 / weightingms, 2) AS price_per_100g
FROM zepto
WHERE weightingms >= 100
ORDER BY category, discountedsellingprice * 100.0 / weightingms ASC;

-- Q21. Average price, discount and stock-out rate side by side (category scorecard)
SELECT category,
       COUNT(*) AS products,
       ROUND(AVG(discountedsellingprice), 2) AS avg_price,
       ROUND(AVG(discountpercent), 2) AS avg_discount_pct,
       ROUND(100.0 * AVG(CASE WHEN outofstock THEN 1 ELSE 0 END), 2) AS oos_rate_pct,
       SUM(availablequantity) AS total_units_available
FROM zepto
GROUP BY category
ORDER BY avg_discount_pct DESC;

-- Q22. Are heavily discounted products more likely to be out of stock?
SELECT CASE 
	WHEN discountpercent >= 20 THEN 'High discount (20%+)'
    WHEN discountpercent >= 10 THEN 'Medium discount (10-19%)'
    	ELSE 'Low discount (<10%)' END AS discount_tier,
   COUNT(*) AS products,
   ROUND(100.0 * AVG(CASE WHEN outofstock THEN 1 ELSE 0 END), 2) AS oos_rate_pct
FROM zepto
GROUP BY discount_tier
ORDER BY oos_rate_pct DESC;

