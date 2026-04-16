-- "N/A" — заглушка для пустых значений, чтобы не получать NULL в ключах
INSERT INTO dim_country (country_name)
VALUES ('N/A')
;

INSERT INTO dim_product_category (category_name)
VALUES ('N/A')
;

INSERT INTO dim_product_brand (brand_name)
VALUES ('N/A')
;

-- Страны 
INSERT INTO dim_country (country_name)
SELECT DISTINCT trim(c)
FROM (
  SELECT customer_country AS c FROM mock_data
  UNION ALL
  SELECT store_country FROM mock_data
  UNION ALL
  SELECT supplier_country FROM mock_data
) u
WHERE c IS NOT NULL
  AND trim(c) <> ''
;

-- Категории и бренды
INSERT INTO dim_product_category (category_name)
SELECT DISTINCT trim(product_category)
FROM mock_data
WHERE product_category IS NOT NULL
  AND trim(product_category) <> ''
;

INSERT INTO dim_product_brand (brand_name)
SELECT DISTINCT trim(product_brand)
FROM mock_data
WHERE product_brand IS NOT NULL
  AND trim(product_brand) <> ''
;

-- Календарь по фактическим датам продаж
INSERT INTO dim_date (date_key, full_date, year, quarter, month, day)
SELECT DISTINCT
  to_char(fd, 'YYYYMMDD')::integer,
  fd,
  EXTRACT(YEAR FROM fd)::smallint,
  EXTRACT(QUARTER FROM fd)::smallint,
  EXTRACT(MONTH FROM fd)::smallint,
  EXTRACT(DAY FROM fd)::smallint
FROM (
  SELECT
    -- Исходный формат в CSV: M/D/YYYY или MM/DD/YYYY
    to_date(trim(sale_date), 'FMMM/FMDD/YYYY') AS fd
  FROM mock_data
  WHERE sale_date ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
) d
WHERE fd IS NOT NULL
;

-- Клиенты, продавцы, магазины, поставщики, товары
INSERT INTO dim_customer (
  sale_customer_id, first_name, last_name, age, email, postal_code,
  pet_type, pet_name, pet_breed, country_key
)
SELECT
  t.sale_customer_id::integer,
  t.customer_first_name,
  t.customer_last_name,
  NULLIF(trim(t.customer_age), '')::integer,
  t.customer_email,
  t.customer_postal_code,
  t.customer_pet_type,
  t.customer_pet_name,
  t.customer_pet_breed,
  c.country_key
FROM (
  SELECT
    m.*,
    CASE
      WHEN m.customer_country IS NULL OR trim(m.customer_country) = '' THEN 'N/A'
      ELSE trim(m.customer_country)
    END AS customer_country_norm,
    ROW_NUMBER() OVER (
      PARTITION BY m.sale_customer_id::integer
      ORDER BY m.row_id
    ) AS rn
  FROM mock_data m
  WHERE m.sale_customer_id IS NOT NULL
) t
JOIN dim_country c
  ON c.country_name = t.customer_country_norm
WHERE t.rn = 1;

INSERT INTO dim_seller (
  sale_seller_id, first_name, last_name, email, postal_code, country_key
)
SELECT
  t.sale_seller_id::integer,
  t.seller_first_name,
  t.seller_last_name,
  t.seller_email,
  t.seller_postal_code,
  c.country_key
FROM (
  SELECT
    m.*,
    CASE
      WHEN m.seller_country IS NULL OR trim(m.seller_country) = '' THEN 'N/A'
      ELSE trim(m.seller_country)
    END AS seller_country_norm,
    ROW_NUMBER() OVER (
      PARTITION BY m.sale_seller_id::integer
      ORDER BY m.row_id
    ) AS rn
  FROM mock_data m
  WHERE m.sale_seller_id IS NOT NULL
) t
JOIN dim_country c
  ON c.country_name = t.seller_country_norm
WHERE t.rn = 1;

INSERT INTO dim_store (
  store_name, store_location, store_city, store_state, phone, email, country_key
)
SELECT
  t.store_name,
  t.store_location,
  t.store_city,
  t.store_state,
  t.store_phone,
  t.store_email,
  c.country_key
FROM (
  SELECT
    m.*,
    ROW_NUMBER() OVER (
      PARTITION BY
        m.store_name,
        m.store_phone,
        m.store_city,
        CASE
          WHEN m.store_country IS NULL OR trim(m.store_country) = '' THEN 'N/A'
          ELSE trim(m.store_country)
        END
      ORDER BY m.row_id
    ) AS rn
  FROM mock_data m
) t
JOIN dim_country c
  ON c.country_name = CASE
    WHEN t.store_country IS NULL OR trim(t.store_country) = '' THEN 'N/A'
    ELSE trim(t.store_country)
  END
WHERE t.rn = 1;

INSERT INTO dim_supplier (
  supplier_name, contact, email, phone, address, city, country_key
)
SELECT
  t.supplier_name,
  t.supplier_contact,
  t.supplier_email,
  t.supplier_phone,
  t.supplier_address,
  t.supplier_city,
  c.country_key
FROM (
  SELECT
    m.*,
    ROW_NUMBER() OVER (
      PARTITION BY
        m.supplier_name,
        m.supplier_email,
        m.supplier_phone,
        CASE
          WHEN m.supplier_country IS NULL OR trim(m.supplier_country) = '' THEN 'N/A'
          ELSE trim(m.supplier_country)
        END
      ORDER BY m.row_id
    ) AS rn
  FROM mock_data m
) t
JOIN dim_country c
  ON c.country_name = CASE
    WHEN t.supplier_country IS NULL OR trim(t.supplier_country) = '' THEN 'N/A'
    ELSE trim(t.supplier_country)
  END
WHERE t.rn = 1;

INSERT INTO dim_product (
  sale_product_id, product_name, category_key, brand_key, pet_category,
  weight, color, size, material, description, rating, reviews,
  release_date, expiry_date, list_price
)
SELECT
  t.sale_product_id::integer,
  t.product_name,
  cat.category_key,
  br.brand_key,
  t.pet_category,
  NULLIF(trim(t.product_weight), '')::numeric,
  t.product_color,
  t.product_size,
  t.product_material,
  t.product_description,
  NULLIF(trim(t.product_rating), '')::numeric,
  NULLIF(trim(t.product_reviews), '')::integer,
  t.product_release_date,
  t.product_expiry_date,
  NULLIF(trim(t.product_price), '')::numeric
FROM (
  SELECT
    m.*,
    CASE
      WHEN m.product_category IS NULL OR trim(m.product_category) = '' THEN 'N/A'
      ELSE trim(m.product_category)
    END AS product_category_norm,
    CASE
      WHEN m.product_brand IS NULL OR trim(m.product_brand) = '' THEN 'N/A'
      ELSE trim(m.product_brand)
    END AS product_brand_norm,
    ROW_NUMBER() OVER (
      PARTITION BY m.sale_product_id::integer
      ORDER BY m.row_id
    ) AS rn
  FROM mock_data m
  WHERE m.sale_product_id IS NOT NULL
) t
JOIN dim_product_category cat
  ON cat.category_name = t.product_category_norm
JOIN dim_product_brand br
  ON br.brand_name = t.product_brand_norm
WHERE t.rn = 1;

-- Факт продаж
INSERT INTO fact_sales (
  source_row_id, date_key, customer_key, seller_key, product_key,
  store_key, supplier_key, quantity, total_price, unit_price
)
SELECT
  m.row_id,
  dd.date_key,
  cust.customer_key,
  sel.seller_key,
  pr.product_key,
  sto.store_key,
  sup.supplier_key,
  NULLIF(trim(m.sale_quantity), '')::numeric,
  NULLIF(trim(m.sale_total_price), '')::numeric,
  NULLIF(trim(m.product_price), '')::numeric
FROM mock_data m
JOIN dim_customer cust ON cust.sale_customer_id = m.sale_customer_id::integer
JOIN dim_seller sel ON sel.sale_seller_id = m.sale_seller_id::integer
JOIN dim_product pr ON pr.sale_product_id = m.sale_product_id::integer
JOIN dim_country cstor ON cstor.country_name = CASE
  WHEN m.store_country IS NULL OR trim(m.store_country) = '' THEN 'N/A'
  ELSE trim(m.store_country)
END
JOIN dim_country csupp ON csupp.country_name = CASE
  WHEN m.supplier_country IS NULL OR trim(m.supplier_country) = '' THEN 'N/A'
  ELSE trim(m.supplier_country)
END
JOIN dim_store sto
  ON sto.store_name = m.store_name
 AND sto.phone IS NOT DISTINCT FROM m.store_phone
 AND sto.store_city IS NOT DISTINCT FROM m.store_city
 AND sto.country_key = cstor.country_key
JOIN dim_supplier sup
  ON sup.supplier_name IS NOT DISTINCT FROM m.supplier_name
 AND sup.email IS NOT DISTINCT FROM m.supplier_email
 AND sup.phone IS NOT DISTINCT FROM m.supplier_phone
 AND sup.country_key = csupp.country_key
LEFT JOIN dim_date dd
  ON dd.full_date = CASE
    WHEN m.sale_date ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN
      to_date(trim(m.sale_date), 'FMMM/FMDD/YYYY')
    ELSE NULL
  END;
