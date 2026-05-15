CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key TEXT PRIMARY KEY,
    customer_source_id BIGINT,
    customer_first_name TEXT,
    customer_last_name TEXT,
    customer_age INTEGER,
    customer_email TEXT,
    customer_country TEXT,
    customer_postal_code TEXT
);


CREATE TABLE IF NOT EXISTS dim_pet_type (
    pet_type_key TEXT PRIMARY KEY,
    pet_type_name TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS dim_pet_breed (
    pet_breed_key TEXT PRIMARY KEY,
    pet_breed_name TEXT NOT NULL,
    pet_category TEXT
);


CREATE TABLE IF NOT EXISTS dim_pet (
    pet_key TEXT PRIMARY KEY,
    customer_key TEXT,
    pet_type_key TEXT,
    pet_breed_key TEXT,
    pet_name TEXT
);


CREATE TABLE IF NOT EXISTS dim_seller (
    seller_key TEXT PRIMARY KEY,
    seller_source_id BIGINT,
    seller_first_name TEXT,
    seller_last_name TEXT,
    seller_email TEXT,
    seller_country TEXT,
    seller_postal_code TEXT
);


CREATE TABLE IF NOT EXISTS dim_category (
    category_key TEXT PRIMARY KEY,
    category_name TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS dim_brand (
    brand_key TEXT PRIMARY KEY,
    brand_name TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS dim_product (
    product_key TEXT PRIMARY KEY,
    product_source_id BIGINT,
    product_name TEXT,
    category_key TEXT,
    brand_key TEXT,
    product_price NUMERIC(12, 2),
    product_quantity INTEGER,
    product_weight NUMERIC(12, 2),
    product_color TEXT,
    product_size TEXT,
    product_material TEXT,
    product_description TEXT,
    product_rating NUMERIC(4, 2),
    product_reviews INTEGER,
    product_release_date DATE,
    product_expiry_date DATE
);


CREATE TABLE IF NOT EXISTS dim_location (
    location_key TEXT PRIMARY KEY,
    location_name TEXT,
    location_city TEXT,
    location_state TEXT,
    location_country TEXT
);


CREATE TABLE IF NOT EXISTS dim_store (
    store_key TEXT PRIMARY KEY,
    store_name TEXT,
    location_key TEXT,
    store_phone TEXT,
    store_email TEXT
);


CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_key TEXT PRIMARY KEY,
    supplier_name TEXT,
    supplier_contact TEXT,
    supplier_email TEXT,
    supplier_phone TEXT,
    supplier_address TEXT,
    supplier_city TEXT,
    supplier_country TEXT
);


CREATE TABLE IF NOT EXISTS fact_sales (
    sale_key TEXT PRIMARY KEY,
    source_file TEXT,
    sale_source_row_id BIGINT,
    sale_date DATE,
    sale_customer_id BIGINT,
    sale_seller_id BIGINT,
    sale_product_id BIGINT,
    sale_quantity INTEGER,
    sale_total_price NUMERIC(12, 2),
    customer_key TEXT,
    pet_key TEXT,
    seller_key TEXT,
    product_key TEXT,
    store_key TEXT,
    supplier_key TEXT
);
