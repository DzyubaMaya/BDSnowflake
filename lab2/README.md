# Лабораторная работа №2 (обязательная часть) — ETL на PySpark + ClickHouse

## Что поднимаем

- `db` (PostgreSQL): staging `mock_data` + модель **звезда** в схеме `star`
- `spark` (PySpark): 2 ETL-джобы
- `clickhouse` (ClickHouse): база `reports` и 6 таблиц отчётов

## Запуск инфраструктуры

Из папки `lab2/`:

```bash
docker-compose up -d --build
docker-compose ps
```

Важно:
- `mock_data` можно загрузить **двумя способами**:
  - автоматически init-скриптами Postgres (`sql/init/`) при первом запуске на пустом томе
  - или **через Spark**: job1 читает CSV из `data/` и перезаписывает `public.mock_data`

Если нужно полностью пересоздать БД и заново залить данные init-скриптами, используй:

```bash
docker-compose down -v
docker-compose up -d --build
```

## 1) Подготовить схему звезды в PostgreSQL

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/lab2/01_star_ddl.sql
```

## 2) Подготовить таблицы отчётов в ClickHouse

```bash
docker-compose exec -T clickhouse clickhouse-client -q "$(cat sql/lab2/02_clickhouse_ddl.sql)"
```

## 3) Spark Job #1: mock_data → звезда (PostgreSQL)

```bash
docker-compose exec -T spark spark-submit-jdbc /app/jobs/job1_star_from_mock.py
```

Проверка:

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -c "SELECT COUNT(*) FROM star.fact_sales;"
```

## 4) Spark Job #2: звезда → 6 отчётов (ClickHouse)

```bash
docker-compose exec -T spark spark-submit-jdbc /app/jobs/job2_reports_to_clickhouse.py
```

Проверка (пример):

```bash
docker-compose exec -T clickhouse clickhouse-client -q "SELECT count() FROM reports.report_products;"
docker-compose exec -T clickhouse clickhouse-client -q "SELECT * FROM reports.report_products ORDER BY total_revenue DESC LIMIT 10;"
```

Подключение к ClickHouse с хоста (DBeaver): HTTP `8123`, native `9000`, user `lab`, password `lab`, DB `reports`.

Примечание: отчёты формируются через единый `fact_enriched` (join факта с измерениями) и содержат ранги (`sales_rank`, `customer_rank`, `store_rank`, `supplier_rank`, `rating_rank_*`, `reviews_rank`), как в типовом решении.

## 5) Готовые проверки (checks)

PostgreSQL:

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/lab2/03_postgres_checks.sql
```

ClickHouse:

```bash
docker-compose exec -T clickhouse clickhouse-client -q "$(cat sql/lab2/04_clickhouse_checks.sql)"
```

