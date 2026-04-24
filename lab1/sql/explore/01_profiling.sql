SELECT COUNT(*) AS total_rows FROM mock_data;


SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT id) AS distinct_id FROM mock_data;


SELECT MIN(sale_customer_id::INT), MAX(sale_customer_id::INT) FROM mock_data WHERE sale_customer_id ~ '^[0-9]+$';
SELECT COUNT(DISTINCT sale_customer_id) FROM mock_data;
SELECT COUNT(DISTINCT sale_seller_id) FROM mock_data;
SELECT COUNT(DISTINCT sale_product_id) FROM mock_data;


SELECT product_category, COUNT(*) FROM mock_data GROUP BY 1 ORDER BY 2 DESC;
SELECT store_country, COUNT(*) FROM mock_data GROUP BY 1 ORDER BY 2 DESC;
SELECT supplier_country, COUNT(*) FROM mock_data GROUP BY 1 ORDER BY 2 DESC;


SELECT MIN(sale_date), MAX(sale_date) FROM mock_data;
SELECT sale_date, COUNT(*) AS cnt FROM mock_data GROUP BY 1 ORDER BY cnt DESC LIMIT 15;


SELECT row_id, sale_customer_id, sale_seller_id, sale_product_id, sale_quantity, sale_total_price, sale_date
FROM mock_data
LIMIT 5;
