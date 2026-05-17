#!/usr/bin/env bash
set -euo pipefail

PGHOST="${PGHOST:-postgres}"
PGUSER="${PGUSER:-lab}"
PGPASSWORD="${PGPASSWORD:-lab}"
PGDATABASE="${PGDATABASE:-snowflake_lab}"
export PGPASSWORD

CH_HOST="${CH_HOST:-clickhouse}"
CH_USER="${CH_USER:-lab}"
CH_PASSWORD="${CH_PASSWORD:-lab}"
export CLICKHOUSE_USER="$CH_USER"
export CLICKHOUSE_PASSWORD="$CH_PASSWORD"
export CH_HOST

wait_pg() {
  for _ in $(seq 1 60); do
    if psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -c "SELECT 1" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "[loader] postgres not ready" >&2
  exit 1
}

wait_ch() {
  for _ in $(seq 1 60); do
    if clickhouse-client --host "$CH_HOST" --user "$CH_USER" --password "$CH_PASSWORD" -q "SELECT 1" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "[loader] clickhouse not ready" >&2
  exit 1
}

pg_rows() {
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -tAc \
    "SELECT COUNT(*) FROM mock_data" 2>/dev/null || echo "0"
}

ch_rows() {
  clickhouse-client --host "$CH_HOST" --user "$CH_USER" --password "$CH_PASSWORD" -q \
    "SELECT count() FROM staging.mock_data" 2>/dev/null || echo "0"
}

echo "[loader] waiting for databases..."
wait_pg
wait_ch

PG_CNT="$(pg_rows | tr -d '[:space:]')"
if [ "${PG_CNT:-0}" != "5000" ]; then
  echo "[loader] loading PostgreSQL mock_data (had ${PG_CNT:-0} rows)..."
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -v ON_ERROR_STOP=1 -c "DROP TABLE IF EXISTS mock_data;"
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -v ON_ERROR_STOP=1 -f /pg-init/01_create_mock_data.sql
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -v ON_ERROR_STOP=1 -f /pg-init/02_load_mock_data.sql
  echo "[loader] postgres rows: $(pg_rows)"
else
  echo "[loader] postgres mock_data already has 5000 rows, skip"
fi

CH_CNT="$(ch_rows | tr -d '[:space:]')"
if [ "${CH_CNT:-0}" != "5000" ]; then
  echo "[loader] loading ClickHouse staging.mock_data (had ${CH_CNT:-0} rows)..."
  /ch-init.sh
else
  echo "[loader] clickhouse staging.mock_data already has 5000 rows, skip"
fi

echo "[loader] done."
