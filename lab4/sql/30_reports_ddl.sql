-- Lab4: datamarts in ClickHouse (6 тем задания; часть тем — основная таблица + срез).
-- Дополнительно: годовые агрегаты, сравнение с предыдущим месяцем, корреляция рейтинг–продажи.

CREATE SCHEMA IF NOT EXISTS clickhouse.reports;

DROP TABLE IF EXISTS clickhouse.reports.report_products;
DROP TABLE IF EXISTS clickhouse.reports.report_products_by_category;
DROP TABLE IF EXISTS clickhouse.reports.report_customers;
DROP TABLE IF EXISTS clickhouse.reports.report_customers_by_country;
DROP TABLE IF EXISTS clickhouse.reports.report_time;
DROP TABLE IF EXISTS clickhouse.reports.report_time_year;
DROP TABLE IF EXISTS clickhouse.reports.report_time_period_compare;
DROP TABLE IF EXISTS clickhouse.reports.report_stores;
DROP TABLE IF EXISTS clickhouse.reports.report_stores_by_geo;
DROP TABLE IF EXISTS clickhouse.reports.report_suppliers;
DROP TABLE IF EXISTS clickhouse.reports.report_suppliers_by_country;
DROP TABLE IF EXISTS clickhouse.reports.report_quality;
DROP TABLE IF EXISTS clickhouse.reports.report_quality_correlation;

CREATE TABLE clickhouse.reports.report_products (
  product_id           INTEGER NOT NULL,
  product_name         VARCHAR,
  category             VARCHAR,
  brand                VARCHAR,
  total_orders         BIGINT,
  total_qty            DOUBLE,
  total_revenue        DOUBLE,
  avg_unit_price       DOUBLE,
  catalog_rating       DOUBLE,
  catalog_reviews      INTEGER,
  sales_rank           INTEGER NOT NULL,
  sales_rank_by_qty    INTEGER NOT NULL
) WITH (engine = 'MergeTree', order_by = ARRAY['sales_rank', 'product_id']);

CREATE TABLE clickhouse.reports.report_products_by_category (
  category       VARCHAR NOT NULL,
  total_orders   BIGINT,
  total_qty      DOUBLE,
  total_revenue  DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['category']);

CREATE TABLE clickhouse.reports.report_customers (
  customer_id   INTEGER NOT NULL,
  first_name    VARCHAR,
  last_name     VARCHAR,
  country       VARCHAR,
  total_orders  BIGINT,
  total_qty     DOUBLE,
  total_spent   DOUBLE,
  avg_check     DOUBLE,
  customer_rank INTEGER NOT NULL
) WITH (engine = 'MergeTree', order_by = ARRAY['customer_rank', 'customer_id']);

CREATE TABLE clickhouse.reports.report_customers_by_country (
  country         VARCHAR NOT NULL,
  customers_cnt   BIGINT,
  total_orders    BIGINT,
  total_revenue   DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['country']);

CREATE TABLE clickhouse.reports.report_time (
  year             INTEGER NOT NULL,
  month            INTEGER NOT NULL,
  total_orders     BIGINT,
  total_qty        DOUBLE,
  total_revenue    DOUBLE,
  avg_order_value  DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['year', 'month']);

CREATE TABLE clickhouse.reports.report_time_year (
  year             INTEGER NOT NULL,
  total_orders     BIGINT,
  total_qty        DOUBLE,
  total_revenue    DOUBLE,
  avg_order_value  DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['year']);

CREATE TABLE clickhouse.reports.report_time_period_compare (
  year                   INTEGER NOT NULL,
  month                  INTEGER NOT NULL,
  revenue_current        DOUBLE,
  revenue_prior_month    DOUBLE,
  pct_change_vs_prior    DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['year', 'month']);

CREATE TABLE clickhouse.reports.report_stores (
  store_id       INTEGER NOT NULL,
  store_name     VARCHAR,
  store_city     VARCHAR,
  store_country  VARCHAR,
  total_orders   BIGINT,
  total_qty      DOUBLE,
  total_revenue  DOUBLE,
  avg_check      DOUBLE,
  store_rank     INTEGER NOT NULL
) WITH (engine = 'MergeTree', order_by = ARRAY['store_rank', 'store_id']);

CREATE TABLE clickhouse.reports.report_stores_by_geo (
  store_country  VARCHAR NOT NULL,
  store_city     VARCHAR NOT NULL,
  total_orders   BIGINT,
  total_revenue  DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['store_country', 'store_city']);

CREATE TABLE clickhouse.reports.report_suppliers (
  supplier_id       INTEGER NOT NULL,
  supplier_name     VARCHAR,
  supplier_country  VARCHAR,
  total_orders      BIGINT,
  total_qty         DOUBLE,
  total_revenue     DOUBLE,
  avg_unit_price    DOUBLE,
  avg_list_price    DOUBLE,
  supplier_rank     INTEGER NOT NULL
) WITH (engine = 'MergeTree', order_by = ARRAY['supplier_rank', 'supplier_id']);

CREATE TABLE clickhouse.reports.report_suppliers_by_country (
  supplier_country VARCHAR NOT NULL,
  suppliers_cnt    BIGINT,
  total_orders     BIGINT,
  total_revenue    DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['supplier_country']);

CREATE TABLE clickhouse.reports.report_quality (
  product_id       INTEGER NOT NULL,
  product_name     VARCHAR,
  rating           DOUBLE,
  reviews          INTEGER,
  total_qty        DOUBLE,
  total_revenue    DOUBLE,
  rating_rank_desc INTEGER,
  rating_rank_asc  INTEGER,
  reviews_rank     INTEGER
) WITH (engine = 'MergeTree', order_by = ARRAY['product_id']);

CREATE TABLE clickhouse.reports.report_quality_correlation (
  id                         INTEGER NOT NULL,
  corr_rating_total_qty      DOUBLE,
  corr_rating_total_revenue  DOUBLE,
  n_products                 BIGINT
) WITH (engine = 'MergeTree', order_by = ARRAY['id']);
