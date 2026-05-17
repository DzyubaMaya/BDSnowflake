-- Lab4: quick sanity checks runnable in Trino.

SELECT 'pg_mock_data'    AS what, COUNT(*) AS rows FROM postgresql.public.mock_data
UNION ALL
SELECT 'ch_mock_data'    AS what, COUNT(*) AS rows FROM clickhouse.staging.mock_data
UNION ALL
SELECT 'dim_date'        AS what, COUNT(*) FROM clickhouse.star.dim_date
UNION ALL
SELECT 'dim_customer'    AS what, COUNT(*) FROM clickhouse.star.dim_customer
UNION ALL
SELECT 'dim_seller'      AS what, COUNT(*) FROM clickhouse.star.dim_seller
UNION ALL
SELECT 'dim_product'     AS what, COUNT(*) FROM clickhouse.star.dim_product
UNION ALL
SELECT 'dim_store'       AS what, COUNT(*) FROM clickhouse.star.dim_store
UNION ALL
SELECT 'dim_supplier'    AS what, COUNT(*) FROM clickhouse.star.dim_supplier
UNION ALL
SELECT 'fact_sales'      AS what, COUNT(*) FROM clickhouse.star.fact_sales
UNION ALL
SELECT 'report_products'              , COUNT(*) FROM clickhouse.reports.report_products
UNION ALL
SELECT 'report_products_by_category'  , COUNT(*) FROM clickhouse.reports.report_products_by_category
UNION ALL
SELECT 'report_customers'             , COUNT(*) FROM clickhouse.reports.report_customers
UNION ALL
SELECT 'report_customers_by_country'  , COUNT(*) FROM clickhouse.reports.report_customers_by_country
UNION ALL
SELECT 'report_time'                  , COUNT(*) FROM clickhouse.reports.report_time
UNION ALL
SELECT 'report_time_year'             , COUNT(*) FROM clickhouse.reports.report_time_year
UNION ALL
SELECT 'report_time_period_compare'   , COUNT(*) FROM clickhouse.reports.report_time_period_compare
UNION ALL
SELECT 'report_stores'                , COUNT(*) FROM clickhouse.reports.report_stores
UNION ALL
SELECT 'report_stores_by_geo'         , COUNT(*) FROM clickhouse.reports.report_stores_by_geo
UNION ALL
SELECT 'report_suppliers'             , COUNT(*) FROM clickhouse.reports.report_suppliers
UNION ALL
SELECT 'report_suppliers_by_country'  , COUNT(*) FROM clickhouse.reports.report_suppliers_by_country
UNION ALL
SELECT 'report_quality'               , COUNT(*) FROM clickhouse.reports.report_quality
UNION ALL
SELECT 'report_quality_correlation'   , COUNT(*) FROM clickhouse.reports.report_quality_correlation
ORDER BY what;
