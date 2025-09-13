# AWS Three-Tier Architecture Configuration - Staging Environment

# Basic Configuration
env_name       = "staging"
region         = "us-east-1"
aws_profile    = "rnato35"
project_prefix = "three-tier"

# Network Configuration
vpc_cidr = "10.1.0.0/16"
az_count = 2

# Network Feature Flags
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = true # Enabled for staging monitoring
enable_nacls       = false

# Application Configuration
certificate_arn = "arn:aws:acm:us-east-1:825982271549:certificate/97a22ccc-77bf-4d7d-81ae-c6afc27fe7d9"
domain_name     = "renatomendoza.io"
subdomain       = "staging-demo"

# Web Tier Configuration
web_instance_type    = "t3.small"
web_min_capacity     = 2
web_max_capacity     = 4
web_desired_capacity = 2

# Database Configuration
db_instance_class    = "db.t3.small"
db_allocated_storage = 20
db_engine_version    = "8.0"
db_name              = "sampledb"
db_username          = "admin"
db_password          = "StagingPassword123!"

# Resource Tags
tags = {
  Environment = "staging"
  Project     = "three-tier-architecture"
  Owner       = "renato@renatomendoza.io"
  ManagedBy   = "terraform"
}
