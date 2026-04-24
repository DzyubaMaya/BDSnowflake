import os
from typing import Optional

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def env(name: str, default: Optional[str] = None):
    v = os.getenv(name, default)
    if v is None:
        raise RuntimeError(f"Missing env var: {name}")
    return v


def main():
    spark = (
        SparkSession.builder.appName("lab2-job2-reports-to-clickhouse")
        .config("spark.sql.session.timeZone", "UTC")
        .config(
            "spark.driver.extraClassPath",
            "/opt/spark/jars-extra/postgresql-42.7.4.jar:/opt/spark/jars-extra/clickhouse-jdbc-0.6.0-all.jar",
        )
        .config(
            "spark.executor.extraClassPath",
            "/opt/spark/jars-extra/postgresql-42.7.4.jar:/opt/spark/jars-extra/clickhouse-jdbc-0.6.0-all.jar",
        )
        .getOrCreate()
    )

    pg_host = env("POSTGRES_HOST", "db")
    pg_port = env("POSTGRES_PORT", "5432")
    pg_db = env("POSTGRES_DB", "snowflake_lab")
    pg_user = env("POSTGRES_USER", "lab")
    pg_pass = env("POSTGRES_PASSWORD", "lab")

    ch_host = env("CLICKHOUSE_HOST", "clickhouse")
    ch_port = env("CLICKHOUSE_PORT", "8123")
    ch_db = env("CLICKHOUSE_DB", "reports")
    ch_user = env("CLICKHOUSE_USER", "lab")
    ch_pass = env("CLICKHOUSE_PASSWORD", "lab")

    pg_url = f"jdbc:postgresql://{pg_host}:{pg_port}/{pg_db}"
    pg_props = {"user": pg_user, "password": pg_pass, "driver": "org.postgresql.Driver"}

    ch_url = f"jdbc:clickhouse://{ch_host}:{ch_port}/{ch_db}"
    ch_props = {"user": ch_user, "password": ch_pass, "driver": "com.clickhouse.jdbc.ClickHouseDriver"}

    fact = spark.read.jdbc(pg_url, "star.fact_sales", properties=pg_props)
    dim_product = spark.read.jdbc(pg_url, "star.dim_product", properties=pg_props)
    dim_customer = spark.read.jdbc(pg_url, "star.dim_customer", properties=pg_props)
    dim_store = spark.read.jdbc(pg_url, "star.dim_store", properties=pg_props)
    dim_supplier = spark.read.jdbc(pg_url, "star.dim_supplier", properties=pg_props)
    dim_date = spark.read.jdbc(pg_url, "star.dim_date", properties=pg_props)

    na = F.lit("N/A")

    # 1) Витрина по продуктам
    rp = (
        fact.join(dim_product, on="product_id", how="left")
        .groupBy("product_id", "product_name", "category", "brand", "rating", "reviews")
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("quantity").cast("double").alias("total_qty"),
            F.sum("total_price").cast("double").alias("total_revenue"),
            F.avg("unit_price").cast("double").alias("avg_unit_price"),
        )
        .withColumn("product_id", F.coalesce(F.col("product_id"), F.lit(0)).cast("int"))
        .withColumn("product_name", F.coalesce(F.col("product_name"), na))
        .withColumn("category", F.coalesce(F.col("category"), na))
        .withColumn("brand", F.coalesce(F.col("brand"), na))
        .withColumn("rating", F.coalesce(F.col("rating"), F.lit(0.0)).cast("double"))
        .withColumn("reviews", F.coalesce(F.col("reviews"), F.lit(0)).cast("long"))
    )

    # 2) Витрина по клиентам
    rc = (
        fact.join(dim_customer, on="customer_id", how="left")
        .groupBy("customer_id", "first_name", "last_name", "country")
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("quantity").cast("double").alias("total_qty"),
            F.sum("total_price").cast("double").alias("total_spent"),
            F.avg("total_price").cast("double").alias("avg_check"),
        )
        .withColumn("customer_id", F.coalesce(F.col("customer_id"), F.lit(0)).cast("int"))
        .withColumn("first_name", F.coalesce(F.col("first_name"), na))
        .withColumn("last_name", F.coalesce(F.col("last_name"), na))
        .withColumn("country", F.coalesce(F.col("country"), na))
    )

    # 3) Витрина по времени
    rt = (
        fact.join(dim_date.select("date_key", "year", "month"), on="date_key", how="left")
        .groupBy("year", "month")
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("quantity").cast("double").alias("total_qty"),
            F.sum("total_price").cast("double").alias("total_revenue"),
            F.avg("total_price").cast("double").alias("avg_order_value"),
        )
        .where(F.col("year").isNotNull() & F.col("month").isNotNull())
        .orderBy("year", "month")
    )

    # 4) Витрина по магазинам
    rs = (
        fact.join(
            dim_store.select("store_id", "store_name", "store_city", "store_country"),
            on="store_id",
            how="left",
        )
        .withColumn("store_id", F.coalesce(F.col("store_id"), F.lit(0)).cast("int"))
        .withColumn("store_name", F.coalesce(F.col("store_name"), na))
        .withColumn("store_city", F.coalesce(F.col("store_city"), na))
        .withColumn("store_country", F.coalesce(F.col("store_country"), na))
        .groupBy("store_id", "store_name", "store_city", "store_country")
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("quantity").cast("double").alias("total_qty"),
            F.sum("total_price").cast("double").alias("total_revenue"),
            F.avg("total_price").cast("double").alias("avg_check"),
        )
    )

    # 5) Витрина по поставщикам
    rsup = (
        fact.join(
            dim_supplier.select("supplier_id", "supplier_name", "supplier_country"),
            on="supplier_id",
            how="left",
        )
        .withColumn("supplier_id", F.coalesce(F.col("supplier_id"), F.lit(0)).cast("int"))
        .withColumn("supplier_name", F.coalesce(F.col("supplier_name"), na))
        .withColumn("supplier_country", F.coalesce(F.col("supplier_country"), na))
        .groupBy("supplier_id", "supplier_name", "supplier_country")
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("quantity").cast("double").alias("total_qty"),
            F.sum("total_price").cast("double").alias("total_revenue"),
            F.avg("unit_price").cast("double").alias("avg_unit_price"),
        )
    )

    # 6) Качество продукции
    rq = (
        fact.join(dim_product.select("product_id", "product_name", "rating", "reviews"), on="product_id", how="left")
        .groupBy("product_id", "product_name", "rating", "reviews")
        .agg(
            F.sum("quantity").cast("double").alias("total_qty"),
            F.sum("total_price").cast("double").alias("total_revenue"),
        )
        .withColumn("product_id", F.coalesce(F.col("product_id"), F.lit(0)).cast("int"))
        .withColumn("product_name", F.coalesce(F.col("product_name"), na))
        .withColumn("rating", F.coalesce(F.col("rating"), F.lit(0.0)).cast("double"))
        .withColumn("reviews", F.coalesce(F.col("reviews"), F.lit(0)).cast("long"))
    )

    def ch_truncate(table: str) -> None:
        jvm = spark._sc._gateway.jvm
        jvm.java.lang.Class.forName("com.clickhouse.jdbc.ClickHouseDriver")
        conn = jvm.java.sql.DriverManager.getConnection(ch_url, ch_user, ch_pass)
        stmt = conn.createStatement()
        stmt.execute(f"TRUNCATE TABLE {table}")
        stmt.close()
        conn.close()

    tables = [
        "reports.report_products",
        "reports.report_customers",
        "reports.report_time",
        "reports.report_stores",
        "reports.report_suppliers",
        "reports.report_quality",
    ]
    for t in tables:
        ch_truncate(t)

    rp.write.jdbc(ch_url, "reports.report_products", mode="append", properties=ch_props)
    rc.write.jdbc(ch_url, "reports.report_customers", mode="append", properties=ch_props)
    rt.write.jdbc(ch_url, "reports.report_time", mode="append", properties=ch_props)
    rs.write.jdbc(ch_url, "reports.report_stores", mode="append", properties=ch_props)
    rsup.write.jdbc(ch_url, "reports.report_suppliers", mode="append", properties=ch_props)
    rq.write.jdbc(ch_url, "reports.report_quality", mode="append", properties=ch_props)

    spark.stop()


if __name__ == "__main__":
    main()
