#!/usr/bin/env bash
# Lab4: run the whole Trino ETL end-to-end.
#
# Usage:
#   ./scripts/run_etl.sh                # run all stages
#   ./scripts/run_etl.sh star           # only star schema (DDL+load)
#   ./scripts/run_etl.sh reports        # only datamart layer
#   ./scripts/run_etl.sh check          # only counters
set -euo pipefail

LAB4_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$LAB4_ROOT"

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  echo "[lab4] need docker-compose or 'docker compose'" >&2
  exit 1
fi
TRINO_EXEC="$COMPOSE exec -T trino trino --server http://localhost:8080 --catalog clickhouse --schema default"

run_sql() {
  local file="$1"
  local basename
  basename="$(basename "$file")"
  local host_sql="${LAB4_ROOT:-.}/sql/${basename}"
  echo
  echo "============================================================"
  echo "  >> running $basename"
  echo "============================================================"
  # Prefer SQL baked into the trino image (/sql). Fall back to piping from host
  # when bind mounts are empty (common on Docker Desktop / Colima).
  if $COMPOSE exec -T trino test -f "/sql/${basename}"; then
    $TRINO_EXEC --file "/sql/${basename}"
  elif [ -f "$host_sql" ]; then
    cat "$host_sql" | $TRINO_EXEC
  else
    echo "[lab4] missing ${host_sql} and /sql/${basename} in container" >&2
    exit 1
  fi
}

wait_trino() {
  echo "[lab4] waiting for trino to accept queries..."
  for i in $(seq 1 60); do
    if $COMPOSE exec -T trino trino --execute "SELECT 1" >/dev/null 2>&1; then
      echo "[lab4] trino is ready"
      return 0
    fi
    sleep 2
  done
  echo "[lab4] trino did not become ready in time" >&2
  exit 1
}

wait_trino

stage="${1:-all}"

case "$stage" in
  star)
    run_sql 10_star_ddl.sql
    run_sql 20_star_load.sql
    ;;
  reports)
    run_sql 30_reports_ddl.sql
    run_sql 40_reports_load.sql
    ;;
  check)
    run_sql 50_checks_trino.sql
    ;;
  all)
    run_sql 10_star_ddl.sql
    run_sql 20_star_load.sql
    run_sql 30_reports_ddl.sql
    run_sql 40_reports_load.sql
    run_sql 50_checks_trino.sql
    ;;
  *)
    echo "unknown stage: $stage (expected: star|reports|check|all)" >&2
    exit 2
    ;;
esac

echo
echo "[lab4] done."
