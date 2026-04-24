#!/usr/bin/env bash
set -euo pipefail

JARS="/opt/spark/jars-extra/postgresql-42.7.4.jar,/opt/spark/jars-extra/clickhouse-jdbc-0.6.0-all.jar"
CP="/opt/spark/jars-extra/postgresql-42.7.4.jar:/opt/spark/jars-extra/clickhouse-jdbc-0.6.0-all.jar"

exec /opt/spark/bin/spark-submit \
  --jars "$JARS" \
  --driver-class-path "$CP" \
  --conf "spark.executor.extraClassPath=$CP" \
  "$@"

