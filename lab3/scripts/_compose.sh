# Resolve docker compose CLI (Compose V2 plugin vs docker-compose v1).
compose() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}
