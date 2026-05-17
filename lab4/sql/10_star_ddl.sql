-- Lab4: create star-schema target in ClickHouse via Trino.
-- Keys in ORDER BY must be NOT NULL (ClickHouse MergeTree default).

CREATE SCHEMA IF NOT EXISTS clickhouse.star;

DROP TABLE IF EXISTS clickhouse.star.fact_sales;
DROP TABLE IF EXISTS clickhouse.star.dim_date;
DROP TABLE IF EXISTS clickhouse.star.dim_customer;
DROP TABLE IF EXISTS clickhouse.star.dim_seller;
DROP TABLE IF EXISTS clickhouse.star.dim_product;
DROP TABLE IF EXISTS clickhouse.star.dim_store;
DROP TABLE IF EXISTS clickhouse.star.dim_supplier;

CREATE TABLE clickhouse.star.dim_date (
  date_key   INTEGER NOT NULL,
  full_date  DATE,
  year       INTEGER,
  quarter    INTEGER,
  month      INTEGER,
  day        INTEGER
) WITH (engine = 'MergeTree', order_by = ARRAY['date_key']);

CREATE TABLE clickhouse.star.dim_customer (
  customer_id INTEGER NOT NULL,
  first_name  VARCHAR,
  last_name   VARCHAR,
  age         INTEGER,
  email       VARCHAR,
  country     VARCHAR,
  postal_code VARCHAR,
  pet_type    VARCHAR,
  pet_name    VARCHAR,
  pet_breed   VARCHAR
) WITH (engine = 'MergeTree', order_by = ARRAY['customer_id']);

CREATE TABLE clickhouse.star.dim_seller (
  seller_id   INTEGER NOT NULL,
  first_name  VARCHAR,
  last_name   VARCHAR,
  email       VARCHAR,
  country     VARCHAR,
  postal_code VARCHAR
) WITH (engine = 'MergeTree', order_by = ARRAY['seller_id']);

CREATE TABLE clickhouse.star.dim_product (
  product_id    INTEGER NOT NULL,
  product_name  VARCHAR,
  category      VARCHAR,
  brand         VARCHAR,
  material      VARCHAR,
  pet_category  VARCHAR,
  list_price    DOUBLE,
  weight        DOUBLE,
  color         VARCHAR,
  size          VARCHAR,
  description   VARCHAR,
  rating        DOUBLE,
  reviews       INTEGER,
  release_date  VARCHAR,
  expiry_date   VARCHAR
) WITH (engine = 'MergeTree', order_by = ARRAY['product_id']);

CREATE TABLE clickhouse.star.dim_store (
  store_id       INTEGER NOT NULL,
  store_name     VARCHAR,
  store_location VARCHAR,
  store_city     VARCHAR,
  store_state    VARCHAR,
  store_country  VARCHAR,
  store_phone    VARCHAR,
  store_email    VARCHAR
) WITH (engine = 'MergeTree', order_by = ARRAY['store_id']);

CREATE TABLE clickhouse.star.dim_supplier (
  supplier_id      INTEGER NOT NULL,
  supplier_name    VARCHAR,
  supplier_contact VARCHAR,
  supplier_email   VARCHAR,
  supplier_phone   VARCHAR,
  supplier_address VARCHAR,
  supplier_city    VARCHAR,
  supplier_country VARCHAR
) WITH (engine = 'MergeTree', order_by = ARRAY['supplier_id']);

CREATE TABLE clickhouse.star.fact_sales (
  sale_key      BIGINT NOT NULL,
  source_row_id VARCHAR,
  date_key      INTEGER,
  customer_id   INTEGER,
  seller_id     INTEGER,
  product_id    INTEGER,
  store_id      INTEGER,
  supplier_id   INTEGER,
  quantity      DOUBLE,
  unit_price    DOUBLE,
  total_price   DOUBLE
) WITH (engine = 'MergeTree', order_by = ARRAY['sale_key']);
