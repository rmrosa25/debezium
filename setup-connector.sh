#!/bin/bash

# Wait for Debezium Connect to be ready
echo "Waiting for Debezium Connect to be ready..."
until curl -f http://localhost:8083/ > /dev/null 2>&1; do
    echo "Debezium Connect is not ready yet. Waiting..."
    sleep 5
done

echo "Debezium Connect is ready!"

# Check if connector already exists
CONNECTOR_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8083/connectors/oracle-connector)

if [ "$CONNECTOR_STATUS" == "200" ]; then
    echo "Connector already exists. Deleting it first..."
    curl -X DELETE http://localhost:8083/connectors/oracle-connector
    sleep 2
fi

# Register the Oracle connector
echo "Registering Oracle connector..."
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @oracle-connector.json

echo ""
echo "Connector registration complete!"

# Check connector status
echo ""
echo "Checking connector status..."
sleep 3
curl -s http://localhost:8083/connectors/oracle-connector/status | jq '.'

echo ""
echo "Setup complete! You can monitor topics at http://localhost:8080"
