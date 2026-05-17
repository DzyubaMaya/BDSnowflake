# Лабораторная работа №4 — ETL на Trino

Реализация задания [MAIStudents/BigDataTrino](https://github.com/MAIStudents/BigDataTrino)

**Как устроен пайплайн:**

1. В **PostgreSQL** лежат первые 5 CSV-файлов (5000 строк) в таблице `mock_data`.
2. В **ClickHouse** — вторые 5 CSV (ещё 5000 строк) в `staging.mock_data`.
3. **Trino** читает обе таблицы как два каталога, объединяет строки и строит в ClickHouse схему **«звезда»** (`star`: дименшены + `fact_sales`).
4. Затем Trino по звезде считает витрины в схеме `reports` (см. таблицу ниже: 6 тем → 13 физических таблиц).
5. Проверка — SQL в ClickHouse, Trino или DBeaver.

## Раскладка данных

| Источник   | CSV-файлы                               | Таблица             | Строк |
| ---------- | --------------------------------------- | ------------------- | ----- |
| PostgreSQL | `MOCK_DATA.csv`, `MOCK_DATA (1..4).csv` | `public.mock_data`  | 5000  |
| ClickHouse | `MOCK_DATA (5..9).csv`                  | `staging.mock_data` | 5000  |

## Структура

```
lab4/
├── data/                         10 CSV
├── docker-compose.yml            postgres + clickhouse + loader + trino
├── postgres/Dockerfile           образ PG с CSV и init-скриптами
├── loader/                       одноразовая загрузка PG + CH
├── trino/Dockerfile              образ Trino с catalog и sql
├── sql/
│   ├── 10_star_ddl.sql           DDL звезды
│   ├── 20_star_load.sql          ETL → star
│   ├── 30_reports_ddl.sql        DDL витрин
│   ├── 40_reports_load.sql       расчёт витрин
│   ├── 50_checks_trino.sql       счётчики
│   └── 60_reports_preview_clickhouse.sql
└── scripts/run_etl.sh
```

## Запуск

```bash
cd lab4
docker-compose up -d --build    # PG, CH, loader (загрузка CSV), Trino
./scripts/run_etl.sh            # звезда + витрины + проверка
```

По этапам:

```bash
./scripts/run_etl.sh star       # только star
./scripts/run_etl.sh reports    # только витрины
./scripts/run_etl.sh check      # только счётчики
```

| Сервис     | Порт        | Логин / пароль |
| ---------- | ----------- | -------------- |
| PostgreSQL | 5432        | `lab` / `lab`  |
| ClickHouse | 8123, 9000  | `lab` / `lab`  |
| Trino      | 8080        | любой пользователь |

DBeaver:

- ClickHouse: `jdbc:clickhouse://localhost:8123/default`
- PostgreSQL: `jdbc:postgresql://localhost:5432/snowflake_lab`
- Trino: `jdbc:trino://localhost:8080/clickhouse/default`

## Модель «звезда» (`clickhouse.star`)

| Таблица        | Назначение                    |
| -------------- | ----------------------------- |
| `dim_date`     | календарь                     |
| `dim_customer` | клиенты                       |
| `dim_seller`   | продавцы (есть в `fact_sales.seller_id`) |
| `dim_product`  | товары                        |
| `dim_store`    | магазины (синтетический ключ) |
| `dim_supplier` | поставщики (синтетический ключ)|
| `fact_sales`   | факт продаж                   |

В `fact_sales.source_row_id` префикс `pg:` или `ch:` — откуда пришла строка.

## Витрины (`clickhouse.reports`): 6 тем → 13 таблиц

| Тема задания | Основная таблица | Доп. срез / метрики |
| ------------ | ---------------- | ------------------- |
| 1. Продукты | `report_products` (топ по **выручке** `sales_rank`, топ по **объёму** `sales_rank_by_qty`, `catalog_rating`, `catalog_reviews`) | `report_products_by_category` |
| 2. Клиенты | `report_customers` | `report_customers_by_country` |
| 3. Время | `report_time` (помесячно) | `report_time_year` (по годам), `report_time_period_compare` (выручка месяца к предыдущему, % изменения) |
| 4. Магазины | `report_stores` | `report_stores_by_geo` |
| 5. Поставщики | `report_suppliers` (`avg_unit_price` по факту, `avg_list_price` из `dim_product`) | `report_suppliers_by_country` |
| 6. Качество | `report_quality` | `report_quality_correlation` (одна строка: Pearson `corr(rating, total_qty)` и `corr(rating, total_revenue)` по продуктам) |



| #  | Таблица | Назначение |
| -- | ------- | ---------- |
| 1  | `report_products` | агрегаты по товару, два ранга |
| 1b | `report_products_by_category` | выручка по категориям |
| 2  | `report_customers` | клиенты, средний чек |
| 2b | `report_customers_by_country` | страны |
| 3  | `report_time` | месяцы |
| 3b | `report_time_year` | годы |
| 3c | `report_time_period_compare` | MoM |
| 4  | `report_stores` | магазины |
| 4b | `report_stores_by_geo` | география |
| 5  | `report_suppliers` | поставщики |
| 5b | `report_suppliers_by_country` | страны поставщиков |
| 6  | `report_quality` | рейтинги / отзывы / продажи по SKU |
| 6b | `report_quality_correlation` | корреляция рейтинга с объёмом и выручкой |

---

## Проверка: тестовые запросы и примеры вывода

Все команды — из папки `lab4`. Используется `docker-compose`.

### 1. Исходные данные (по 5000 строк)

**Запрос:**

```bash
docker-compose exec postgres psql -U lab -d snowflake_lab -c "SELECT COUNT(*) AS pg_rows FROM mock_data;"
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "SELECT count() AS ch_rows FROM staging.mock_data"
```

**Пример вывода:**

```
 pg_rows
---------
    5000

5000
```

---

### 2. Звезда: количество строк

**Запрос:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT 'fact_sales' AS t, count() FROM star.fact_sales
UNION ALL SELECT 'dim_customer', count() FROM star.dim_customer
UNION ALL SELECT 'dim_product', count() FROM star.dim_product
UNION ALL SELECT 'dim_date', count() FROM star.dim_date
UNION ALL SELECT 'dim_store', count() FROM star.dim_store
UNION ALL SELECT 'dim_supplier', count() FROM star.dim_supplier
FORMAT Pretty"
```

**Пример вывода:**

```
   ┏━━━━━━━━━━━━━━┳━━━━━━━━━┓
   ┃ t            ┃ count() ┃
   ┡━━━━━━━━━━━━━━╇━━━━━━━━━┩
   │ dim_date     │     364 │
   │ dim_customer │    1000 │
   │ dim_product  │    1000 │
   │ dim_supplier │   10000 │
   │ dim_store    │   10000 │
   │ fact_sales   │   10000 │
   └──────────────┴─────────┘
```

`dim_store` / `dim_supplier` ≈ 10000 — в CSV у каждой строки продажи своя комбинация полей магазина/поставщика, поэтому много уникальных ключей.

---

### 3. Объединение PostgreSQL + ClickHouse в факте

**Запрос:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT substring(source_row_id, 1, 2) AS src, count() AS cnt
FROM star.fact_sales
GROUP BY src
ORDER BY src
FORMAT Pretty"
```

**Пример вывода:**

```
   ┏━━━━━┳━━━━━━┓
   ┃ src ┃  cnt ┃
   ┡━━━━━╇━━━━━━┩
   │ ch  │ 5000 │
   │ pg  │ 5000 │
   └─────┴──────┘
```

---

### 4. Счётчики витрин

**Запрос:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT table_name, row_count FROM (
  SELECT 'report_products' AS table_name, count() AS row_count FROM reports.report_products
  UNION ALL SELECT 'report_customers', count() FROM reports.report_customers
  UNION ALL SELECT 'report_time', count() FROM reports.report_time
  UNION ALL SELECT 'report_time_year', count() FROM reports.report_time_year
  UNION ALL SELECT 'report_time_period_compare', count() FROM reports.report_time_period_compare
  UNION ALL SELECT 'report_quality', count() FROM reports.report_quality
  UNION ALL SELECT 'report_quality_correlation', count() FROM reports.report_quality_correlation
) ORDER BY table_name
FORMAT Pretty"
```

**Пример вывода:** `report_time_year` — **1** строка (в данных один календарный год), `report_time_period_compare` — **12** (по числу месяцев), `report_quality_correlation` — **1** строка.

Полный список после ETL (`50_checks_trino.sql`):

| Таблица                         | Строк (типично) |
| ------------------------------- | --------------- |
| `report_products`               | 1000            |
| `report_products_by_category`   | 3               |
| `report_customers`              | 1000            |
| `report_customers_by_country`   | 126             |
| `report_time`                   | 12              |
| `report_time_year`              | 1               |
| `report_time_period_compare`    | 12              |
| `report_stores`                 | 10000           |
| `report_stores_by_geo`          | 9852            |
| `report_suppliers`              | 10000           |
| `report_suppliers_by_country`   | 203             |
| `report_quality`                | 1000            |
| `report_quality_correlation`    | 1               |

---

### 5. Витрина 1 — продажи по продуктам

Топ по **выручке** — колонка `sales_rank`; топ по **объёму продаж (количество)** — `sales_rank_by_qty`. Рейтинг и число отзывов из каталога — `catalog_rating`, `catalog_reviews`.

**Топ-10 товаров по выручке:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT product_name, total_revenue, sales_rank
FROM reports.report_products
ORDER BY sales_rank
LIMIT 10
FORMAT Pretty"
```

**Пример вывода (фрагмент):**

```
   ┃ product_name ┃      total_revenue ┃ sales_rank ┃
   │ Bird Cage    │ 4005.98            │          1 │
   │ Cat Toy      │ 3784.44            │          2 │
   │ Bird Cage    │ 3751.09            │          3 │
   ...
```

**Топ-10 по количеству (`sales_rank_by_qty`):**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT product_name, total_qty, sales_rank_by_qty
FROM reports.report_products
ORDER BY sales_rank_by_qty
LIMIT 10
FORMAT Pretty
"
```

**Выручка по категориям:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT category, total_revenue, total_orders
FROM reports.report_products_by_category
ORDER BY total_revenue DESC
FORMAT Pretty"
```

**Пример вывода:**

```
   ┃ category ┃     total_revenue ┃ total_orders ┃
   │ Cage     │  845521.98        │         3350 │
   │ Food     │  843109.67        │         3300 │
   │ Toy      │  841220.47        │         3350 │
```

---

### 6. Витрина 2 — продажи по клиентам

**Топ-10 клиентов:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT first_name, last_name, country, total_spent, customer_rank
FROM reports.report_customers
ORDER BY customer_rank
LIMIT 10
FORMAT Pretty"
```

**Пример вывода (фрагмент):**

```
   ┃ first_name ┃ last_name  ┃ country   ┃ total_spent ┃ customer_rank ┃
   │ Mile       │ Tuer       │ Jordan    │ 4005.98     │             1 │
   │ Lewiss     │ Pinshon    │ China     │ 3784.44     │             2 │
   ...
```

**Клиенты по странам:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT country, customers_cnt, total_revenue
FROM reports.report_customers_by_country
ORDER BY total_revenue DESC
LIMIT 5
FORMAT Pretty"
```

**Пример вывода:**

```
   ┃ country     ┃ customers_cnt ┃ total_revenue ┃
   │ China       │           177 │ 451918.73     │
   │ Indonesia   │           112 │ 280610.79     │
   │ Philippines │            46 │ 119883.90     │
   ...
```

---

### 7. Витрина 3 — продажи по времени

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT year, month, total_revenue, avg_order_value
FROM reports.report_time
ORDER BY year, month
FORMAT Pretty"
```

**Пример вывода (фрагмент):**

```
   ┃ year ┃ month ┃ total_revenue ┃ avg_order_value ┃
   │ 2021 │     1 │ 224158.54     │ 256.47          │
   │ 2021 │     2 │ 192348.31     │ 260.28          │
   ...
   │ 2021 │    12 │ 191368.86     │ 248.53          │
```

12 строк — помесячные агрегаты за 2021 год.

**Год и сравнение с предыдущим месяцем:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT * FROM reports.report_time_year FORMAT Pretty
"
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT year, month, revenue_current, revenue_prior_month, pct_change_vs_prior
FROM reports.report_time_period_compare
ORDER BY year, month
FORMAT Pretty
"
```

---

### 8. Витрина 4 — продажи по магазинам

**Топ-5 магазинов:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT store_name, store_city, store_country, total_revenue, store_rank
FROM reports.report_stores
ORDER BY store_rank
LIMIT 5
FORMAT Pretty"
```

**Пример вывода:**

```
   ┃ store_name  ┃ store_city ┃ store_country ┃ total_revenue ┃ store_rank ┃
   │ DabZ        │ Grekan     │ South Africa  │        499.85 │          1 │
   │ Thoughtblab │ Fonte      │ Poland        │        499.80 │          2 │
   ...
```

**По географии:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT store_country, store_city, total_revenue
FROM reports.report_stores_by_geo
ORDER BY total_revenue DESC
LIMIT 5
FORMAT Pretty"
```

---

### 9. Витрина 5 — продажи по поставщикам

**Топ-5 поставщиков:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT supplier_name, supplier_country, total_revenue, avg_unit_price, avg_list_price, supplier_rank
FROM reports.report_suppliers
ORDER BY supplier_rank
LIMIT 5
FORMAT Pretty"
```

**Пример вывода:**

```
   ┃ supplier_name ┃ supplier_country ┃ total_revenue ┃ supplier_rank ┃
   │ Brainverse    │ Ireland          │        499.85 │             1 │
   │ Jamia         │ Russia           │        499.80 │             2 │
   ...
```

---

### 10. Витрина 6 — качество продукции

**Корреляция (одна строка на всю выборку продуктов):**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT * FROM reports.report_quality_correlation FORMAT Pretty
"
```

**Лучший рейтинг:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT product_name, rating, reviews, total_revenue, rating_rank_desc
FROM reports.report_quality
ORDER BY rating_rank_desc
LIMIT 5
FORMAT Pretty"
```

**Пример вывода:**

```
   ┃ product_name ┃ rating ┃ reviews ┃ total_revenue ┃
   │ Dog Food     │      5 │      48 │       2394.00 │
   │ Cat Toy      │      5 │     512 │       2185.49 │
   ...
```

**Больше всего отзывов:**

```bash
docker-compose exec clickhouse clickhouse-client -u lab --password lab -q "
SELECT product_name, rating, reviews, reviews_rank
FROM reports.report_quality
ORDER BY reviews_rank
LIMIT 5
FORMAT Pretty"
```

**Пример вывода:**

```
   ┃ product_name ┃ rating ┃ reviews ┃ reviews_rank ┃
   │ Bird Cage    │      4 │    1000 │            1 │
   │ Dog Food     │    1.7 │    1000 │            2 │
   ...
```

---

### 11. Проверка через Trino

```bash
docker-compose exec -T trino trino --execute "
SELECT product_name, total_revenue, sales_rank
FROM clickhouse.reports.report_products
ORDER BY sales_rank
LIMIT 5"
```

**Пример вывода:**

```
"611","Bird Cage","Toy","Roomm","10","63.0","4005.98","46.07","2.8","642","1"
"779","Cat Toy","Toy","Jayo","10","59.0","3784.44","55.63","4.8","709","2"
...
```

---

## Остановка

```bash
docker-compose down          # остановить контейнеры
docker-compose down -v       # удалить тома (полный сброс данных)
```
