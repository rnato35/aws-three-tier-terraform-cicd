# AWS Three-Tier Architecture Configuration - Production Environment

# Basic Configuration
env_name       = "prod"
region         = "us-east-1"
aws_profile    = "rnato35"
project_prefix = "three-tier"

# Network Configuration
vpc_cidr = "10.2.0.0/16"
az_count = 3 # Higher availability with 3 AZs for production

# Network Feature Flags
enable_nat_gateway = true
single_nat_gateway = false # Multiple NAT gateways for HA in production
enable_flow_logs   = true  # Enabled for production monitoring
enable_nacls       = true  # Enabled for additional security in production

# Application Configuration
certificate_arn = "arn:aws:acm:us-east-1:825982271549:certificate/97a22ccc-77bf-4d7d-81ae-c6afc27fe7d9"
domain_name     = "renatomendoza.io"
subdomain       = "demo"

# Web Tier Configuration (Production-grade)
web_instance_type    = "t3.small"
web_min_capacity     = 2
web_max_capacity     = 6
web_desired_capacity = 3

# Database Configuration (Production-grade)
db_instance_class    = "db.t3.small"
db_allocated_storage = 50
db_engine_version    = "8.0"
db_name              = "sampledb"
db_username          = "admin"
db_password          = "ProductionPassword123!"

# Resource Tags
tags = {
  Environment = "prod"
  Project     = "three-tier-architecture"
  Owner       = "renato@renatomendoza.io"
  ManagedBy   = "terraform"
}
