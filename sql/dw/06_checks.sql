-- 1) Количество строк
SELECT COUNT(*) AS mock_data_rows FROM mock_data;
SELECT COUNT(*) AS fact_rows FROM fact_sales;

-- 2) Сверка сумм (должны совпасть)
SELECT
  round((SELECT sum(sale_total_price::numeric) FROM mock_data)::numeric, 2) AS sum_total_staging,
  round((SELECT sum(total_price) FROM fact_sales)::numeric, 2)             AS sum_total_fact;

-- 3) Потери (все строки staging должны попасть в факт)
SELECT COUNT(*) AS lost_rows
FROM mock_data m
LEFT JOIN fact_sales f ON f.source_row_id = m.row_id
WHERE f.source_row_id IS NULL;

-- 4) Пример аналитического запроса: top-10 по выручке (страна клиента × товар)
SELECT
  co.country_name,
  pr.product_name,
  sum(f.quantity) AS total_qty,
  round(sum(f.total_price), 2) AS total_sum
FROM fact_sales f
JOIN dim_customer c ON c.customer_key = f.customer_key
JOIN dim_country co ON co.country_key = c.country_key
JOIN dim_product pr ON pr.product_key = f.product_key
GROUP BY co.country_name, pr.product_name
ORDER BY total_sum DESC
LIMIT 10;

