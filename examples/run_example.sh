#!/bin/bash

# Spark Submit Example Script for Iceberg + OSS
# This script demonstrates how to submit PySpark applications with Iceberg and OSS support

set -e

# Configuration
APP_NAME="iceberg-oss-app"
MASTER_URL=${SPARK_MASTER_URL:-"local[*]"}
OSS_ENDPOINT=${OSS_ENDPOINT:-"oss-cn-hangzhou.aliyuncs.com"}
OSS_ACCESS_KEY_ID=${OSS_ACCESS_KEY_ID:-"YOUR_ACCESS_KEY_ID"}
OSS_ACCESS_KEY_SECRET=${OSS_ACCESS_KEY_SECRET:-"YOUR_ACCESS_KEY_SECRET"}
OSS_BUCKET=${OSS_BUCKET:-"your-bucket"}

# Spark configuration
SPARK_CONF=(
    "--conf spark.sql.catalog.iceberg_catalog=org.apache.iceberg.spark.SparkCatalog"
    "--conf spark.sql.catalog.iceberg_catalog.type=hadoop"
    "--conf spark.sql.catalog.iceberg_catalog.warehouse=oss://${OSS_BUCKET}/warehouse"
    "--conf spark.sql.catalog.iceberg_catalog.io-impl=org.apache.iceberg.hadoop.HadoopFileIO"
    "--conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
    "--conf spark.sql.defaultCatalog=iceberg_catalog"
    "--conf spark.hadoop.fs.oss.endpoint=${OSS_ENDPOINT}"
    "--conf spark.hadoop.fs.oss.accessKeyId=${OSS_ACCESS_KEY_ID}"
    "--conf spark.hadoop.fs.oss.accessKeySecret=${OSS_ACCESS_KEY_SECRET}"
    "--conf spark.hadoop.fs.oss.impl=org.apache.hadoop.fs.aliyun.oss.AliyunOSSFileSystem"
)

echo "=================================="
echo "Submitting Spark Application"
echo "=================================="
echo "App Name: ${APP_NAME}"
echo "Master: ${MASTER_URL}"
echo "OSS Endpoint: ${OSS_ENDPOINT}"
echo "OSS Bucket: ${OSS_BUCKET}"
echo "=================================="

# Submit the application
spark-submit \
    --master ${MASTER_URL} \
    --name ${APP_NAME} \
    --driver-memory 2g \
    --executor-memory 2g \
    "${SPARK_CONF[@]}" \
    iceberg_oss_example.py

echo "=================================="
echo "Application completed!"
echo "=================================="
