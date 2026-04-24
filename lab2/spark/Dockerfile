FROM apache/spark:3.5.1

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/spark/jars-extra

# JDBC драйверы для Spark:
# - Postgres JDBC
# - ClickHouse JDBC
RUN curl -fL "https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.4/postgresql-42.7.4.jar" \
      -o /opt/spark/jars-extra/postgresql-42.7.4.jar && \
    curl -fL "https://repo1.maven.org/maven2/com/clickhouse/clickhouse-jdbc/0.6.0/clickhouse-jdbc-0.6.0-all.jar" \
      -o /opt/spark/jars-extra/clickhouse-jdbc-0.6.0-all.jar

ENV SPARK_CLASSPATH="/opt/spark/jars-extra/postgresql-42.7.4.jar:/opt/spark/jars-extra/clickhouse-jdbc-0.6.0-all.jar"
ENV PATH="/opt/spark/bin:${PATH}"

WORKDIR /app
COPY spark/jobs/ /app/jobs/
COPY sql/ /app/sql/
COPY data/ /app/data/
COPY spark/submit.sh /usr/local/bin/spark-submit-jdbc
RUN chmod +x /usr/local/bin/spark-submit-jdbc

USER 185

