#!/bin/bash

# Monitor Spark cluster status and metrics

set -e

echo "================================================================"
echo "  Spark Cluster Monitoring"
echo "================================================================"
echo ""

# Check if containers are running
if ! docker ps | grep -q spark-iceberg-master; then
    echo "❌ Spark cluster is not running"
    echo "   Run 'docker-compose up -d' to start the cluster"
    exit 1
fi

# Container status
echo "Container Status:"
echo "─────────────────"
docker ps --filter "name=spark-iceberg" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Resource Usage:"
echo "─────────────────"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
    $(docker ps --filter "name=spark-iceberg" -q)

echo ""
echo "Web UIs:"
echo "─────────────────"
echo "Spark Master:  http://localhost:8080"
echo "Spark Worker:  http://localhost:8081"
echo "Spark App UI:  http://localhost:4040 (when application is running)"

echo ""
echo "Worker Information:"
echo "─────────────────"
docker exec spark-iceberg-master curl -s http://spark-master:8080/json/ | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(f'Alive Workers: {len(data.get(\"workers\", []))}'); print(f'Cores: {data.get(\"cores\", 0)}'); print(f'Memory: {data.get(\"memory\", 0)} MB')" 2>/dev/null || \
    echo "Could not fetch worker information"

echo ""
echo "Recent Logs (last 20 lines):"
echo "─────────────────"
docker-compose logs --tail=20 --no-color

echo ""
echo "================================================================"
echo "For live logs: docker-compose logs -f"
echo "================================================================"
