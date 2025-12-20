#!/bin/bash

echo "=== Debezium CDC Test Script ==="
echo ""

# Function to execute SQL in Oracle
execute_sql() {
    docker exec -i oracle sqlplus -S debezium/dbz@//localhost:1521/ORCLPDB1 <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
$1
EXIT;
EOF
}

# Function to consume the last N Kafka messages from a topic
consume_topic() {
    local topic=$1
    local count=${2:-5}
    echo "Consuming last $count messages from topic: $topic"
    docker exec kafka kafka-console-consumer \
        --bootstrap-server localhost:29092 \
        --topic "$topic" \
        --from-beginning \
        --timeout-ms 5000 2>/dev/null | tail -n "$count" | jq '.' 2>/dev/null || echo "No messages or invalid JSON"
    echo ""
}

# Test 1: Insert a new customer
echo "Test 1: Inserting a new customer..."
execute_sql "INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, city, state, zip_code) VALUES (customers_seq.NEXTVAL, 'Alice', 'Williams', 'alice.williams@example.com', '555-0104', '321 Elm St', 'Boston', 'MA', '02101');
COMMIT;"
echo "Customer inserted. Waiting for CDC event..."
sleep 5
consume_topic "oracle-server.DEBEZIUM.CUSTOMERS" 1

# Test 2: Update a customer
echo "Test 2: Updating customer email..."
execute_sql "UPDATE customers SET email = 'alice.w@example.com', updated_at = CURRENT_TIMESTAMP WHERE email = 'alice.williams@example.com'; 
COMMIT;"
echo "Customer updated. Waiting for CDC event..."
sleep 5
consume_topic "oracle-server.DEBEZIUM.CUSTOMERS" 1

# Test 3: Insert a new product
echo "Test 3: Inserting a new product..."
execute_sql "INSERT INTO products (product_id, product_name, description, category, price, stock_quantity) VALUES (products_seq.NEXTVAL, 'Monitor 27inch', '4K UHD monitor with HDR support', 'Electronics', 399.99, 30); 
COMMIT;"
echo "Product inserted. Waiting for CDC event..."
sleep 5
consume_topic "oracle-server.DEBEZIUM.PRODUCTS" 1

# Test 4: Create a new invoice
echo "Test 4: Creating a new invoice..."
execute_sql "INSERT INTO invoices (invoice_id, customer_id, product_id, quantity, unit_price, total_amount, status) VALUES (invoices_seq.NEXTVAL, 1, (select max(product_id) from products), 1, 399.99, 399.99, 'PENDING'); 
COMMIT;"
echo "Invoice created. Waiting for CDC event..."
sleep 5
consume_topic "oracle-server.DEBEZIUM.INVOICES" 1

# Test 5: Update invoice status
echo "Test 5: Updating invoice status..."
execute_sql "UPDATE invoices SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP WHERE status = 'PENDING' AND ROWNUM = 1; 
COMMIT;"
echo "Invoice updated. Waiting for CDC event..."
sleep 5
consume_topic "oracle-server.DEBEZIUM.INVOICES" 1

# Test 6: Delete a product (soft delete simulation)
echo "Test 6: Deleting a product..."
execute_sql "DELETE FROM products WHERE product_name = 'Monitor 27inch'; 
COMMIT;"
echo "Product deleted. Waiting for CDC event..."
sleep 5
consume_topic "oracle-server.DEBEZIUM.PRODUCTS" 1

echo ""
echo "=== Test Summary ==="
echo "All tests completed. Check the output above for CDC events."
echo ""
echo "To view all topics, run:"
echo "  docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list"
echo ""
echo "To consume from a specific topic, run:"
echo "  docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic <topic-name> --from-beginning"
echo ""
echo "Or visit Kafka UI at: http://localhost:8080"
