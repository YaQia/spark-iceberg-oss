#!/usr/bin/env python3
"""
Example PySpark script demonstrating Iceberg table operations with Aliyun OSS storage and JDBC Catalog

This script shows how to:
1. Create an Iceberg table stored in OSS with JDBC Catalog support
2. Insert data into the table
3. Query the table
4. Update data
5. Time travel queries
6. Schema evolution
7. Work with namespaces (namespace feature is now supported with JDBC Catalog)
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp
import os

# Configuration
OSS_ENDPOINT = os.getenv("OSS_ENDPOINT", "oss-cn-hangzhou.aliyuncs.com")
OSS_ACCESS_KEY_ID = os.getenv("OSS_ACCESS_KEY_ID", "")
OSS_ACCESS_KEY_SECRET = os.getenv("OSS_ACCESS_KEY_SECRET", "")
OSS_BUCKET = os.getenv("OSS_BUCKET", "your-bucket")
OSS_WAREHOUSE = f"oss://{OSS_BUCKET}/warehouse"

# Database Configuration for JDBC Catalog
DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_USER = os.getenv("DB_USER", "iceberg_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "iceberg_password")
JDBC_URI = f"jdbc:postgresql://{DB_HOST}:{DB_PORT}/iceberg_catalog"

# Validate credentials
if (
    not OSS_ACCESS_KEY_ID
    or not OSS_ACCESS_KEY_SECRET
    or OSS_ACCESS_KEY_ID == ""
    or OSS_ACCESS_KEY_SECRET == ""
):
    print("❌ Error: OSS credentials not configured")
    print(
        "   Please set OSS_ACCESS_KEY_ID and OSS_ACCESS_KEY_SECRET environment variables"
    )
    exit(1)


def create_spark_session():
    """Create and configure Spark session with Iceberg (JDBC Catalog) and OSS support"""
    spark = (
        SparkSession.builder.appName("Iceberg-JDBC-OSS-Example")
        .config(
            "spark.sql.catalog.iceberg_catalog", "org.apache.iceberg.spark.SparkCatalog"
        )
        .config("spark.sql.catalog.iceberg_catalog.type", "jdbc")
        .config("spark.sql.catalog.iceberg_catalog.warehouse", OSS_WAREHOUSE)
        .config(
            "spark.sql.catalog.iceberg_catalog.io-impl",
            "org.apache.iceberg.hadoop.HadoopFileIO",
        )
        .config("spark.sql.catalog.iceberg_catalog.uri", JDBC_URI)
        .config("spark.sql.catalog.iceberg_catalog.jdbc.user", DB_USER)
        .config("spark.sql.catalog.iceberg_catalog.jdbc.password", DB_PASSWORD)
        .config(
            "spark.sql.catalog.iceberg_catalog.jdbc.driver", "org.postgresql.Driver"
        )
        .config(
            "spark.sql.extensions",
            "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
        )
        .config("spark.sql.defaultCatalog", "iceberg_catalog")
        .config("spark.hadoop.fs.oss.endpoint", OSS_ENDPOINT)
        .config("spark.hadoop.fs.oss.accessKeyId", OSS_ACCESS_KEY_ID)
        .config("spark.hadoop.fs.oss.accessKeySecret", OSS_ACCESS_KEY_SECRET)
        .config(
            "spark.hadoop.fs.oss.impl",
            "org.apache.hadoop.fs.aliyun.oss.AliyunOSSFileSystem",
        )
        .getOrCreate()
    )

    return spark


def main():
    """Main function demonstrating Iceberg operations with JDBC Catalog"""

    print("=" * 80)
    print("Spark + Iceberg (JDBC Catalog) + Aliyun OSS Example")
    print("=" * 80)

    # Create Spark session
    spark = create_spark_session()

    print("\n1. Creating Iceberg namespace...")
    try:
        spark.sql("CREATE NAMESPACE IF NOT EXISTS demo")
        print("✓ Namespace 'demo' created")
    except Exception as e:
        print(f"Note: {e}")

    spark.sql("USE demo")

    print("\n2. Creating Iceberg table...")
    spark.sql("""
        CREATE TABLE IF NOT EXISTS users (
            id BIGINT,
            name STRING,
            age INT,
            email STRING,
            created_at TIMESTAMP
        ) USING iceberg
        PARTITIONED BY (days(created_at))
    """)
    print("✓ Table 'users' created")

    print("\n3. Inserting sample data...")
    spark.sql("""
        INSERT INTO users VALUES
        (1, 'Alice', 30, 'alice@example.com', current_timestamp()),
        (2, 'Bob', 25, 'bob@example.com', current_timestamp()),
        (3, 'Charlie', 35, 'charlie@example.com', current_timestamp())
    """)
    print("✓ Data inserted")

    print("\n4. Querying data...")
    df = spark.sql("SELECT * FROM users ORDER BY id")
    df.show()

    print("\n5. Updating data...")
    spark.sql("UPDATE users SET age = 31 WHERE name = 'Alice'")
    print("✓ Data updated")

    print("\n6. Querying updated data...")
    df = spark.sql("SELECT * FROM users WHERE name = 'Alice'")
    df.show()

    print("\n7. Getting table snapshots (for time travel)...")
    try:
        snapshots = spark.sql("SELECT * FROM iceberg_catalog.demo.users.snapshots")
        snapshots.show(truncate=False)
    except Exception as e:
        print(f"Note: Snapshots query - {e}")

    print("\n8. Schema evolution - adding new column...")
    spark.sql("ALTER TABLE users ADD COLUMN city STRING")
    print("✓ Column 'city' added")

    print("\n9. Inserting data with new schema...")
    spark.sql("""
        INSERT INTO users VALUES
        (4, 'David', 28, 'david@example.com', current_timestamp(), 'Beijing')
    """)
    print("✓ Data with new schema inserted")

    print("\n10. Final query showing all data...")
    df = spark.sql("SELECT * FROM users ORDER BY id")
    df.show()

    print("\n11. Table metadata...")
    try:
        metadata = spark.sql("SELECT * FROM iceberg_catalog.demo.users.files")
        print(f"Total data files: {metadata.count()}")
    except Exception as e:
        print(f"Note: Files query - {e}")

    print("\n12. Listing namespaces (JDBC Catalog feature)...")
    try:
        namespaces = spark.sql("SHOW NAMESPACES")
        namespaces.show()
    except Exception as e:
        print(f"Note: {e}")

    print("\n" + "=" * 80)
    print("✓ Example completed successfully!")
    print(f"Data stored in: {OSS_WAREHOUSE}")
    print(f"Metadata stored in: PostgreSQL ({JDBC_URI})")
    print("=" * 80)

    spark.stop()


if __name__ == "__main__":
    main()
