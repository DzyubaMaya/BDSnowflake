--   docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/lab2/03_postgres_checks.sql

-- 1) Базовые количества
SELECT 'mock_data' AS table_name, COUNT(*) AS cnt FROM public.mock_data;
SELECT 'star.fact_sales' AS table_name, COUNT(*) AS cnt FROM star.fact_sales;

-- 2) Проверка: не потеряли строки при переносе в факт
SELECT COUNT(*) AS lost_rows
FROM public.mock_data m
LEFT JOIN star.fact_sales f ON f.source_row_id = m.row_id
WHERE f.source_row_id IS NULL;

-- 3) Проверка: суммы в staging и в факте совпадают 
SELECT
  ROUND((SELECT SUM(sale_total_price::numeric) FROM public.mock_data)::numeric, 2) AS sum_total_staging,
  ROUND((SELECT SUM(total_price) FROM star.fact_sales)::numeric, 2)                 AS sum_total_fact;

-- 4) Проверка: ключи факта не NULL 
SELECT COUNT(*) AS null_date_key     FROM star.fact_sales WHERE date_key IS NULL;
SELECT COUNT(*) AS null_customer_id  FROM star.fact_sales WHERE customer_id IS NULL;
SELECT COUNT(*) AS null_seller_id    FROM star.fact_sales WHERE seller_id IS NULL;
SELECT COUNT(*) AS null_product_id   FROM star.fact_sales WHERE product_id IS NULL;
SELECT COUNT(*) AS null_store_id     FROM star.fact_sales WHERE store_id IS NULL;
SELECT COUNT(*) AS null_supplier_id  FROM star.fact_sales WHERE supplier_id IS NULL;

-- 5) Проверка: размеры измерений
SELECT 'star.dim_date'     AS table_name, COUNT(*) AS cnt FROM star.dim_date;
SELECT 'star.dim_customer' AS table_name, COUNT(*) AS cnt FROM star.dim_customer;
SELECT 'star.dim_seller'   AS table_name, COUNT(*) AS cnt FROM star.dim_seller;
SELECT 'star.dim_product'  AS table_name, COUNT(*) AS cnt FROM star.dim_product;
SELECT 'star.dim_store'    AS table_name, COUNT(*) AS cnt FROM star.dim_store;
SELECT 'star.dim_supplier' AS table_name, COUNT(*) AS cnt FROM star.dim_supplier;

