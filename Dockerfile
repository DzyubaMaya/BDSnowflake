FROM postgres:16-alpine
COPY sql/init/ /docker-entrypoint-initdb.d/
COPY data/ /csv/
