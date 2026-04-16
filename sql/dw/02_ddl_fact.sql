CREATE TABLE fact_sales (
  sale_key      BIGSERIAL PRIMARY KEY,
  source_row_id BIGINT NOT NULL UNIQUE REFERENCES mock_data (row_id),
  date_key      INTEGER REFERENCES dim_date (date_key),
  customer_key  INTEGER NOT NULL REFERENCES dim_customer (customer_key),
  seller_key    INTEGER NOT NULL REFERENCES dim_seller (seller_key),
  product_key   INTEGER NOT NULL REFERENCES dim_product (product_key),
  store_key     INTEGER NOT NULL REFERENCES dim_store (store_key),
  supplier_key  INTEGER NOT NULL REFERENCES dim_supplier (supplier_key),
  quantity      NUMERIC NOT NULL,
  total_price   NUMERIC NOT NULL,
  unit_price    NUMERIC
);

COMMENT ON TABLE fact_sales IS 'Факт продажи; меры: quantity, total_price, unit_price.';
