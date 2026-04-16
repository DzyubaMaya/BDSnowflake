CREATE TABLE dim_country (
  country_key SERIAL PRIMARY KEY,
  country_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dim_date (
  date_key   INTEGER PRIMARY KEY,
  full_date  DATE NOT NULL UNIQUE,
  year       SMALLINT NOT NULL,
  quarter    SMALLINT NOT NULL,
  month      SMALLINT NOT NULL,
  day        SMALLINT NOT NULL
);

CREATE TABLE dim_product_category (
  category_key SERIAL PRIMARY KEY,
  category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dim_product_brand (
  brand_key SERIAL PRIMARY KEY,
  brand_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dim_customer (
  customer_key     SERIAL PRIMARY KEY,
  sale_customer_id INTEGER NOT NULL UNIQUE,
  first_name       TEXT,
  last_name        TEXT,
  age              INTEGER,
  email            TEXT,
  postal_code      TEXT,
  pet_type         TEXT,
  pet_name         TEXT,
  pet_breed        TEXT,
  country_key      INTEGER NOT NULL REFERENCES dim_country (country_key)
);

CREATE TABLE dim_seller (
  seller_key     SERIAL PRIMARY KEY,
  sale_seller_id INTEGER NOT NULL UNIQUE,
  first_name     TEXT,
  last_name      TEXT,
  email          TEXT,
  postal_code    TEXT,
  country_key    INTEGER NOT NULL REFERENCES dim_country (country_key)
);

CREATE TABLE dim_store (
  store_key       SERIAL PRIMARY KEY,
  store_name      TEXT NOT NULL,
  store_location  TEXT,
  store_city      TEXT,
  store_state     TEXT,
  phone           TEXT,
  email           TEXT,
  country_key     INTEGER NOT NULL REFERENCES dim_country (country_key)
);

CREATE INDEX idx_dim_store_lookup ON dim_store (store_name, phone, store_city, country_key);

CREATE TABLE dim_supplier (
  supplier_key   SERIAL PRIMARY KEY,
  supplier_name  TEXT,
  contact        TEXT,
  email          TEXT,
  phone          TEXT,
  address        TEXT,
  city           TEXT,
  country_key    INTEGER NOT NULL REFERENCES dim_country (country_key)
);

CREATE INDEX idx_dim_supplier_lookup ON dim_supplier (supplier_name, email, phone);

CREATE TABLE dim_product (
  product_key      SERIAL PRIMARY KEY,
  sale_product_id  INTEGER NOT NULL UNIQUE,
  product_name     TEXT,
  category_key     INTEGER NOT NULL REFERENCES dim_product_category (category_key),
  brand_key        INTEGER NOT NULL REFERENCES dim_product_brand (brand_key),
  pet_category     TEXT,
  weight           NUMERIC,
  color            TEXT,
  size             TEXT,
  material         TEXT,
  description      TEXT,
  rating           NUMERIC,
  reviews          INTEGER,
  release_date     TEXT,
  expiry_date      TEXT,
  list_price       NUMERIC
);
