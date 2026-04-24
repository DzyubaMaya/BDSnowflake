--   docker-compose exec -T clickhouse clickhouse-client -q "$(cat sql/lab2/04_clickhouse_checks.sql)"

-- 1) Количество строк в каждой таблице отчёта (должно быть > 0)
SELECT 'report_products'  AS t, count() AS c FROM reports.report_products
UNION ALL SELECT 'report_customers',  count() FROM reports.report_customers
UNION ALL SELECT 'report_time',       count() FROM reports.report_time
UNION ALL SELECT 'report_stores',     count() FROM reports.report_stores
UNION ALL SELECT 'report_suppliers',  count() FROM reports.report_suppliers
UNION ALL SELECT 'report_quality',    count() FROM reports.report_quality
FORMAT Pretty;

-- 2) Пример: топ-10 продуктов по выручке
SELECT product_id, product_name, total_revenue, sales_rank
FROM reports.report_products
ORDER BY sales_rank ASC
LIMIT 10
FORMAT Pretty;

-- 3) Проверка рангов: минимальный ранг = 1
SELECT min(sales_rank)    AS min_sales_rank    FROM reports.report_products;
SELECT min(customer_rank) AS min_customer_rank FROM reports.report_customers;
SELECT min(store_rank)    AS min_store_rank    FROM reports.report_stores;
SELECT min(supplier_rank) AS min_supplier_rank FROM reports.report_suppliers;
SELECT min(rating_rank_desc) AS min_rating_rank_desc FROM reports.report_quality;

