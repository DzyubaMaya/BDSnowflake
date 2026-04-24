import os
from typing import Optional

from pyspark.sql import SparkSession, Window
from pyspark.sql import functions as F


def env(name: str, default: Optional[str] = None) -> str:
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


    fact_enriched = (
        fact.alias("f")
        .join(dim_customer.alias("c"), on="customer_id", how="left")
        .join(dim_product.alias("p"), on="product_id", how="left")
        .join(dim_store.alias("st"), on="store_id", how="left")
        .join(dim_supplier.alias("sp"), on="supplier_id", how="left")
        .join(dim_date.select("date_key", "year", "month"), on="date_key", how="left")
        .select(
            F.col("f.sale_key"),
            F.col("f.customer_id"),
            F.col("c.first_name").alias("customer_first_name"),
            F.col("c.last_name").alias("customer_last_name"),
            F.col("c.country").alias("customer_country"),
            F.col("f.product_id"),
            F.col("p.product_name"),
            F.col("p.category").alias("product_category"),
            F.col("p.brand").alias("product_brand"),
            F.col("p.rating").alias("product_rating"),
            F.col("p.reviews").alias("product_reviews"),
            F.col("f.store_id"),
            F.col("st.store_name"),
            F.col("st.store_city"),
            F.col("st.store_country"),
            F.col("f.supplier_id"),
            F.col("sp.supplier_name"),
            F.col("sp.supplier_country"),
            F.col("f.quantity").alias("sale_quantity"),
            F.col("f.total_price").alias("sale_total_price"),
            F.col("f.unit_price").alias("unit_price"),
            F.col("year").alias("sale_year"),
            F.col("month").alias("sale_month"),
        )
        .withColumn("product_name", F.coalesce(F.col("product_name"), na))
        .withColumn("product_category", F.coalesce(F.col("product_category"), na))
        .withColumn("product_brand", F.coalesce(F.col("product_brand"), na))
        .withColumn("customer_first_name", F.coalesce(F.col("customer_first_name"), na))
        .withColumn("customer_last_name", F.coalesce(F.col("customer_last_name"), na))
        .withColumn("customer_country", F.coalesce(F.col("customer_country"), na))
        .withColumn("store_name", F.coalesce(F.col("store_name"), na))
        .withColumn("store_city", F.coalesce(F.col("store_city"), na))
        .withColumn("store_country", F.coalesce(F.col("store_country"), na))
        .withColumn("supplier_name", F.coalesce(F.col("supplier_name"), na))
        .withColumn("supplier_country", F.coalesce(F.col("supplier_country"), na))
        .withColumn("product_rating", F.coalesce(F.col("product_rating"), F.lit(0.0)).cast("double"))
        .withColumn("product_reviews", F.coalesce(F.col("product_reviews"), F.lit(0)).cast("long"))
    )

    product_window = Window.orderBy(F.col("total_revenue").desc(), F.col("product_name").asc())
    customer_window = Window.orderBy(F.col("total_spent").desc(), F.col("customer_id").asc())
    store_window = Window.orderBy(F.col("total_revenue").desc(), F.col("store_name").asc())
    supplier_window = Window.orderBy(F.col("total_revenue").desc(), F.col("supplier_name").asc())
    rating_desc_window = Window.orderBy(
        F.col("product_rating").desc_nulls_last(),
        F.col("product_name").asc(),
    )
    rating_asc_window = Window.orderBy(
        F.col("product_rating").asc_nulls_last(),
        F.col("product_name").asc(),
    )
    reviews_window = Window.orderBy(
        F.col("product_reviews").desc_nulls_last(),
        F.col("product_name").asc(),
    )

    # 1) Витрина по продуктам
    rp = (
        fact_enriched.groupBy(
            "product_id",
            "product_name",
            "product_category",
            "product_brand",
            "product_rating",
            "product_reviews",
        )
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("sale_quantity").cast("double").alias("total_qty"),
            F.sum("sale_total_price").cast("double").alias("total_revenue"),
            F.avg("unit_price").cast("double").alias("avg_unit_price"),
        )
        .withColumn("sales_rank", F.row_number().over(product_window).cast("long"))
        .select(
            F.coalesce(F.col("product_id"), F.lit(0)).cast("int").alias("product_id"),
            "product_name",
            F.coalesce(F.col("product_category"), na).alias("category"),
            F.coalesce(F.col("product_brand"), na).alias("brand"),
            "total_orders",
            "total_qty",
            "total_revenue",
            "avg_unit_price",
            F.coalesce(F.col("product_rating"), F.lit(0.0)).cast("double").alias("rating"),
            F.coalesce(F.col("product_reviews"), F.lit(0)).cast("long").alias("reviews"),
            F.col("sales_rank").cast("long"),
        )
    )

    # 2) Витрина по клиентам
    rc = (
        fact_enriched.groupBy(
            "customer_id",
            "customer_first_name",
            "customer_last_name",
            "customer_country",
        )
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("sale_quantity").cast("double").alias("total_qty"),
            F.sum("sale_total_price").cast("double").alias("total_spent"),
            F.avg("sale_total_price").cast("double").alias("avg_check"),
        )
        .withColumn("customer_rank", F.row_number().over(customer_window).cast("long"))
        .select(
            F.coalesce(F.col("customer_id"), F.lit(0)).cast("int").alias("customer_id"),
            F.coalesce(F.col("customer_first_name"), na).alias("first_name"),
            F.coalesce(F.col("customer_last_name"), na).alias("last_name"),
            F.coalesce(F.col("customer_country"), na).alias("country"),
            "total_orders",
            "total_qty",
            "total_spent",
            "avg_check",
            F.col("customer_rank").cast("long"),
        )
    )

    # 3) Витрина по времени
    rt = (
        fact_enriched.groupBy("sale_year", "sale_month")
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("sale_quantity").cast("double").alias("total_qty"),
            F.sum("sale_total_price").cast("double").alias("total_revenue"),
            F.avg("sale_total_price").cast("double").alias("avg_order_value"),
        )
        .where(F.col("sale_year").isNotNull() & F.col("sale_month").isNotNull())
        .withColumnRenamed("sale_year", "year")
        .withColumnRenamed("sale_month", "month")
        .orderBy("year", "month")
    )

    # 4) Витрина по магазинам
    rs = (
        fact_enriched.groupBy(
            "store_id",
            "store_name",
            "store_city",
            "store_country",
        )
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("sale_quantity").cast("double").alias("total_qty"),
            F.sum("sale_total_price").cast("double").alias("total_revenue"),
            F.avg("sale_total_price").cast("double").alias("avg_check"),
        )
        .withColumn("store_rank", F.row_number().over(store_window).cast("long"))
        .select(
            F.coalesce(F.col("store_id"), F.lit(0)).cast("int").alias("store_id"),
            F.coalesce(F.col("store_name"), na).alias("store_name"),
            F.coalesce(F.col("store_city"), na).alias("store_city"),
            F.coalesce(F.col("store_country"), na).alias("store_country"),
            "total_orders",
            "total_qty",
            "total_revenue",
            "avg_check",
            F.col("store_rank").cast("long"),
        )
    )

    # 5) Витрина по поставщикам
    rsup = (
        fact_enriched.groupBy(
            "supplier_id",
            "supplier_name",
            "supplier_country",
        )
        .agg(
            F.count(F.lit(1)).cast("long").alias("total_orders"),
            F.sum("sale_quantity").cast("double").alias("total_qty"),
            F.sum("sale_total_price").cast("double").alias("total_revenue"),
            F.avg("unit_price").cast("double").alias("avg_unit_price"),
        )
        .withColumn("supplier_rank", F.row_number().over(supplier_window).cast("long"))
        .select(
            F.coalesce(F.col("supplier_id"), F.lit(0)).cast("int").alias("supplier_id"),
            F.coalesce(F.col("supplier_name"), na).alias("supplier_name"),
            F.coalesce(F.col("supplier_country"), na).alias("supplier_country"),
            "total_orders",
            "total_qty",
            "total_revenue",
            "avg_unit_price",
            F.col("supplier_rank").cast("long"),
        )
    )

    # 6) Качество продукции
    rq = (
        fact_enriched.groupBy(
            "product_id",
            "product_name",
            "product_rating",
            "product_reviews",
        )
        .agg(
            F.sum("sale_quantity").cast("double").alias("total_qty"),
            F.sum("sale_total_price").cast("double").alias("total_revenue"),
        )
        .withColumn("rating_rank_desc", F.row_number().over(rating_desc_window).cast("long"))
        .withColumn("rating_rank_asc", F.row_number().over(rating_asc_window).cast("long"))
        .withColumn("reviews_rank", F.row_number().over(reviews_window).cast("long"))
        .select(
            F.coalesce(F.col("product_id"), F.lit(0)).cast("int").alias("product_id"),
            "product_name",
            F.coalesce(F.col("product_rating"), F.lit(0.0)).cast("double").alias("rating"),
            F.coalesce(F.col("product_reviews"), F.lit(0)).cast("long").alias("reviews"),
            "total_qty",
            "total_revenue",
            F.col("rating_rank_desc").cast("long"),
            F.col("rating_rank_asc").cast("long"),
            F.col("reviews_rank").cast("long"),
        )
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
