FROM postgres:16
COPY postgres/init/*.sql /docker-entrypoint-initdb.d/
COPY data/*.csv /csv/
