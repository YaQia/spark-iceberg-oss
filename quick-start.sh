#!/bin/bash

# Quick start script for Spark + Iceberg + OSS
# This script helps you set up and run the environment quickly

set -e

echo "================================================================"
echo "  Spark + Iceberg + Aliyun OSS Quick Start"
echo "================================================================"
echo ""

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
	echo "❌ Error: Docker is not installed."
	echo "Please install Docker from https://docs.docker.com/get-docker/"
	exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &>/dev/null; then
	echo "❌ Error: Docker Compose is not installed."
	echo "Please install Docker Compose from https://docs.docker.com/compose/install/"
	exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
	echo "⚠️  .env file not found. Creating from template..."
	cp .env.template .env
	echo ""
	echo "⚠️  IMPORTANT: Please edit .env file with your configuration"
	echo "   1. Aliyun OSS Credentials:"
	echo "      - OSS_ACCESS_KEY_ID"
	echo "      - OSS_ACCESS_KEY_SECRET"
	echo "      - OSS_ENDPOINT (for your region)"
	echo "      - OSS_BUCKET (your bucket name)"
	echo ""
	echo "   2. PostgreSQL Database Configuration (for JDBC Catalog):"
	echo "      - DB_HOST (default: postgres)"
	echo "      - DB_PORT (default: 5432)"
	echo "      - DB_USER (default: iceberg_user)"
	echo "      - DB_PASSWORD (default: iceberg_password)"
	echo ""
	read -p "Press Enter after you've configured .env file..."
fi

# Check if credentials are still default values
if grep -q "YOUR_ACCESS_KEY_ID" .env; then
	echo "❌ Error: Please configure your OSS credentials in .env file"
	exit 1
fi

echo "✅ Configuration file found"
echo ""

# Build Docker image
echo "📦 Building Docker image..."
docker build -t spark-iceberg-oss:latest .

if [ $? -eq 0 ]; then
	echo "✅ Docker image built successfully"
else
	echo "❌ Failed to build Docker image"
	exit 1
fi

echo ""

# Start services
echo "🚀 Starting Spark cluster..."
docker compose up -d

if [ $? -eq 0 ]; then
	echo "✅ Spark cluster started successfully"
else
	echo "❌ Failed to start Spark cluster"
	exit 1
fi

echo ""
echo "================================================================"
echo "  Spark Cluster is Ready!"
echo "================================================================"
echo ""
echo "Web UIs:"
echo "  • Spark Master:  http://localhost:8080"
echo "  • Spark Worker:  http://localhost:8081"
echo "  • Spark App UI:  http://localhost:4040 (when app is running)"
echo "  • PostgreSQL:    localhost:5432 (for JDBC Catalog)"
echo ""
echo "Quick Commands:"
echo ""
echo "1. Run PySpark example:"
echo "   docker exec -it spark-iceberg-master \\"
echo "     spark-submit --master spark://spark-master:7077 \\"
echo "     /opt/spark/examples/iceberg_oss_example.py"
echo ""
echo "2. Start Spark SQL shell:"
echo "   docker exec -it spark-iceberg-master \\"
echo "     spark-sql --master spark://spark-master:7077"
echo ""
echo "3. Start PySpark shell:"
echo "   docker exec -it spark-iceberg-master \\"
echo "     pyspark --master spark://spark-master:7077"
echo ""
echo "4. View logs:"
echo "   docker compose logs -f"
echo ""
echo "5. Stop cluster:"
echo "   docker compose down"
echo ""
echo "================================================================"
