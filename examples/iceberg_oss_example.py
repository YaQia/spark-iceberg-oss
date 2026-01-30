#!/usr/bin/env python3
"""
Example PySpark script demonstrating Iceberg table operations with Aliyun OSS storage

This script shows how to:
1. Create an Iceberg table stored in OSS
2. Insert data into the table
3. Query the table
4. Update data
5. Time travel queries
6. Schema evolution
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp
import os

# Configuration
OSS_ENDPOINT = os.getenv('OSS_ENDPOINT', 'oss-cn-hangzhou.aliyuncs.com')
OSS_ACCESS_KEY_ID = os.getenv('OSS_ACCESS_KEY_ID', '')
OSS_ACCESS_KEY_SECRET = os.getenv('OSS_ACCESS_KEY_SECRET', '')
OSS_BUCKET = os.getenv('OSS_BUCKET', 'your-bucket')
OSS_WAREHOUSE = f"oss://{OSS_BUCKET}/warehouse"

# Validate credentials
if not OSS_ACCESS_KEY_ID or not OSS_ACCESS_KEY_SECRET or OSS_ACCESS_KEY_ID == '' or OSS_ACCESS_KEY_SECRET == '':
    print("❌ Error: OSS credentials not configured")
    print("   Please set OSS_ACCESS_KEY_ID and OSS_ACCESS_KEY_SECRET environment variables")
    exit(1)

def create_spark_session():
    """Create and configure Spark session with Iceberg and OSS support"""
    spark = SparkSession.builder \
        .appName("Iceberg-OSS-Example") \
        .config("spark.sql.catalog.iceberg_catalog", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.iceberg_catalog.type", "hadoop") \
        .config("spark.sql.catalog.iceberg_catalog.warehouse", OSS_WAREHOUSE) \
        .config("spark.sql.catalog.iceberg_catalog.io-impl", "org.apache.iceberg.hadoop.HadoopFileIO") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.defaultCatalog", "iceberg_catalog") \
        .config("spark.hadoop.fs.oss.endpoint", OSS_ENDPOINT) \
        .config("spark.hadoop.fs.oss.accessKeyId", OSS_ACCESS_KEY_ID) \
        .config("spark.hadoop.fs.oss.accessKeySecret", OSS_ACCESS_KEY_SECRET) \
        .config("spark.hadoop.fs.oss.impl", "org.apache.hadoop.fs.aliyun.oss.AliyunOSSFileSystem") \
        .getOrCreate()
    
    return spark

def main():
    """Main function demonstrating Iceberg operations"""
    
    print("=" * 80)
    print("Spark + Iceberg + Aliyun OSS Example")
    print("=" * 80)
    
    # Create Spark session
    spark = create_spark_session()
    
    print("\n1. Creating Iceberg database...")
    spark.sql("CREATE DATABASE IF NOT EXISTS demo")
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
    
    print("\n3. Inserting sample data...")
    spark.sql("""
        INSERT INTO users VALUES
        (1, 'Alice', 30, 'alice@example.com', current_timestamp()),
        (2, 'Bob', 25, 'bob@example.com', current_timestamp()),
        (3, 'Charlie', 35, 'charlie@example.com', current_timestamp())
    """)
    
    print("\n4. Querying data...")
    df = spark.sql("SELECT * FROM users ORDER BY id")
    df.show()
    
    print("\n5. Updating data...")
    spark.sql("UPDATE users SET age = 31 WHERE name = 'Alice'")
    
    print("\n6. Querying updated data...")
    df = spark.sql("SELECT * FROM users WHERE name = 'Alice'")
    df.show()
    
    print("\n7. Getting table snapshots (for time travel)...")
    snapshots = spark.sql("SELECT * FROM iceberg_catalog.demo.users.snapshots")
    snapshots.show(truncate=False)
    
    print("\n8. Schema evolution - adding new column...")
    spark.sql("ALTER TABLE users ADD COLUMN city STRING")
    
    print("\n9. Inserting data with new schema...")
    spark.sql("""
        INSERT INTO users VALUES
        (4, 'David', 28, 'david@example.com', current_timestamp(), 'Beijing')
    """)
    
    print("\n10. Final query showing all data...")
    df = spark.sql("SELECT * FROM users ORDER BY id")
    df.show()
    
    print("\n11. Table metadata...")
    metadata = spark.sql("SELECT * FROM iceberg_catalog.demo.users.files")
    print(f"Total data files: {metadata.count()}")
    
    print("\n" + "=" * 80)
    print("Example completed successfully!")
    print(f"Data stored in: {OSS_WAREHOUSE}")
    print("=" * 80)
    
    spark.stop()

if __name__ == "__main__":
    main()
