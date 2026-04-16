# BigDataSnowflake
Лабораторная работа №1  
Нормализация данных в аналитическую модель типа **Snowflake (снежинка)**

---

## Цель работы

Преобразовать исходные данные (10 CSV-файлов) в аналитическую модель данных типа **снежинка**: выделить **факт продаж** и **измерения**, нормализовать повторяющиеся атрибуты (страны, категории, бренды).

---

## Исходные данные

Используются 10 CSV-файлов с данными о продажах товаров для домашних животных.  
Все CSV находятся в папке `data/`.

---

## Построенная модель

### Staging
- `mock_data` — staging-таблица, в неё загружаются все 10 CSV (всего **10000** строк)

### Факт
- `fact_sales` — факт продаж (меры: `quantity`, `total_price`, `unit_price`)

### Измерения
- `dim_customer`
- `dim_seller`
- `dim_product`
- `dim_store`
- `dim_supplier`
- `dim_date`

### Нормализация (уровень снежинки)
- `dim_country` — страны вынесены отдельно (на неё ссылаются customer/seller/store/supplier)
- `dim_product_category` — категории товара
- `dim_product_brand` — бренды товара

Итого в `public` получается 11 таблиц: `mock_data`, `fact_sales` и 9 `dim_*`.

---

## Структура проекта

```text
BDSnowflake/
│
├── docker-compose.yml
├── Dockerfile
├── README.md
│
├── data/
│   ├── MOCK_DATA.csv
│   ├── MOCK_DATA (1).csv
│   ├── ...
│   └── MOCK_DATA (9).csv
│
└── sql/
    ├── init/
    │   ├── 01_create_mock_data.sql
    │   └── 02_load_mock_data.sql
    │
    ├── explore/
    │   └── 01_profiling.sql
    │
    └── dw/
        ├── 00_truncate_dw.sql
        ├── 01_ddl_dimensions.sql
        ├── 02_ddl_fact.sql
        ├── 03_dml_load.sql
        ├── 04_verify.sql
        └── 06_checks.sql
```

---

## Запуск лабораторной работы

### 1) Запуск базы данных (Docker)

В корне проекта:

```bash
docker-compose up -d --build
```

Параметры подключения:

| Параметр | Значение |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `snowflake_lab` |
| User | `lab` |
| Password | `lab` |
| Schema | `public` |

---

### 2) Staging: создание и загрузка `mock_data` (автоматически)

При первом запуске контейнера Postgres выполняет init-скрипты из `sql/init/`:
- `01_create_mock_data.sql` — создаёт таблицу `mock_data`
- `02_load_mock_data.sql` — загружает 10 CSV в `mock_data`

Проверка:

```bash
docker-compose exec db psql -U lab -d snowflake_lab -c "SELECT COUNT(*) FROM mock_data;"
```

Ожидается:

```text
10000
```

---

### 3) Анализ исходных данных (profiling)

Файл с запросами:
- `sql/explore/01_profiling.sql`

Запускать удобно в DBeaver (SQL Editor), подключившись к базе `snowflake_lab`.

---

### 4) Создание схемы снежинка (DDL)

Запуск (вариант через терминал):

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/01_ddl_dimensions.sql
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/02_ddl_fact.sql
```

Запуск (вариант через DBeaver):
- Открыть файлы `sql/dw/01_ddl_dimensions.sql` и `sql/dw/02_ddl_fact.sql`
- Выполнить их в базе `snowflake_lab` (schema `public`)

---

### 5) Заполнение измерений и факта (DML)

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/03_dml_load.sql
```

Запуск (вариант через DBeaver):
- Открыть файл `sql/dw/03_dml_load.sql`
- Выполнить в базе `snowflake_lab`

Примечания:
- В исходных данных `sale_date` хранится строкой формата `M/D/YYYY` (например, `3/7/2024`) и парсится в `sql/dw/03_dml_load.sql` через `to_date(..., 'FMMM/FMDD/YYYY')`.
- Для выбора одной строки на сущность (клиент/продавец/товар и т.д.) используется `row_number() ... where rn = 1`.

---

### 6) Проверка результата

Запуск скрипта проверок:

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/04_verify.sql
```

Единый файл проверок (как “checks”):

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/06_checks.sql
```

Минимальные проверки вручную:

```bash
docker-compose exec db psql -U lab -d snowflake_lab -c "SELECT COUNT(*) FROM mock_data;"
docker-compose exec db psql -U lab -d snowflake_lab -c "SELECT COUNT(*) FROM fact_sales;"
```

Ожидается:

```text
10000
10000
```

Проверка сумм (должны совпасть):

```sql
SELECT
  round((SELECT sum(sale_total_price::numeric) FROM mock_data)::numeric, 2) AS sum_total_staging,
  round((SELECT sum(total_price) FROM fact_sales)::numeric, 2)             AS sum_total_fact;
```

Проверка “потерь” (ожидается 0):

```sql
SELECT COUNT(*) AS lost_rows
FROM mock_data m
LEFT JOIN fact_sales f ON f.source_row_id = m.row_id
WHERE f.source_row_id IS NULL;
```

---

## Пример аналитического запроса (top-10 по сумме)

```sql
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
```

То же самое одной командой из терминала:

```bash
docker-compose exec db psql -U lab -d snowflake_lab -c "SELECT co.country_name, pr.product_name, sum(f.quantity) AS total_qty, round(sum(f.total_price), 2) AS total_sum FROM fact_sales f JOIN dim_customer c ON c.customer_key = f.customer_key JOIN dim_country co ON co.country_key = c.country_key JOIN dim_product pr ON pr.product_key = f.product_key GROUP BY co.country_name, pr.product_name ORDER BY total_sum DESC LIMIT 10;"
```

---

## Повторный запуск (перезагрузка витрины)

Если нужно перезаполнить витрину (не трогая `mock_data`):

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/00_truncate_dw.sql
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/03_dml_load.sql
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/04_verify.sql
```

Если нужно полностью пересоздать БД с нуля:

```bash
docker-compose down -v
docker-compose up -d --build
```

Важно: init-скрипты из `sql/init/` выполняются Postgres только при первом запуске на пустом томе. Если контейнер просто перезапустить без `-v`, автоматическая загрузка CSV в `mock_data` повторно не произойдёт.

