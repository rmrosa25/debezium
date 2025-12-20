# Debezium Oracle CDC Example

A working example of Change Data Capture (CDC) using Debezium with Oracle Database, Kafka, and Docker.

## Overview

This project demonstrates real-time data replication from Oracle Database to Kafka using Debezium. It includes:

- **Oracle Database Enterprise Edition 19c** with sample schema (customers, products, invoices)
- **Apache Kafka** for event streaming
- **Debezium Connect** for CDC
- **Kafka UI** for monitoring and visualization
- Test scripts for validating CDC functionality

## Architecture

```
Oracle DB (LogMiner) → Debezium Connect → Kafka Topics → Consumers
```

## Prerequisites

- Docker and Docker Compose
- At least 12GB RAM available for Docker (Oracle Enterprise requires more resources)
- Ports available: 1521 (Oracle), 8080 (Kafka UI), 8083 (Debezium), 9092 (Kafka)
- Oracle Container Registry account (required to pull Oracle Enterprise Edition image)

### Oracle Container Registry Setup

Before starting, you need to authenticate with Oracle Container Registry:

1. Create an account at [https://container-registry.oracle.com](https://container-registry.oracle.com)
2. Accept the license agreement for Oracle Database Enterprise Edition
3. Login to the registry:

```bash
docker login container-registry.oracle.com
# Enter your Oracle account credentials
```

Need to download instantclient_21_12
```bash

cd ./drivers/instantclient
curl -L -o instantclient-basic-linux.x64-21.12.0.0.0dbru.el9.zip \
  -H "Cookie: oraclelicense=accept-securebackup-cookie" \
  https://download.oracle.com/otn_software/linux/instantclient/2112000/el9/instantclient-basic-linux.x64-21.12.0.0.0dbru.el9.zip
unzip instantclient-basic-linux.x64-21.12.0.0.0dbru.el9.zip

```


## Quick Start

### 1. Start the Environment

```bash
docker-compose up -d
```

This will start:
- Zookeeper (port 2181)
- Kafka (port 9092)
- Oracle Database Enterprise Edition (port 1521)
- Debezium Connect (port 8083)
- Kafka UI (port 8080)

**Note:** Oracle Database Enterprise Edition takes 5-10 minutes to initialize on first startup. The container will download ~6GB on first run.

### 2. Wait for Services to be Ready

Check service health:

```bash
# Check all containers are running
docker-compose ps

# Check Debezium Connect is ready
curl http://localhost:8083/

# Check Oracle is ready
docker logs oracle | grep "DATABASE IS READY TO USE"
```

### 3. Configure Oracle for CDC

The Oracle initialization scripts automatically:
- Enable LogMiner and supplemental logging
- Create the `c##dbzuser` user with required privileges
- Create sample tables (customers, products, invoices)
- Insert initial test data

To manually verify the setup:

```bash
# Connect to PDB
docker exec -it oracle sqlplus c##dbzuser/dbz@//localhost:1521/ORCLPDB1

# Connect to CDB as SYS
docker exec -it oracle sqlplus sys/OraclePassword123@//localhost:1521/ORCLCDB as sysdba
```

### 4. Register the Debezium Connector

```bash
./setup-connector.sh
```

This script:
- Waits for Debezium Connect to be ready
- Registers the Oracle connector
- Verifies connector status

### 5. Run CDC Tests

```bash
./test-cdc.sh
```

This script performs:
- INSERT operations (new customer, product, invoice)
- UPDATE operations (customer email, invoice status)
- DELETE operations (product removal)
- Displays CDC events from Kafka topics

### 6. Monitor the System

```bash
./monitor.sh
```

Or visit the Kafka UI at: [http://localhost:8080](http://localhost:8080)

## Database Schema

### Customers Table
```sql
- customer_id (PK)
- first_name, last_name
- email (unique)
- phone, address, city, state, zip_code
- created_at, updated_at
```

### Products Table
```sql
- product_id (PK)
- product_name, description
- category
- price, stock_quantity
- created_at, updated_at
```

### Invoices Table
```sql
- invoice_id (PK)
- customer_id (FK → customers)
- product_id (FK → products)
- quantity, unit_price, total_amount
- invoice_date, status
- created_at, updated_at
```

## Kafka Topics

Debezium creates the following topics:

- `oracle-server.DEBEZIUM.CUSTOMERS` - Customer table changes
- `oracle-server.DEBEZIUM.PRODUCTS` - Product table changes
- `oracle-server.DEBEZIUM.INVOICES` - Invoice table changes
- `schema-changes.oracle` - Schema change history
- `debezium_connect_*` - Debezium internal topics

## Manual Testing

### Insert a New Customer

```bash
docker exec -it oracle sqlplus c##dbzuser/dbz@//localhost:1521/ORCLPDB1

INSERT INTO customers (customer_id, first_name, last_name, email, phone)
VALUES (customers_seq.NEXTVAL, 'Test', 'User', 'test@example.com', '555-9999');
COMMIT;
```

### Consume Kafka Messages

```bash
# View all messages from customers topic
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic oracle-server.DEBEZIUM.CUSTOMERS \
  --from-beginning

# View with pretty JSON formatting
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic oracle-server.DEBEZIUM.CUSTOMERS \
  --from-beginning | jq '.'
```

### Check Connector Status

```bash
# List all connectors
curl http://localhost:8083/connectors

# Get connector details
curl http://localhost:8083/connectors/oracle-connector

# Get connector status
curl http://localhost:8083/connectors/oracle-connector/status | jq '.'

# Restart connector
curl -X POST http://localhost:8083/connectors/oracle-connector/restart
```

## Troubleshooting

### Oracle Database Issues

```bash
# Check Oracle logs
docker logs oracle

# Connect to Oracle CDB as SYS
docker exec -it oracle sqlplus sys/OraclePassword123@//localhost:1521/ORCLCDB as sysdba

# Connect to PDB as SYS
docker exec -it oracle sqlplus sys/OraclePassword123@//localhost:1521/ORCLPDB1 as sysdba

# Check if LogMiner is enabled
SELECT SUPPLEMENTAL_LOG_DATA_MIN FROM V$DATABASE;
```

### Debezium Connector Issues

```bash
# Check Debezium logs
docker logs debezium

# Check connector tasks
curl http://localhost:8083/connectors/oracle-connector/tasks

# Delete and recreate connector
curl -X DELETE http://localhost:8083/connectors/oracle-connector
./setup-connector.sh
```

### Kafka Issues

```bash
# List all topics
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Describe a topic
docker exec kafka kafka-topics --bootstrap-server localhost:29092 \
  --describe --topic oracle-server.DEBEZIUM.CUSTOMERS

# Check consumer groups
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:29092 --list
```

## Cleanup

### Stop All Services

```bash
docker-compose down
```

### Remove All Data (including volumes)

```bash
docker-compose down -v
```

### Remove Oracle Connector

```bash
curl -X DELETE http://localhost:8083/connectors/oracle-connector
```

## Configuration Files

- `docker-compose.yml` - Service definitions
- `oracle-connector.json` - Debezium connector configuration
- `oracle-init/01-setup-logminer.sql` - Oracle LogMiner setup
- `oracle-init/02-create_debezium_user.sql` - Create Debezium User
- `oracle-init/05-create-schema.sql` - Schema and sample data
- `setup-connector.sh` - Connector registration script
- `test-cdc.sh` - CDC testing script
- `monitor.sh` - System monitoring script

## Key Features

- **Snapshot Mode**: Initial snapshot captures existing data
- **LogMiner**: Uses Oracle LogMiner for CDC (no additional licensing required)
- **Supplemental Logging**: Enabled for all columns to capture complete change data
- **JSON Format**: Messages in JSON format for easy consumption
- **Unwrap Transform**: Extracts only the changed data (not full envelope)
- **Foreign Keys**: Demonstrates CDC with related tables

## Performance Considerations

- LogMiner strategy: `online_catalog` for better performance
- Continuous mining: Enabled for real-time CDC
- Single task: Suitable for development; increase for production
- Archive log management: Configured with 10GB recovery area

## Next Steps

1. Implement a consumer application to process CDC events
2. Add data validation and transformation logic
3. Configure monitoring and alerting
4. Tune performance for production workloads
5. Implement error handling and retry logic

## Resources

- [Debezium Oracle Connector Documentation](https://debezium.io/documentation/reference/stable/connectors/oracle.html)
- [Oracle LogMiner Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/sutil/oracle-logminer-utility.html)
- [Kafka Connect Documentation](https://kafka.apache.org/documentation/#connect)