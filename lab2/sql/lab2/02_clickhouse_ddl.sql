CREATE DATABASE IF NOT EXISTS reports;

DROP TABLE IF EXISTS reports.sales_product_report;
DROP TABLE IF EXISTS reports.sales_customer_report;
DROP TABLE IF EXISTS reports.sales_time_report;
DROP TABLE IF EXISTS reports.sales_store_report;
DROP TABLE IF EXISTS reports.sales_supplier_report;
DROP TABLE IF EXISTS reports.product_quality_report;

DROP TABLE IF EXISTS reports.report_products;
DROP TABLE IF EXISTS reports.report_customers;
DROP TABLE IF EXISTS reports.report_time;
DROP TABLE IF EXISTS reports.report_stores;
DROP TABLE IF EXISTS reports.report_suppliers;
DROP TABLE IF EXISTS reports.report_quality;

CREATE TABLE reports.report_products (
  product_id     Int32,
  product_name   String,
  category       String,
  brand          String,
  total_orders   UInt64,
  total_qty      Float64,
  total_revenue  Float64,
  avg_unit_price Float64,
  rating         Float64,
  reviews        UInt64,
  sales_rank     UInt32
)
ENGINE = MergeTree
ORDER BY (product_id);

CREATE TABLE reports.report_customers (
  customer_id   Int32,
  first_name    String,
  last_name     String,
  country       String,
  total_orders  UInt64,
  total_qty     Float64,
  total_spent   Float64,
  avg_check     Float64,
  customer_rank UInt32
)
ENGINE = MergeTree
ORDER BY (customer_id);

CREATE TABLE reports.report_time (
  year            Int16,
  month           Int8,
  total_orders    UInt64,
  total_qty       Float64,
  total_revenue   Float64,
  avg_order_value Float64
)
ENGINE = MergeTree
ORDER BY (year, month);

CREATE TABLE reports.report_stores (
  store_id      Int32,
  store_name    String,
  store_city    String,
  store_country String,
  total_orders  UInt64,
  total_qty     Float64,
  total_revenue Float64,
  avg_check     Float64,
  store_rank    UInt32
)
ENGINE = MergeTree
ORDER BY (store_id);

CREATE TABLE reports.report_suppliers (
  supplier_id      Int32,
  supplier_name    String,
  supplier_country String,
  total_orders     UInt64,
  total_qty        Float64,
  total_revenue    Float64,
  avg_unit_price   Float64,
  supplier_rank    UInt32
)
ENGINE = MergeTree
ORDER BY (supplier_id);

CREATE TABLE reports.report_quality (
  product_id    Int32,
  product_name  String,
  rating        Float64,
  reviews       UInt64,
  total_qty     Float64,
  total_revenue Float64,
  rating_rank_desc UInt32,
  rating_rank_asc  UInt32,
  reviews_rank     UInt32
)
ENGINE = MergeTree
ORDER BY (product_id);
