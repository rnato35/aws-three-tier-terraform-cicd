#!/bin/bash

# Log everything for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script execution at $(date)"

# Update system and install packages
echo "Installing packages..."
yum update -y

# Install Amazon Linux Extras for newer MySQL client
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 

# Install packages
yum install -y httpd php php-mysqli mariadb

# Ensure SSM agent is installed and running (usually pre-installed on Amazon Linux 2)
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

echo "SSM Agent status:"
systemctl status amazon-ssm-agent --no-pager

# Create health check endpoint immediately
echo "Creating health check endpoint..."
mkdir -p /var/www/html
echo "OK" > /var/www/html/health.html
chown apache:apache /var/www/html/health.html

# Start and enable httpd
echo "Starting Apache..."
systemctl start httpd
systemctl enable httpd

# Verify Apache is running
systemctl status httpd

echo "Health check endpoint created and Apache started. Proceeding with database setup..."

# Retrieve database password from AWS Secrets Manager
echo "Retrieving database password from Secrets Manager..."
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "${secrets_manager_secret_name}" --region "${aws_region}" --query SecretString --output text)

# Wait for RDS to be ready (with timeout)
echo "Waiting for database to be ready..."
timeout=300  # 5 minutes timeout
counter=0
while ! mysqladmin ping -h"${db_host}" -u"${db_username}" -p"$DB_PASSWORD" --silent; do
    if [ $counter -ge $timeout ]; then
        echo "Database connection timeout after $timeout seconds"
        # Continue anyway - we'll show an error in the web app
        break
    fi
    echo "Database not ready yet, waiting... ($counter/$timeout)"
    sleep 10
    counter=$((counter + 10))
done

echo "Database is ready, creating tables and sample data..."

# Create the database and sample data with explicit charset
mysql -h "${db_host}" -u "${db_username}" -p"$DB_PASSWORD" --default-character-set=utf8 << EOF
USE ${db_name};

-- Drop tables if they exist to ensure clean setup
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS products;

-- Create users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users
INSERT INTO users (name, email) VALUES
('John Doe', 'john@example.com'),
('Jane Smith', 'jane@example.com'),
('Mike Johnson', 'mike@example.com'),
('Sarah Davis', 'sarah@example.com'),
('David Wilson', 'david@example.com');

-- Insert sample products
INSERT INTO products (name, description, price, stock) VALUES
('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 25),
('Wireless Mouse', 'Ergonomic wireless mouse with long battery life', 29.99, 150),
('Mechanical Keyboard', 'Premium mechanical keyboard with RGB lighting', 89.99, 75),
('USB-C Hub', 'Multi-port USB-C hub with HDMI and Ethernet', 49.99, 100),
('External Monitor', '27-inch 4K external monitor', 399.99, 40),
('Webcam HD', 'HD webcam for video conferencing', 79.99, 80),
('Desk Lamp', 'LED desk lamp with adjustable brightness', 34.99, 120),
('Coffee Mug', 'Programmer-themed coffee mug', 14.99, 200);

-- Verify data was inserted
SELECT 'Users inserted:' as info, COUNT(*) as count FROM users;
SELECT 'Products inserted:' as info, COUNT(*) as count FROM products;

EOF

# Create the PHP application
cat > /var/www/html/index.php << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Three-Tier Architecture Demo - ${domain}</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            margin: 0;
            font-size: 1.2em;
            opacity: 0.9;
        }
        .content {
            padding: 40px;
        }
        .section {
            margin-bottom: 40px;
        }
        .section h2 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .info-card h3 {
            margin-top: 0;
            color: #2c3e50;
        }
        .table-container {
            overflow-x: auto;
            margin: 20px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        th {
            background: #3498db;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #eee;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .status {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .architecture-diagram {
            text-align: center;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
            margin: 20px 0;
        }
        .tier {
            display: inline-block;
            margin: 10px;
            padding: 15px 25px;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            border-top: 4px solid #3498db;
        }
        .tier.web { border-top-color: #e74c3c; }
        .tier.app { border-top-color: #f39c12; }
        .tier.db { border-top-color: #27ae60; }
        .footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏗️ Three-Tier Architecture Demo</h1>
            <p>Hosted on: <strong>${domain}</strong></p>
            <p>AWS + Terraform + Auto Scaling + RDS</p>
        </div>
        
        <div class="content">
            <?php
            $servername = "${db_host}";
            $username = "${db_username}";
            $dbname = "${db_name}";
            
            // Retrieve password from AWS Secrets Manager
            $secretName = "${secrets_manager_secret_name}";
            $region = "${aws_region}";
            $cmd = "aws secretsmanager get-secret-value --secret-id '$secretName' --region '$region' --query SecretString --output text 2>/dev/null";
            $password = trim(shell_exec($cmd));
            
            $conn = new mysqli($servername, $username, $password, $dbname);
            
            // Set charset to UTF-8 to avoid charset issues
            if (!$conn->connect_error) {
                $conn->set_charset("utf8");
            }
            
            if ($conn->connect_error) {
                echo '<div class="section">';
                echo '<h2>❌ Database Connection</h2>';
                echo '<span class="status error">Connection failed: ' . $conn->connect_error . '</span>';
                echo '</div>';
            } else {
                echo '<div class="section">';
                echo '<h2>✅ Architecture Status</h2>';
                echo '<div class="info-grid">';
                
                echo '<div class="info-card">';
                echo '<h3>🌐 Web Tier</h3>';
                echo '<p><strong>Status:</strong> <span class="status success">Active</span></p>';
                echo '<p><strong>Server:</strong> ' . gethostname() . '</p>';
                echo '<p><strong>IP:</strong> ' . $_SERVER['SERVER_ADDR'] . '</p>';
                echo '</div>';
                
                echo '<div class="info-card">';
                echo '<h3>💾 Database Tier</h3>';
                echo '<p><strong>Status:</strong> <span class="status success">Connected</span></p>';
                echo '<p><strong>Host:</strong> ' . $servername . '</p>';
                echo '<p><strong>Database:</strong> ' . $dbname . '</p>';
                echo '</div>';
                
                echo '<div class="info-card">';
                echo '<h3>🔧 Infrastructure</h3>';
                echo '<p><strong>Load Balancer:</strong> <span class="status success">Active</span></p>';
                echo '<p><strong>Auto Scaling:</strong> <span class="status success">Enabled</span></p>';
                echo '<p><strong>SSL:</strong> <span class="status success">Encrypted</span></p>';
                echo '</div>';
                
                echo '</div>';
                echo '</div>';
                
                // Architecture Diagram
                echo '<div class="section">';
                echo '<h2>🏛️ Architecture Overview</h2>';
                echo '<div class="architecture-diagram">';
                echo '<div class="tier web">Web Tier<br><small>ALB + Auto Scaling</small></div>';
                echo '<div class="tier app">App Tier<br><small>EC2 Instances</small></div>';
                echo '<div class="tier db">DB Tier<br><small>RDS MySQL</small></div>';
                echo '</div>';
                echo '</div>';
                
                // Display Users
                echo '<div class="section">';
                echo '<h2>👥 Sample Users Data</h2>';
                $result = $conn->query("SELECT * FROM users ORDER BY created_at DESC");
                if ($result->num_rows > 0) {
                    echo '<div class="table-container">';
                    echo '<table>';
                    echo '<tr><th>ID</th><th>Name</th><th>Email</th><th>Created At</th></tr>';
                    while($row = $result->fetch_assoc()) {
                        echo '<tr>';
                        echo '<td>' . $row["id"] . '</td>';
                        echo '<td>' . $row["name"] . '</td>';
                        echo '<td>' . $row["email"] . '</td>';
                        echo '<td>' . $row["created_at"] . '</td>';
                        echo '</tr>';
                    }
                    echo '</table>';
                    echo '</div>';
                }
                echo '</div>';
                
                // Display Products
                echo '<div class="section">';
                echo '<h2>📦 Sample Products Data</h2>';
                $result = $conn->query("SELECT * FROM products ORDER BY name");
                if ($result->num_rows > 0) {
                    echo '<div class="table-container">';
                    echo '<table>';
                    echo '<tr><th>ID</th><th>Product</th><th>Description</th><th>Price</th><th>Stock</th></tr>';
                    while($row = $result->fetch_assoc()) {
                        echo '<tr>';
                        echo '<td>' . $row["id"] . '</td>';
                        echo '<td><strong>' . $row["name"] . '</strong></td>';
                        echo '<td>' . $row["description"] . '</td>';
                        echo '<td>$' . number_format($row["price"], 2) . '</td>';
                        echo '<td>' . $row["stock"] . '</td>';
                        echo '</tr>';
                    }
                    echo '</table>';
                    echo '</div>';
                }
                echo '</div>';
            }
            $conn->close();
            ?>
        </div>
        
        <div class="footer">
            <p>🚀 Deployed with Terraform on AWS | Three-Tier Architecture Demo</p>
            <p><small>Web Server: <?php echo gethostname(); ?> | Load Balanced & Auto Scaled</small></p>
        </div>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.php
chmod 644 /var/www/html/index.php

# Remove default index.html and welcome.conf to avoid conflicts
rm -f /var/www/html/index.html
rm -f /etc/httpd/conf.d/welcome.conf

# Restart httpd to ensure everything is loaded
echo "Restarting Apache with new configuration..."
systemctl restart httpd

# Verify the health check endpoint still exists
echo "OK" > /var/www/html/health.html
chown apache:apache /var/www/html/health.html

# Test local connectivity
echo "Testing local web server..."
curl -s http://localhost/health.html || echo "Health check failed"
curl -s http://localhost/ | head -10 || echo "Main page test failed"

echo "User data script completed at $(date)"
echo "Files in /var/www/html:"
ls -la /var/www/html/