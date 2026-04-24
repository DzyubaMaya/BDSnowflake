CREATE SCHEMA IF NOT EXISTS star;

DROP TABLE IF EXISTS star.fact_sales CASCADE;
DROP TABLE IF EXISTS star.dim_date CASCADE;
DROP TABLE IF EXISTS star.dim_customer CASCADE;
DROP TABLE IF EXISTS star.dim_seller CASCADE;
DROP TABLE IF EXISTS star.dim_product CASCADE;
DROP TABLE IF EXISTS star.dim_store CASCADE;
DROP TABLE IF EXISTS star.dim_supplier CASCADE;

CREATE TABLE star.dim_date (
  date_key   INTEGER PRIMARY KEY,
  full_date  DATE UNIQUE,
  year       SMALLINT,
  quarter    SMALLINT,
  month      SMALLINT,
  day        SMALLINT
);

CREATE TABLE star.dim_customer (
  customer_id   INTEGER PRIMARY KEY,
  first_name    TEXT,
  last_name     TEXT,
  age           INTEGER,
  email         TEXT,
  country       TEXT,
  postal_code   TEXT,
  pet_type      TEXT,
  pet_name      TEXT,
  pet_breed     TEXT
);

CREATE TABLE star.dim_seller (
  seller_id     INTEGER PRIMARY KEY,
  first_name    TEXT,
  last_name     TEXT,
  email         TEXT,
  country       TEXT,
  postal_code   TEXT
);

CREATE TABLE star.dim_product (
  product_id     INTEGER PRIMARY KEY,
  product_name   TEXT,
  category       TEXT,
  brand          TEXT,
  material       TEXT,
  pet_category   TEXT,
  list_price     NUMERIC,
  weight         NUMERIC,
  color          TEXT,
  size           TEXT,
  description    TEXT,
  rating         NUMERIC,
  reviews        INTEGER,
  release_date   TEXT,
  expiry_date    TEXT
);

CREATE TABLE star.dim_store (
  store_id       INTEGER PRIMARY KEY,
  store_name     TEXT,
  store_location TEXT,
  store_city     TEXT,
  store_state    TEXT,
  store_country  TEXT,
  store_phone    TEXT,
  store_email    TEXT
);

CREATE TABLE star.dim_supplier (
  supplier_id      INTEGER PRIMARY KEY,
  supplier_name    TEXT,
  supplier_contact TEXT,
  supplier_email   TEXT,
  supplier_phone   TEXT,
  supplier_address TEXT,
  supplier_city    TEXT,
  supplier_country TEXT
);

CREATE TABLE star.fact_sales (
  sale_key       BIGINT PRIMARY KEY,
  source_row_id  BIGINT NOT NULL UNIQUE,
  date_key       INTEGER REFERENCES star.dim_date (date_key),
  customer_id    INTEGER REFERENCES star.dim_customer (customer_id),
  seller_id      INTEGER REFERENCES star.dim_seller (seller_id),
  product_id     INTEGER REFERENCES star.dim_product (product_id),
  store_id       INTEGER REFERENCES star.dim_store (store_id),
  supplier_id    INTEGER REFERENCES star.dim_supplier (supplier_id),
  quantity       NUMERIC,
  total_price    NUMERIC,
  unit_price     NUMERIC
);
