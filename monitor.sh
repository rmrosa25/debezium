#!/bin/bash

echo "=== Debezium Monitoring Script ==="
echo ""

# Check Debezium Connect status
echo "1. Debezium Connect Status:"
curl -s http://localhost:8083/ | jq '.' 2>/dev/null || echo "Debezium Connect not available"
echo ""

# List all connectors
echo "2. Registered Connectors:"
curl -s http://localhost:8083/connectors | jq '.' 2>/dev/null || echo "No connectors found"
echo ""

# Check Oracle connector status
echo "3. Oracle Connector Status:"
curl -s http://localhost:8083/connectors/oracle-connector/status | jq '.' 2>/dev/null || echo "Oracle connector not found"
echo ""

# List Kafka topics
echo "4. Kafka Topics:"
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list 2>/dev/null | grep -E "oracle-server|DEBEZIUM" || echo "No Debezium topics found"
echo ""

# Show topic details
echo "5. Topic Message Counts:"
for topic in $(docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list 2>/dev/null | grep "oracle-server"); do
    count=$(docker exec kafka kafka-run-class kafka.tools.GetOffsetShell \
        --broker-list localhost:29092 \
        --topic "$topic" 2>/dev/null | awk -F ":" '{sum += $3} END {print sum}')
    echo "  $topic: $count messages"
done
echo ""

echo "=== Quick Access URLs ==="
echo "Kafka UI: http://localhost:8080"
echo "Debezium Connect API: http://localhost:8083"
echo ""
