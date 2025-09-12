# AWS Three-Tier Architecture Configuration - Dev Environment

# Basic Configuration
env_name    = "dev"
region      = "us-east-1"
aws_profile = "rnato35"
project_prefix = "three-tier"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Network Feature Flags
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = false
enable_nacls       = false

# Resource Tags
tags = {
  Environment = "dev"
  Project     = "three-tier-architecture"
  Owner       = "renato@renatomendoza.io"
  ManagedBy   = "terraform"
}
