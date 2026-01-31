.PHONY: help build up down restart logs shell sql pyspark clean test

# Default target
help:
	@echo "Spark + Iceberg + OSS - Available Commands:"
	@echo ""
	@echo "  make build       - Build Docker image"
	@echo "  make up          - Start the cluster"
	@echo "  make down        - Stop the cluster"
	@echo "  make restart     - Restart the cluster"
	@echo "  make logs        - View cluster logs"
	@echo "  make shell       - Open bash shell in master container"
	@echo "  make sql         - Start Spark SQL shell"
	@echo "  make pyspark     - Start PySpark shell"
	@echo "  make example     - Run PySpark example"
	@echo "  make clean       - Clean up Docker resources"
	@echo "  make test        - Test OSS connectivity"
	@echo ""

# Build Docker image
build:
	@echo "Building Docker image..."
	docker build -t spark-iceberg-oss:latest .

# Start the cluster
up:
	@echo "Starting Spark cluster..."
	docker-compose up -d
	@echo ""
	@echo "Cluster started successfully!"
	@echo "Master UI: http://localhost:8080"
	@echo "Worker UI: http://localhost:8081"

# Stop the cluster
down:
	@echo "Stopping Spark cluster..."
	docker-compose down

# Restart the cluster
restart: down up

# View logs
logs:
	docker-compose logs -f

# Open bash shell in master container
shell:
	docker exec -it spark-iceberg-master bash

# Start Spark SQL shell
sql:
	docker exec -it spark-iceberg-master \
		spark-sql --master spark://spark-master:7077

# Start PySpark shell
pyspark:
	docker exec -it spark-iceberg-master \
		pyspark --master spark://spark-master:7077

# Run PySpark example
example:
	@echo "Running PySpark example..."
	docker exec -it spark-iceberg-master \
		spark-submit --master spark://spark-master:7077 \
		/opt/spark/examples/iceberg_oss_example.py

# Test OSS connectivity
test:
	@echo "Testing OSS connectivity..."
	@if [ -z "$(OSS_BUCKET)" ]; then \
		echo "❌ Error: OSS_BUCKET not set. Please configure .env file"; \
		exit 1; \
	fi
	docker exec -it spark-iceberg-master \
		hadoop fs -ls oss://$(OSS_BUCKET)/ || echo "OSS connection test failed"

# Clean up Docker resources
clean:
	@echo "Cleaning up Docker resources..."
	docker-compose down -v
	docker rmi spark-iceberg-oss:latest || true
	@echo "Cleanup complete!"
