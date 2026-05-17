-- Lab4: populate datamarts from clickhouse.star.* via Trino.

-- ====================================================================
-- 1. Sales by Products
-- ====================================================================
INSERT INTO clickhouse.reports.report_products
SELECT
  p.product_id,
  p.product_name,
  p.category,
  p.brand,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_revenue,
  COALESCE(AVG(f.unit_price),  0) AS avg_unit_price,
  COALESCE(MAX(p.rating),       0) AS catalog_rating,
  COALESCE(MAX(p.reviews),      0) AS catalog_reviews,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(f.total_price), 0) DESC) AS INTEGER) AS sales_rank,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(f.quantity),    0) DESC) AS INTEGER) AS sales_rank_by_qty
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_product p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.brand;

INSERT INTO clickhouse.reports.report_products_by_category
SELECT
  COALESCE(p.category, 'N/A') AS category,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_revenue
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_product p ON f.product_id = p.product_id
GROUP BY COALESCE(p.category, 'N/A');

-- ====================================================================
-- 2. Sales by Customers
-- ====================================================================
INSERT INTO clickhouse.reports.report_customers
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_spent,
  COALESCE(AVG(f.total_price), 0) AS avg_check,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(f.total_price), 0) DESC) AS INTEGER) AS customer_rank
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country;

INSERT INTO clickhouse.reports.report_customers_by_country
SELECT
  COALESCE(c.country, 'N/A') AS country,
  COUNT(DISTINCT c.customer_id) AS customers_cnt,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.total_price), 0) AS total_revenue
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_customer c ON f.customer_id = c.customer_id
GROUP BY COALESCE(c.country, 'N/A');

-- ====================================================================
-- 3. Sales over Time (monthly + yearly + MoM comparison)
-- ====================================================================
INSERT INTO clickhouse.reports.report_time
SELECT
  d.year,
  d.month,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_revenue,
  COALESCE(AVG(f.total_price), 0) AS avg_order_value
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month;

INSERT INTO clickhouse.reports.report_time_year
SELECT
  d.year,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_revenue,
  COALESCE(AVG(f.total_price), 0) AS avg_order_value
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_date d ON f.date_key = d.date_key
GROUP BY d.year;

INSERT INTO clickhouse.reports.report_time_period_compare
WITH monthly AS (
  SELECT
    d.year,
    d.month,
    COUNT(*) AS total_orders,
    COALESCE(SUM(f.total_price), 0) AS total_revenue
  FROM clickhouse.star.fact_sales f
  JOIN clickhouse.star.dim_date d ON f.date_key = d.date_key
  GROUP BY d.year, d.month
)
SELECT
  y.year,
  y.month,
  y.total_revenue AS revenue_current,
  p.total_revenue AS revenue_prior_month,
  CASE
    WHEN p.total_revenue IS NULL OR p.total_revenue = 0 THEN CAST(NULL AS DOUBLE)
    ELSE 100.0 * (y.total_revenue - p.total_revenue) / p.total_revenue
  END AS pct_change_vs_prior
FROM monthly y
LEFT JOIN monthly p
  ON (
    (p.year = y.year AND p.month = y.month - 1)
    OR (y.month = 1 AND p.year = y.year - 1 AND p.month = 12)
  );

-- ====================================================================
-- 4. Sales by Stores
-- ====================================================================
INSERT INTO clickhouse.reports.report_stores
SELECT
  s.store_id,
  s.store_name,
  s.store_city,
  s.store_country,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_revenue,
  COALESCE(AVG(f.total_price), 0) AS avg_check,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(f.total_price), 0) DESC) AS INTEGER) AS store_rank
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_store s ON f.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.store_city, s.store_country;

INSERT INTO clickhouse.reports.report_stores_by_geo
SELECT
  COALESCE(s.store_country, 'N/A') AS store_country,
  COALESCE(s.store_city,    'N/A') AS store_city,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.total_price), 0) AS total_revenue
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_store s ON f.store_id = s.store_id
GROUP BY COALESCE(s.store_country, 'N/A'), COALESCE(s.store_city, 'N/A');

-- ====================================================================
-- 5. Sales by Suppliers (avg unit in sales + avg list price from dim_product)
-- ====================================================================
INSERT INTO clickhouse.reports.report_suppliers
SELECT
  sp.supplier_id,
  sp.supplier_name,
  sp.supplier_country,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_revenue,
  COALESCE(AVG(f.unit_price),  0) AS avg_unit_price,
  COALESCE(AVG(p.list_price),  0) AS avg_list_price,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(f.total_price), 0) DESC) AS INTEGER) AS supplier_rank
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_supplier sp ON f.supplier_id = sp.supplier_id
JOIN clickhouse.star.dim_product p ON f.product_id = p.product_id
GROUP BY sp.supplier_id, sp.supplier_name, sp.supplier_country;

INSERT INTO clickhouse.reports.report_suppliers_by_country
SELECT
  COALESCE(sp.supplier_country, 'N/A') AS supplier_country,
  COUNT(DISTINCT sp.supplier_id) AS suppliers_cnt,
  COUNT(*) AS total_orders,
  COALESCE(SUM(f.total_price), 0) AS total_revenue
FROM clickhouse.star.fact_sales f
JOIN clickhouse.star.dim_supplier sp ON f.supplier_id = sp.supplier_id
GROUP BY COALESCE(sp.supplier_country, 'N/A');

-- ====================================================================
-- 6. Product Quality + Pearson correlation (rating vs qty / revenue)
-- ====================================================================
INSERT INTO clickhouse.reports.report_quality
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.reviews,
  COALESCE(SUM(f.quantity),    0) AS total_qty,
  COALESCE(SUM(f.total_price), 0) AS total_revenue,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(p.rating,  0) DESC) AS INTEGER) AS rating_rank_desc,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(p.rating,  0) ASC)  AS INTEGER) AS rating_rank_asc,
  CAST(ROW_NUMBER() OVER (ORDER BY COALESCE(p.reviews, 0) DESC) AS INTEGER) AS reviews_rank
FROM clickhouse.star.dim_product p
LEFT JOIN clickhouse.star.fact_sales f ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.rating, p.reviews;

INSERT INTO clickhouse.reports.report_quality_correlation
WITH per_product AS (
  SELECT
    p.product_id,
    CAST(p.rating AS DOUBLE) AS rating,
    COALESCE(SUM(f.quantity),    0) AS total_qty,
    COALESCE(SUM(f.total_price), 0) AS total_revenue
  FROM clickhouse.star.dim_product p
  LEFT JOIN clickhouse.star.fact_sales f ON f.product_id = p.product_id
  WHERE p.rating IS NOT NULL
  GROUP BY p.product_id, p.rating
)
SELECT
  CAST(1 AS INTEGER) AS id,
  corr(rating, total_qty) AS corr_rating_total_qty,
  corr(rating, total_revenue) AS corr_rating_total_revenue,
  COUNT(*) AS n_products
FROM per_product;
