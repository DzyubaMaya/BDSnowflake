SELECT '--- 1. Top-10 products by revenue ---' AS hdr;
SELECT * FROM reports.report_products ORDER BY sales_rank LIMIT 10;

SELECT '--- 1b. Top-10 by quantity (sales_rank_by_qty) ---' AS hdr;
SELECT product_name, total_qty, sales_rank_by_qty FROM reports.report_products ORDER BY sales_rank_by_qty LIMIT 10;

SELECT '--- 1c. Revenue by product category ---' AS hdr;
SELECT * FROM reports.report_products_by_category ORDER BY total_revenue DESC;

SELECT '--- 2. Top-10 customers by spend ---' AS hdr;
SELECT * FROM reports.report_customers ORDER BY customer_rank LIMIT 10;

SELECT '--- 2b. Customers distribution by country ---' AS hdr;
SELECT * FROM reports.report_customers_by_country ORDER BY customers_cnt DESC LIMIT 10;

SELECT '--- 3. Monthly sales trend ---' AS hdr;
SELECT * FROM reports.report_time ORDER BY year, month;

SELECT '--- 3b. Yearly sales ---' AS hdr;
SELECT * FROM reports.report_time_year ORDER BY year;

SELECT '--- 3c. Month vs prior month ---' AS hdr;
SELECT * FROM reports.report_time_period_compare ORDER BY year, month;

SELECT '--- 4. Top-5 stores by revenue ---' AS hdr;
SELECT * FROM reports.report_stores ORDER BY store_rank LIMIT 5;

SELECT '--- 4b. Sales by store geo ---' AS hdr;
SELECT * FROM reports.report_stores_by_geo ORDER BY total_revenue DESC LIMIT 20;

SELECT '--- 5. Top-5 suppliers by revenue ---' AS hdr;
SELECT * FROM reports.report_suppliers ORDER BY supplier_rank LIMIT 5;

SELECT '--- 5b. Suppliers by country ---' AS hdr;
SELECT * FROM reports.report_suppliers_by_country ORDER BY total_revenue DESC;

SELECT '--- 6. Highest-rated products ---' AS hdr;
SELECT * FROM reports.report_quality ORDER BY rating_rank_desc LIMIT 10;

SELECT '--- 6b. Lowest-rated products ---' AS hdr;
SELECT * FROM reports.report_quality ORDER BY rating_rank_asc LIMIT 10;

SELECT '--- 6c. Most reviewed products ---' AS hdr;
SELECT * FROM reports.report_quality ORDER BY reviews_rank LIMIT 10;

SELECT '--- 6d. Pearson: rating vs qty / revenue (all products) ---' AS hdr;
SELECT * FROM reports.report_quality_correlation;
