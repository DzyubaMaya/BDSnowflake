SELECT 'mock_data' AS tbl, COUNT(*) AS n FROM mock_data
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_seller', COUNT(*) FROM dim_seller
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL
SELECT 'dim_supplier', COUNT(*) FROM dim_supplier
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL
SELECT 'dim_country', COUNT(*) FROM dim_country;

SELECT
  round((SELECT sum(sale_total_price::numeric) FROM mock_data)::numeric, 2) AS sum_total_staging,
  round((SELECT sum(total_price) FROM fact_sales)::numeric, 2)       AS sum_total_fact;

SELECT COUNT(*) AS fact_rows_missing_date FROM fact_sales WHERE date_key IS NULL;
