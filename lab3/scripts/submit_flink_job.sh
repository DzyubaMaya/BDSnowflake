#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_compose.sh"

JAR_PATH="/opt/flink/usrlib/lab3-flink-job-1.0.0.jar"

compose exec \
  -e KAFKA_BOOTSTRAP_SERVERS=kafka:19092 \
  -e KAFKA_TOPIC=petshop.sales.raw \
  -e POSTGRES_JDBC_URL=jdbc:postgresql://postgres:5432/pet_shop \
  -e POSTGRES_USER=pet_user \
  -e POSTGRES_PASSWORD=pet_password \
  jobmanager \
  flink run -d "$JAR_PATH"
