FROM clickhouse/clickhouse-server:24.8
RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -rf /var/lib/apt/lists/*
COPY data/*.csv /csv/
COPY postgres/init/*.sql /pg-init/
COPY clickhouse/init/01_init.sh /ch-init.sh
COPY loader/load.sh /load.sh
RUN chmod +x /load.sh /ch-init.sh
ENTRYPOINT ["/load.sh"]
