# AWS Three-Tier Architecture Configuration - Production Environment

# Basic Configuration
env_name    = "prod"
region      = "us-east-1"
aws_profile = "rnato35"
project_prefix = "three-tier"

# Network Configuration
vpc_cidr = "10.2.0.0/16"
az_count = 3  # Higher availability with 3 AZs for production

# Network Feature Flags
enable_nat_gateway = true
single_nat_gateway = false  # Multiple NAT gateways for HA in production
enable_flow_logs   = true   # Enabled for production monitoring
enable_nacls       = true   # Enabled for additional security in production

# Resource Tags
tags = {
  Environment = "prod"
  Project     = "three-tier-architecture"
  Owner       = "renato@renatomendoza.io"
  ManagedBy   = "terraform"
}
