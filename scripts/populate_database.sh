#!/bin/bash

# Manual Database Population Script
# Run this from an EC2 instance that has access to your RDS database

set -e  # Exit on any error

echo "=== AWS Three-Tier App - Manual Database Population ==="
echo "Started at: $(date)"

# Check if we're running on an EC2 instance
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not found. This script should run on an EC2 instance with IAM permissions."
    exit 1
fi

# Get instance metadata for region
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region || echo "us-west-2")
echo "Using AWS region: $REGION"

# Variables - you need to set these based on your deployment
echo ""
echo "Please provide the following information from your Terraform outputs:"
read -p "Database endpoint (RDS endpoint): " DB_HOST
read -p "Database name: " DB_NAME
read -p "Database username: " DB_USERNAME
read -p "Secrets Manager secret name for DB password: " SECRET_NAME

if [[ -z "$DB_HOST" || -z "$DB_NAME" || -z "$DB_USERNAME" || -z "$SECRET_NAME" ]]; then
    echo "ERROR: All fields are required!"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  Database Host: $DB_HOST"
echo "  Database Name: $DB_NAME"
echo "  Username: $DB_USERNAME"
echo "  Secret Name: $SECRET_NAME"
echo "  Region: $REGION"

# Retrieve database password from AWS Secrets Manager
echo ""
echo "Retrieving database password from Secrets Manager..."
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --region "$REGION" --query SecretString --output text)

if [[ -z "$DB_PASSWORD" ]]; then
    echo "ERROR: Failed to retrieve database password from Secrets Manager"
    exit 1
fi

echo "✅ Successfully retrieved database password"

# Test database connectivity
echo ""
echo "Testing database connectivity..."
if ! mysqladmin ping -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" --silent; then
    echo "ERROR: Cannot connect to database. Please check:"
    echo "  1. Database endpoint is correct"
    echo "  2. Security groups allow connection from this EC2 instance"
    echo "  3. Database is running and accessible"
    exit 1
fi

echo "✅ Database connectivity confirmed"

# Create tables and insert sample data
echo ""
echo "Creating tables and inserting sample data..."

mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" --default-character-set=utf8 << EOF
USE $DB_NAME;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clear existing data (if any)
DELETE FROM users;
DELETE FROM products;

-- Reset auto-increment
ALTER TABLE users AUTO_INCREMENT = 1;
ALTER TABLE products AUTO_INCREMENT = 1;

-- Insert sample users
INSERT INTO users (id, name, email) VALUES
(1, 'John Doe', 'john@example.com'),
(2, 'Jane Smith', 'jane@example.com'),
(3, 'Mike Johnson', 'mike@example.com'),
(4, 'Sarah Davis', 'sarah@example.com'),
(5, 'David Wilson', 'david@example.com');

-- Insert sample products
INSERT INTO products (id, name, description, price, stock) VALUES
(1, 'Laptop Pro', 'High-performance laptop for professionals', 1299.99, 25),
(2, 'Wireless Mouse', 'Ergonomic wireless mouse with long battery life', 29.99, 150),
(3, 'Mechanical Keyboard', 'Premium mechanical keyboard with RGB lighting', 89.99, 75),
(4, 'USB-C Hub', 'Multi-port USB-C hub with HDMI and Ethernet', 49.99, 100),
(5, 'External Monitor', '27-inch 4K external monitor', 399.99, 40),
(6, 'Webcam HD', 'HD webcam for video conferencing', 79.99, 80),
(7, 'Desk Lamp', 'LED desk lamp with adjustable brightness', 34.99, 120),
(8, 'Coffee Mug', 'Programmer-themed coffee mug', 14.99, 200);

-- Verify data insertion
SELECT 'Users count:' as table_info, COUNT(*) as count FROM users
UNION ALL
SELECT 'Products count:' as table_info, COUNT(*) as count FROM products;

EOF

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully created tables and inserted sample data!"
    echo ""
    echo "Verification - Current data counts:"
    mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "USE $DB_NAME; SELECT 'Users:' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'Products:', COUNT(*) FROM products;"
    echo ""
    echo "🎉 Database population completed successfully!"
    echo "Your application should now display the sample users and products."
else
    echo "❌ Failed to insert sample data"
    exit 1
fi

echo ""
echo "Completed at: $(date)"