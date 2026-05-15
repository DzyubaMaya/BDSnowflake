#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
mkdir -p "$REPO_ROOT/flink-job/target"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_compose.sh"

compose build flink-build
compose run --rm flink-build
