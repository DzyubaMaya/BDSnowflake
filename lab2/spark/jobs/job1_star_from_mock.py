import os
from typing import Optional

from pyspark.sql import SparkSession, Window
from pyspark.sql import functions as F
from pyspark.sql import types as T


def env(name: str, default: Optional[str] = None) -> str:
    v = os.getenv(name, default)
    if v is None:
        raise RuntimeError(f"Missing env var: {name}")
    return v


def null_if_blank(column_name: str):
    trimmed = F.trim(F.col(column_name))
    return F.when(trimmed == "", F.lit(None)).otherwise(trimmed)


def main():
    spark = (
        SparkSession.builder.appName("lab2-job1-csv-to-mock-and-star")
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

    pg_url = f"jdbc:postgresql://{pg_host}:{pg_port}/{pg_db}"
    pg_props = {"user": pg_user, "password": pg_pass, "driver": "org.postgresql.Driver"}

    
    csv_path = os.getenv("CSV_PATH", "/app/data/*.csv")

    raw_columns = [
        "id",
        "customer_first_name",
        "customer_last_name",
        "customer_age",
        "customer_email",
        "customer_country",
        "customer_postal_code",
        "customer_pet_type",
        "customer_pet_name",
        "customer_pet_breed",
        "seller_first_name",
        "seller_last_name",
        "seller_email",
        "seller_country",
        "seller_postal_code",
        "product_name",
        "product_category",
        "product_price",
        "product_quantity",
        "sale_date",
        "sale_customer_id",
        "sale_seller_id",
        "sale_product_id",
        "sale_quantity",
        "sale_total_price",
        "store_name",
        "store_location",
        "store_city",
        "store_state",
        "store_country",
        "store_phone",
        "store_email",
        "pet_category",
        "product_weight",
        "product_color",
        "product_size",
        "product_brand",
        "product_material",
        "product_description",
        "product_rating",
        "product_reviews",
        "product_release_date",
        "product_expiry_date",
        "supplier_name",
        "supplier_contact",
        "supplier_email",
        "supplier_phone",
        "supplier_address",
        "supplier_city",
        "supplier_country",
    ]

    raw_schema = T.StructType([T.StructField(c, T.StringType(), True) for c in raw_columns])
    raw_df = (
        spark.read.format("csv")
        .option("header", "true")
        .option("multiLine", "true")
        .option("escape", '"')
        .option("quote", '"')
        .schema(raw_schema)
        .load(csv_path)
    )

    df = raw_df.select(
        F.col("id").cast("int").alias("id"),
        null_if_blank("customer_first_name").alias("customer_first_name"),
        null_if_blank("customer_last_name").alias("customer_last_name"),
        null_if_blank("customer_age").alias("customer_age"),
        null_if_blank("customer_email").alias("customer_email"),
        null_if_blank("customer_country").alias("customer_country"),
        null_if_blank("customer_postal_code").alias("customer_postal_code"),
        null_if_blank("customer_pet_type").alias("customer_pet_type"),
        null_if_blank("customer_pet_name").alias("customer_pet_name"),
        null_if_blank("customer_pet_breed").alias("customer_pet_breed"),
        null_if_blank("seller_first_name").alias("seller_first_name"),
        null_if_blank("seller_last_name").alias("seller_last_name"),
        null_if_blank("seller_email").alias("seller_email"),
        null_if_blank("seller_country").alias("seller_country"),
        null_if_blank("seller_postal_code").alias("seller_postal_code"),
        null_if_blank("product_name").alias("product_name"),
        null_if_blank("product_category").alias("product_category"),
        null_if_blank("product_price").alias("product_price"),
        null_if_blank("product_quantity").alias("product_quantity"),
        null_if_blank("sale_date").alias("sale_date"),
        F.col("sale_customer_id").cast("int").alias("sale_customer_id"),
        F.col("sale_seller_id").cast("int").alias("sale_seller_id"),
        F.col("sale_product_id").cast("int").alias("sale_product_id"),
        null_if_blank("sale_quantity").alias("sale_quantity"),
        null_if_blank("sale_total_price").alias("sale_total_price"),
        null_if_blank("store_name").alias("store_name"),
        null_if_blank("store_location").alias("store_location"),
        null_if_blank("store_city").alias("store_city"),
        null_if_blank("store_state").alias("store_state"),
        null_if_blank("store_country").alias("store_country"),
        null_if_blank("store_phone").alias("store_phone"),
        null_if_blank("store_email").alias("store_email"),
        null_if_blank("pet_category").alias("pet_category"),
        null_if_blank("product_weight").alias("product_weight"),
        null_if_blank("product_color").alias("product_color"),
        null_if_blank("product_size").alias("product_size"),
        null_if_blank("product_brand").alias("product_brand"),
        null_if_blank("product_material").alias("product_material"),
        F.col("product_description").alias("product_description"),
        null_if_blank("product_rating").alias("product_rating"),
        null_if_blank("product_reviews").alias("product_reviews"),
        null_if_blank("product_release_date").alias("product_release_date"),
        null_if_blank("product_expiry_date").alias("product_expiry_date"),
        null_if_blank("supplier_name").alias("supplier_name"),
        null_if_blank("supplier_contact").alias("supplier_contact"),
        null_if_blank("supplier_email").alias("supplier_email"),
        null_if_blank("supplier_phone").alias("supplier_phone"),
        null_if_blank("supplier_address").alias("supplier_address"),
        null_if_blank("supplier_city").alias("supplier_city"),
        null_if_blank("supplier_country").alias("supplier_country"),
    )

   
    jvm = spark._sc._gateway.jvm
    jvm.java.lang.Class.forName("org.postgresql.Driver")
    conn = jvm.java.sql.DriverManager.getConnection(pg_url, pg_user, pg_pass)
    stmt = conn.createStatement()
    stmt.execute("TRUNCATE TABLE public.mock_data RESTART IDENTITY")
    stmt.execute("TRUNCATE TABLE star.fact_sales, star.dim_date, star.dim_customer, star.dim_seller, star.dim_product, star.dim_store, star.dim_supplier CASCADE")
    stmt.close()
    conn.close()

    df.write.jdbc(pg_url, "public.mock_data", mode="append", properties=pg_props)

   
    mock = spark.read.jdbc(pg_url, "public.mock_data", properties=pg_props)

    mock = mock.withColumn(
        "sale_date_parsed",
        F.to_date(F.trim(F.col("sale_date")), "M/d/yyyy"),
    )

    
    # dim_date
    dim_date = (
        mock.select("sale_date_parsed")
        .where(F.col("sale_date_parsed").isNotNull())
        .distinct()
        .withColumn("date_key", F.date_format(F.col("sale_date_parsed"), "yyyyMMdd").cast("int"))
        .withColumn("full_date", F.col("sale_date_parsed"))
        .withColumn("year", F.year("sale_date_parsed").cast("smallint"))
        .withColumn("quarter", F.quarter("sale_date_parsed").cast("smallint"))
        .withColumn("month", F.month("sale_date_parsed").cast("smallint"))
        .withColumn("day", F.dayofmonth("sale_date_parsed").cast("smallint"))
        .select("date_key", "full_date", "year", "quarter", "month", "day")
    )

  
    # dim_customer 
    w_cust = Window.partitionBy(F.col("sale_customer_id")).orderBy(F.col("row_id"))
    dim_customer = (
        mock.where(F.col("sale_customer_id").isNotNull())
        .withColumn("rn", F.row_number().over(w_cust))
        .where(F.col("rn") == 1)
        .select(
            F.col("sale_customer_id").cast("int").alias("customer_id"),
            "customer_first_name",
            "customer_last_name",
            F.trim("customer_age").cast("int").alias("age"),
            "customer_email",
            "customer_country",
            "customer_postal_code",
            "customer_pet_type",
            "customer_pet_name",
            "customer_pet_breed",
        )
        .withColumnRenamed("customer_first_name", "first_name")
        .withColumnRenamed("customer_last_name", "last_name")
        .withColumnRenamed("customer_email", "email")
        .withColumnRenamed("customer_country", "country")
        .withColumnRenamed("customer_postal_code", "postal_code")
        .withColumnRenamed("customer_pet_type", "pet_type")
        .withColumnRenamed("customer_pet_name", "pet_name")
        .withColumnRenamed("customer_pet_breed", "pet_breed")
    )

    # dim_seller
    w_sel = Window.partitionBy(F.col("sale_seller_id")).orderBy(F.col("row_id"))
    dim_seller = (
        mock.where(F.col("sale_seller_id").isNotNull())
        .withColumn("rn", F.row_number().over(w_sel))
        .where(F.col("rn") == 1)
        .select(
            F.col("sale_seller_id").cast("int").alias("seller_id"),
            "seller_first_name",
            "seller_last_name",
            "seller_email",
            "seller_country",
            "seller_postal_code",
        )
        .withColumnRenamed("seller_first_name", "first_name")
        .withColumnRenamed("seller_last_name", "last_name")
        .withColumnRenamed("seller_email", "email")
        .withColumnRenamed("seller_country", "country")
        .withColumnRenamed("seller_postal_code", "postal_code")
    )

    
    w_prod = Window.partitionBy(F.col("sale_product_id")).orderBy(F.col("row_id"))
    dim_product = (
        mock.where(F.col("sale_product_id").isNotNull())
        .withColumn("rn", F.row_number().over(w_prod))
        .where(F.col("rn") == 1)
        .select(
            F.col("sale_product_id").cast("int").alias("product_id"),
            "product_name",
            "product_category",
            "product_brand",
            "product_material",
            "pet_category",
            F.trim("product_price").cast("double").alias("list_price"),
            F.trim("product_weight").cast("double").alias("weight"),
            "product_color",
            "product_size",
            "product_description",
            F.trim("product_rating").cast("double").alias("rating"),
            F.trim("product_reviews").cast("int").alias("reviews"),
            "product_release_date",
            "product_expiry_date",
        )
        .withColumnRenamed("product_category", "category")
        .withColumnRenamed("product_brand", "brand")
        .withColumnRenamed("product_material", "material")
        .withColumnRenamed("product_color", "color")
        .withColumnRenamed("product_size", "size")
        .withColumnRenamed("product_description", "description")
        .withColumnRenamed("product_release_date", "release_date")
        .withColumnRenamed("product_expiry_date", "expiry_date")
    )


    # dim_store 
    store_key_cols = [
        "store_name",
        "store_location",
        "store_city",
        "store_state",
        "store_country",
        "store_phone",
        "store_email",
    ]

   
    store_key_exprs = [F.coalesce(F.col(c), F.lit("N/A")).alias(c) for c in store_key_cols]
    w_store = Window.orderBy(*[F.col(c).asc_nulls_last() for c in store_key_cols])
    dim_store = (
        mock.select(*store_key_exprs)
        .distinct()
        .withColumn("store_id", F.row_number().over(w_store).cast("int"))
        .select(
            "store_id",
            "store_name",
            "store_location",
            "store_city",
            "store_state",
            "store_country",
            "store_phone",
            "store_email",
        )
    )

   
    # dim_supplier
    supplier_key_cols = [
        "supplier_name",
        "supplier_contact",
        "supplier_email",
        "supplier_phone",
        "supplier_address",
        "supplier_city",
        "supplier_country",
    ]
    w_sup = Window.orderBy(*[F.col(c).asc_nulls_last() for c in supplier_key_cols])
    dim_supplier = (
        mock.select(*supplier_key_cols)
        .distinct()
        .withColumn("supplier_id", F.row_number().over(w_sup).cast("int"))
        .select(
            "supplier_id",
            "supplier_name",
            "supplier_contact",
            "supplier_email",
            "supplier_phone",
            "supplier_address",
            "supplier_city",
            "supplier_country",
        )
    )

  
    # fact_sales
    fact = (
        mock.select(
            F.col("row_id").cast("long").alias("source_row_id"),
            "sale_date_parsed",
            F.col("sale_customer_id").cast("int").alias("customer_id"),
            F.col("sale_seller_id").cast("int").alias("seller_id"),
            F.col("sale_product_id").cast("int").alias("product_id"),
            *store_key_exprs,
            *supplier_key_cols,
            F.trim("sale_quantity").cast("double").alias("quantity"),
            F.trim("sale_total_price").cast("double").alias("total_price"),
            F.trim("product_price").cast("double").alias("unit_price"),
        )
        .join(
            dim_date.select("date_key", "full_date"),
            F.col("sale_date_parsed") == F.col("full_date"),
            "left",
        )
        .drop("full_date", "sale_date_parsed")
        .join(dim_store.select("store_id", *store_key_cols), on=store_key_cols, how="left")
        .join(dim_supplier.select("supplier_id", *supplier_key_cols), on=supplier_key_cols, how="left")
        .select(
            "source_row_id",
            "date_key",
            "customer_id",
            "seller_id",
            "product_id",
            "store_id",
            "supplier_id",
            "quantity",
            "total_price",
            "unit_price",
        )
    )

    w_sale = Window.orderBy(F.col("source_row_id"))
    fact = fact.withColumn("sale_key", F.row_number().over(w_sale).cast("long"))

    dim_date.write.jdbc(pg_url, "star.dim_date", mode="append", properties=pg_props)
    dim_customer.write.jdbc(pg_url, "star.dim_customer", mode="append", properties=pg_props)
    dim_seller.write.jdbc(pg_url, "star.dim_seller", mode="append", properties=pg_props)
    dim_product.write.jdbc(pg_url, "star.dim_product", mode="append", properties=pg_props)
    dim_store.write.jdbc(pg_url, "star.dim_store", mode="append", properties=pg_props)
    dim_supplier.write.jdbc(pg_url, "star.dim_supplier", mode="append", properties=pg_props)
    fact.select(
        "sale_key",
        "source_row_id",
        "date_key",
        "customer_id",
        "seller_id",
        "product_id",
        "store_id",
        "supplier_id",
        "quantity",
        "total_price",
        "unit_price",
    ).write.jdbc(pg_url, "star.fact_sales", mode="append", properties=pg_props)

    spark.stop()


if __name__ == "__main__":
    main()
