-- Connect as debezium user
CONNECT debezium/dbz@//localhost:1521/ORCLPDB1;

-- Create CUSTOMERS table
CREATE TABLE customers (
    customer_id NUMBER(10) PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    address VARCHAR2(200),
    city VARCHAR2(50),
    state VARCHAR2(50),
    zip_code VARCHAR2(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sequence for customers
CREATE SEQUENCE customers_seq START WITH 1 INCREMENT BY 1;

-- Enable supplemental logging for customers table
ALTER TABLE customers ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- Create PRODUCTS table
CREATE TABLE products (
    product_id NUMBER(10) PRIMARY KEY,
    product_name VARCHAR2(100) NOT NULL,
    description VARCHAR2(500),
    category VARCHAR2(50),
    price NUMBER(10,2) NOT NULL,
    stock_quantity NUMBER(10) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sequence for products
CREATE SEQUENCE products_seq START WITH 1 INCREMENT BY 1;

-- Enable supplemental logging for products table
ALTER TABLE products ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- Create INVOICES table
CREATE TABLE invoices (
    invoice_id NUMBER(10) PRIMARY KEY,
    customer_id NUMBER(10) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    quantity NUMBER(10) NOT NULL,
    unit_price NUMBER(10,2) NOT NULL,
    total_amount NUMBER(10,2) NOT NULL,
    invoice_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR2(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Create sequence for invoices
CREATE SEQUENCE invoices_seq START WITH 1 INCREMENT BY 1;

-- Enable supplemental logging for invoices table
ALTER TABLE invoices ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- Insert sample data into CUSTOMERS
INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, city, state, zip_code)
VALUES (customers_seq.NEXTVAL, 'John', 'Doe', 'john.doe@example.com', '555-0101', '123 Main St', 'New York', 'NY', '10001');

INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, city, state, zip_code)
VALUES (customers_seq.NEXTVAL, 'Jane', 'Smith', 'jane.smith@example.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90001');

INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, city, state, zip_code)
VALUES (customers_seq.NEXTVAL, 'Bob', 'Johnson', 'bob.johnson@example.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', '60601');

-- Insert sample data into PRODUCTS
INSERT INTO products (product_id, product_name, description, category, price, stock_quantity)
VALUES (products_seq.NEXTVAL, 'Laptop Pro 15', 'High-performance laptop with 15-inch display', 'Electronics', 1299.99, 50);

INSERT INTO products (product_id, product_name, description, category, price, stock_quantity)
VALUES (products_seq.NEXTVAL, 'Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 'Accessories', 29.99, 200);

INSERT INTO products (product_id, product_name, description, category, price, stock_quantity)
VALUES (products_seq.NEXTVAL, 'USB-C Hub', '7-in-1 USB-C hub with HDMI and card reader', 'Accessories', 49.99, 150);

INSERT INTO products (product_id, product_name, description, category, price, stock_quantity)
VALUES (products_seq.NEXTVAL, 'Mechanical Keyboard', 'RGB mechanical keyboard with blue switches', 'Accessories', 89.99, 75);

-- Insert sample data into INVOICES
INSERT INTO invoices (invoice_id, customer_id, product_id, quantity, unit_price, total_amount, status)
VALUES (invoices_seq.NEXTVAL, 1, 1, 1, 1299.99, 1299.99, 'COMPLETED');

INSERT INTO invoices (invoice_id, customer_id, product_id, quantity, unit_price, total_amount, status)
VALUES (invoices_seq.NEXTVAL, 1, 2, 2, 29.99, 59.98, 'COMPLETED');

INSERT INTO invoices (invoice_id, customer_id, product_id, quantity, unit_price, total_amount, status)
VALUES (invoices_seq.NEXTVAL, 2, 3, 1, 49.99, 49.99, 'PENDING');

INSERT INTO invoices (invoice_id, customer_id, product_id, quantity, unit_price, total_amount, status)
VALUES (invoices_seq.NEXTVAL, 3, 4, 1, 89.99, 89.99, 'COMPLETED');

COMMIT;

-- Create indexes for better performance
CREATE INDEX idx_customer_email ON customers(email);
CREATE INDEX idx_invoice_customer ON invoices(customer_id);
CREATE INDEX idx_invoice_product ON invoices(product_id);
CREATE INDEX idx_invoice_date ON invoices(invoice_date);

COMMIT;

EXIT;
