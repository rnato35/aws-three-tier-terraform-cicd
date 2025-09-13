# AWS Three-Tier Architecture Configuration - Dev Environment

# Basic Configuration
env_name       = "dev"
region         = "us-east-1"
aws_profile    = "" # Leave empty for CI/CD, set locally if needed
project_prefix = "three-tier"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Network Feature Flags
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = false
enable_nacls       = false

# Application Configuration
certificate_arn = "arn:aws:acm:us-east-1:825982271549:certificate/52f508c8-eff0-4fb5-ac5f-51e9cca94ed7"
domain_name     = "renatomendoza.io"
subdomain       = "dev-demo"

# Web Tier Configuration
web_instance_type    = "t3.micro"
web_min_capacity     = 1
web_max_capacity     = 3
web_desired_capacity = 2

# Database Configuration
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_engine_version    = "8.0"
db_name              = "sampledb"
db_username          = "admin"
# db_password - Set via GitHub Secrets (TF_VAR_db_password) in CI/CD

# Resource Tags
tags = {
  Environment = "dev"
  Project     = "three-tier-architecture"
  Owner       = "renato@renatomendoza.io"
  ManagedBy   = "terraform"
}
