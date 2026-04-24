# Лабораторная работа №1 — Snowflake (снежинка) в PostgreSQL

## Что внутри

- **Данные**: 10 CSV в `lab1/data/`
- **Staging**: `mock_data` (10000 строк) — загружается автоматически при первом старте БД
- **DW (snowflake)**: DDL/DML в `lab1/sql/dw/`

## Запуск

Из папки `lab1/`:

```bash
docker-compose up -d --build
docker-compose ps
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

## 1) Проверить, что staging загрузился

```bash
docker-compose exec db psql -U lab -d snowflake_lab -c "SELECT COUNT(*) FROM mock_data;"
```

Ожидается: `10000`.

## 2) Создать DDL (измерения + факт)

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/01_ddl_dimensions.sql
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/02_ddl_fact.sql
```

## 3) Заполнить DW (DML)

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/03_dml_load.sql
```

## 4) Проверки

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/04_verify.sql
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/06_checks.sql
```

## Повторный запуск

- **Перезаполнить DW (не трогая staging)**:

```bash
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/00_truncate_dw.sql
docker-compose exec -T db psql -U lab -d snowflake_lab -f - < sql/dw/03_dml_load.sql
```

- **Полностью пересоздать БД** (важно для повторной автозагрузки `mock_data` init-скриптами):

```bash
docker-compose down -v
docker-compose up -d --build
```

