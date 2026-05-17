#!/usr/bin/env bash
set -euo pipefail

CH() {
  clickhouse-client --host "${CH_HOST:-127.0.0.1}" --user "${CLICKHOUSE_USER:-lab}" --password "${CLICKHOUSE_PASSWORD:-lab}" "$@"
}

echo "[lab4][clickhouse] creating staging database and mock_data table..."

CH --multiquery --query "
CREATE DATABASE IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.mock_data;

CREATE TABLE staging.mock_data (
  row_id              UInt64,
  id                  Nullable(Int32),
  customer_first_name Nullable(String),
  customer_last_name  Nullable(String),
  customer_age        Nullable(String),
  customer_email      Nullable(String),
  customer_country    Nullable(String),
  customer_postal_code Nullable(String),
  customer_pet_type   Nullable(String),
  customer_pet_name   Nullable(String),
  customer_pet_breed  Nullable(String),
  seller_first_name   Nullable(String),
  seller_last_name    Nullable(String),
  seller_email        Nullable(String),
  seller_country      Nullable(String),
  seller_postal_code  Nullable(String),
  product_name        Nullable(String),
  product_category    Nullable(String),
  product_price       Nullable(String),
  product_quantity    Nullable(String),
  sale_date           Nullable(String),
  sale_customer_id    Nullable(Int32),
  sale_seller_id      Nullable(Int32),
  sale_product_id     Nullable(Int32),
  sale_quantity       Nullable(String),
  sale_total_price    Nullable(String),
  store_name          Nullable(String),
  store_location      Nullable(String),
  store_city          Nullable(String),
  store_state         Nullable(String),
  store_country       Nullable(String),
  store_phone         Nullable(String),
  store_email         Nullable(String),
  pet_category        Nullable(String),
  product_weight      Nullable(String),
  product_color       Nullable(String),
  product_size        Nullable(String),
  product_brand       Nullable(String),
  product_material    Nullable(String),
  product_description Nullable(String),
  product_rating      Nullable(String),
  product_reviews     Nullable(String),
  product_release_date Nullable(String),
  product_expiry_date  Nullable(String),
  supplier_name       Nullable(String),
  supplier_contact    Nullable(String),
  supplier_email      Nullable(String),
  supplier_phone      Nullable(String),
  supplier_address    Nullable(String),
  supplier_city       Nullable(String),
  supplier_country    Nullable(String)
)
ENGINE = MergeTree
ORDER BY row_id;
"

# Logical rows per file (CSVWithNames; multiline fields make wc -l unreliable)
ROWS_PER_FILE=1000
OFFSET=0

FILES=(
  "/csv/MOCK_DATA (5).csv"
  "/csv/MOCK_DATA (6).csv"
  "/csv/MOCK_DATA (7).csv"
  "/csv/MOCK_DATA (8).csv"
  "/csv/MOCK_DATA (9).csv"
)

for f in "${FILES[@]}"; do
  echo "[lab4][clickhouse] loading $f (row_id offset = $OFFSET)..."
  CH --query "
    INSERT INTO staging.mock_data
    SELECT
      ${OFFSET} + rowNumberInAllBlocks() + 1 AS row_id,
      *
    FROM input('
      id Nullable(Int32),
      customer_first_name Nullable(String),
      customer_last_name Nullable(String),
      customer_age Nullable(String),
      customer_email Nullable(String),
      customer_country Nullable(String),
      customer_postal_code Nullable(String),
      customer_pet_type Nullable(String),
      customer_pet_name Nullable(String),
      customer_pet_breed Nullable(String),
      seller_first_name Nullable(String),
      seller_last_name Nullable(String),
      seller_email Nullable(String),
      seller_country Nullable(String),
      seller_postal_code Nullable(String),
      product_name Nullable(String),
      product_category Nullable(String),
      product_price Nullable(String),
      product_quantity Nullable(String),
      sale_date Nullable(String),
      sale_customer_id Nullable(Int32),
      sale_seller_id Nullable(Int32),
      sale_product_id Nullable(Int32),
      sale_quantity Nullable(String),
      sale_total_price Nullable(String),
      store_name Nullable(String),
      store_location Nullable(String),
      store_city Nullable(String),
      store_state Nullable(String),
      store_country Nullable(String),
      store_phone Nullable(String),
      store_email Nullable(String),
      pet_category Nullable(String),
      product_weight Nullable(String),
      product_color Nullable(String),
      product_size Nullable(String),
      product_brand Nullable(String),
      product_material Nullable(String),
      product_description Nullable(String),
      product_rating Nullable(String),
      product_reviews Nullable(String),
      product_release_date Nullable(String),
      product_expiry_date Nullable(String),
      supplier_name Nullable(String),
      supplier_contact Nullable(String),
      supplier_email Nullable(String),
      supplier_phone Nullable(String),
      supplier_address Nullable(String),
      supplier_city Nullable(String),
      supplier_country Nullable(String)
    ') FORMAT CSVWithNames
  " < "$f"
  OFFSET=$((OFFSET + ROWS_PER_FILE))
done

echo "[lab4][clickhouse] mock_data rows:"
CH --query "SELECT count() FROM staging.mock_data"
