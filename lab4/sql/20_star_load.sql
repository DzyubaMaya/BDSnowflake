-- Lab4: ETL via Trino. Union staging from postgresql + clickhouse, then
-- materialize dimensions and the fact table in clickhouse.star.

-- ------------------------------------------------------------------
-- step 1: materialize a unified staging table in ClickHouse so the
-- heavy network read from PostgreSQL is only done once.
-- ------------------------------------------------------------------
DROP TABLE IF EXISTS clickhouse.star.stg_unioned;

CREATE TABLE clickhouse.star.stg_unioned (
  src                  VARCHAR NOT NULL,
  row_id_raw           BIGINT NOT NULL,
  row_id_global        BIGINT NOT NULL,
  id                   INTEGER,
  customer_first_name  VARCHAR,
  customer_last_name   VARCHAR,
  customer_age         VARCHAR,
  customer_email       VARCHAR,
  customer_country     VARCHAR,
  customer_postal_code VARCHAR,
  customer_pet_type    VARCHAR,
  customer_pet_name    VARCHAR,
  customer_pet_breed   VARCHAR,
  seller_first_name    VARCHAR,
  seller_last_name     VARCHAR,
  seller_email         VARCHAR,
  seller_country       VARCHAR,
  seller_postal_code   VARCHAR,
  product_name         VARCHAR,
  product_category     VARCHAR,
  product_price        VARCHAR,
  product_quantity     VARCHAR,
  sale_date            VARCHAR,
  sale_customer_id     INTEGER,
  sale_seller_id       INTEGER,
  sale_product_id      INTEGER,
  sale_quantity        VARCHAR,
  sale_total_price     VARCHAR,
  store_name           VARCHAR,
  store_location       VARCHAR,
  store_city           VARCHAR,
  store_state          VARCHAR,
  store_country        VARCHAR,
  store_phone          VARCHAR,
  store_email          VARCHAR,
  pet_category         VARCHAR,
  product_weight       VARCHAR,
  product_color        VARCHAR,
  product_size         VARCHAR,
  product_brand        VARCHAR,
  product_material     VARCHAR,
  product_description  VARCHAR,
  product_rating       VARCHAR,
  product_reviews      VARCHAR,
  product_release_date VARCHAR,
  product_expiry_date  VARCHAR,
  supplier_name        VARCHAR,
  supplier_contact     VARCHAR,
  supplier_email       VARCHAR,
  supplier_phone       VARCHAR,
  supplier_address     VARCHAR,
  supplier_city        VARCHAR,
  supplier_country     VARCHAR
) WITH (engine = 'MergeTree', order_by = ARRAY['row_id_global']);

INSERT INTO clickhouse.star.stg_unioned
SELECT
  CAST('pg' AS VARCHAR),
  CAST(row_id AS BIGINT),
  CAST(row_id AS BIGINT),
  id,
  customer_first_name, customer_last_name, customer_age, customer_email,
  customer_country, customer_postal_code, customer_pet_type, customer_pet_name, customer_pet_breed,
  seller_first_name, seller_last_name, seller_email, seller_country, seller_postal_code,
  product_name, product_category, product_price, product_quantity, sale_date,
  sale_customer_id, sale_seller_id, sale_product_id, sale_quantity, sale_total_price,
  store_name, store_location, store_city, store_state, store_country, store_phone, store_email,
  pet_category, product_weight, product_color, product_size, product_brand, product_material,
  product_description, product_rating, product_reviews, product_release_date, product_expiry_date,
  supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address,
  supplier_city, supplier_country
FROM postgresql.public.mock_data
UNION ALL
SELECT
  CAST('ch' AS VARCHAR),
  CAST(row_id AS BIGINT),
  CAST(row_id AS BIGINT) + 1000000,
  id,
  customer_first_name, customer_last_name, customer_age, customer_email,
  customer_country, customer_postal_code, customer_pet_type, customer_pet_name, customer_pet_breed,
  seller_first_name, seller_last_name, seller_email, seller_country, seller_postal_code,
  product_name, product_category, product_price, product_quantity, sale_date,
  sale_customer_id, sale_seller_id, sale_product_id, sale_quantity, sale_total_price,
  store_name, store_location, store_city, store_state, store_country, store_phone, store_email,
  pet_category, product_weight, product_color, product_size, product_brand, product_material,
  product_description, product_rating, product_reviews, product_release_date, product_expiry_date,
  supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address,
  supplier_city, supplier_country
FROM clickhouse.staging.mock_data;

-- ------------------------------------------------------------------
-- dim_date
-- ------------------------------------------------------------------
INSERT INTO clickhouse.star.dim_date
SELECT
  CAST(year(d) * 10000 + month(d) * 100 + day(d) AS INTEGER) AS date_key,
  d AS full_date,
  CAST(year(d)    AS INTEGER) AS year,
  CAST(quarter(d) AS INTEGER) AS quarter,
  CAST(month(d)   AS INTEGER) AS month,
  CAST(day(d)     AS INTEGER) AS day
FROM (
  SELECT DISTINCT
    date_parse(sale_date, '%c/%e/%Y') AS d
  FROM clickhouse.star.stg_unioned
  WHERE sale_date IS NOT NULL AND sale_date <> ''
);

-- ------------------------------------------------------------------
-- dim_customer
-- ------------------------------------------------------------------
INSERT INTO clickhouse.star.dim_customer
SELECT
  CAST(sale_customer_id AS INTEGER) AS customer_id,
  customer_first_name,
  customer_last_name,
  TRY_CAST(NULLIF(TRIM(customer_age), '') AS INTEGER) AS age,
  customer_email,
  customer_country,
  customer_postal_code,
  customer_pet_type,
  customer_pet_name,
  customer_pet_breed
FROM (
  SELECT
    sale_customer_id,
    customer_first_name, customer_last_name, customer_age, customer_email,
    customer_country, customer_postal_code, customer_pet_type, customer_pet_name, customer_pet_breed,
    ROW_NUMBER() OVER (PARTITION BY sale_customer_id ORDER BY row_id_global) AS rn
  FROM clickhouse.star.stg_unioned
  WHERE sale_customer_id IS NOT NULL
)
WHERE rn = 1;

-- ------------------------------------------------------------------
-- dim_seller
-- ------------------------------------------------------------------
INSERT INTO clickhouse.star.dim_seller
SELECT
  CAST(sale_seller_id AS INTEGER) AS seller_id,
  seller_first_name,
  seller_last_name,
  seller_email,
  seller_country,
  seller_postal_code
FROM (
  SELECT
    sale_seller_id,
    seller_first_name, seller_last_name, seller_email, seller_country, seller_postal_code,
    ROW_NUMBER() OVER (PARTITION BY sale_seller_id ORDER BY row_id_global) AS rn
  FROM clickhouse.star.stg_unioned
  WHERE sale_seller_id IS NOT NULL
)
WHERE rn = 1;

-- ------------------------------------------------------------------
-- dim_product
-- ------------------------------------------------------------------
INSERT INTO clickhouse.star.dim_product
SELECT
  CAST(sale_product_id AS INTEGER) AS product_id,
  product_name,
  product_category,
  product_brand,
  product_material,
  pet_category,
  TRY_CAST(NULLIF(TRIM(product_price),  '') AS DOUBLE) AS list_price,
  TRY_CAST(NULLIF(TRIM(product_weight), '') AS DOUBLE) AS weight,
  product_color,
  product_size,
  product_description,
  TRY_CAST(NULLIF(TRIM(product_rating),  '') AS DOUBLE)  AS rating,
  TRY_CAST(NULLIF(TRIM(product_reviews), '') AS INTEGER) AS reviews,
  product_release_date,
  product_expiry_date
FROM (
  SELECT
    sale_product_id, product_name, product_category, product_brand, product_material,
    pet_category, product_price, product_weight, product_color, product_size,
    product_description, product_rating, product_reviews,
    product_release_date, product_expiry_date,
    ROW_NUMBER() OVER (PARTITION BY sale_product_id ORDER BY row_id_global) AS rn
  FROM clickhouse.star.stg_unioned
  WHERE sale_product_id IS NOT NULL
)
WHERE rn = 1;

-- ------------------------------------------------------------------
-- dim_store  (synthetic key)
-- ------------------------------------------------------------------
INSERT INTO clickhouse.star.dim_store
SELECT
  CAST(ROW_NUMBER() OVER (ORDER BY store_name, store_location, store_city,
                                  store_state, store_country, store_phone, store_email)
       AS INTEGER) AS store_id,
  store_name, store_location, store_city, store_state,
  store_country, store_phone, store_email
FROM (
  SELECT DISTINCT
    COALESCE(store_name,     'N/A') AS store_name,
    COALESCE(store_location, 'N/A') AS store_location,
    COALESCE(store_city,     'N/A') AS store_city,
    COALESCE(store_state,    'N/A') AS store_state,
    COALESCE(store_country,  'N/A') AS store_country,
    COALESCE(store_phone,    'N/A') AS store_phone,
    COALESCE(store_email,    'N/A') AS store_email
  FROM clickhouse.star.stg_unioned
);

-- ------------------------------------------------------------------
-- dim_supplier  (synthetic key)
-- ------------------------------------------------------------------
INSERT INTO clickhouse.star.dim_supplier
SELECT
  CAST(ROW_NUMBER() OVER (ORDER BY supplier_name, supplier_contact, supplier_email,
                                  supplier_phone, supplier_address, supplier_city, supplier_country)
       AS INTEGER) AS supplier_id,
  supplier_name, supplier_contact, supplier_email, supplier_phone,
  supplier_address, supplier_city, supplier_country
FROM (
  SELECT DISTINCT
    COALESCE(supplier_name,    'N/A') AS supplier_name,
    COALESCE(supplier_contact, 'N/A') AS supplier_contact,
    COALESCE(supplier_email,   'N/A') AS supplier_email,
    COALESCE(supplier_phone,   'N/A') AS supplier_phone,
    COALESCE(supplier_address, 'N/A') AS supplier_address,
    COALESCE(supplier_city,    'N/A') AS supplier_city,
    COALESCE(supplier_country, 'N/A') AS supplier_country
  FROM clickhouse.star.stg_unioned
);

-- ------------------------------------------------------------------
-- fact_sales
-- ------------------------------------------------------------------
INSERT INTO clickhouse.star.fact_sales
SELECT
  CAST(ROW_NUMBER() OVER (ORDER BY u.src, u.row_id_raw) AS BIGINT) AS sale_key,
  u.src || ':' || CAST(u.row_id_raw AS VARCHAR) AS source_row_id,
  d.date_key,
  CAST(u.sale_customer_id AS INTEGER) AS customer_id,
  CAST(u.sale_seller_id   AS INTEGER) AS seller_id,
  CAST(u.sale_product_id  AS INTEGER) AS product_id,
  ds.store_id,
  dsu.supplier_id,
  TRY_CAST(NULLIF(TRIM(u.sale_quantity),    '') AS DOUBLE) AS quantity,
  TRY_CAST(NULLIF(TRIM(u.product_price),    '') AS DOUBLE) AS unit_price,
  TRY_CAST(NULLIF(TRIM(u.sale_total_price), '') AS DOUBLE) AS total_price
FROM clickhouse.star.stg_unioned u
LEFT JOIN clickhouse.star.dim_date d
  ON d.full_date = date_parse(u.sale_date, '%c/%e/%Y')
LEFT JOIN clickhouse.star.dim_store ds
  ON ds.store_name     = COALESCE(u.store_name,     'N/A')
 AND ds.store_location = COALESCE(u.store_location, 'N/A')
 AND ds.store_city     = COALESCE(u.store_city,     'N/A')
 AND ds.store_state    = COALESCE(u.store_state,    'N/A')
 AND ds.store_country  = COALESCE(u.store_country,  'N/A')
 AND ds.store_phone    = COALESCE(u.store_phone,    'N/A')
 AND ds.store_email    = COALESCE(u.store_email,    'N/A')
LEFT JOIN clickhouse.star.dim_supplier dsu
  ON dsu.supplier_name    = COALESCE(u.supplier_name,    'N/A')
 AND dsu.supplier_contact = COALESCE(u.supplier_contact, 'N/A')
 AND dsu.supplier_email   = COALESCE(u.supplier_email,   'N/A')
 AND dsu.supplier_phone   = COALESCE(u.supplier_phone,   'N/A')
 AND dsu.supplier_address = COALESCE(u.supplier_address, 'N/A')
 AND dsu.supplier_city    = COALESCE(u.supplier_city,    'N/A')
 AND dsu.supplier_country = COALESCE(u.supplier_country, 'N/A');

DROP TABLE IF EXISTS clickhouse.star.stg_unioned;
