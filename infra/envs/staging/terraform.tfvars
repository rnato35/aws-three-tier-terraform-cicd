# AWS Three-Tier Architecture Configuration - Staging Environment

# Basic Configuration
env_name    = "staging"
region      = "us-east-1"
aws_profile = "rnato35"
project_prefix = "three-tier"

# Network Configuration
vpc_cidr = "10.1.0.0/16"
az_count = 2

# Network Feature Flags
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = true  # Enabled for staging monitoring
enable_nacls       = false

# Resource Tags
tags = {
  Environment = "staging"
  Project     = "three-tier-architecture"
  Owner       = "renato@renatomendoza.io"
  ManagedBy   = "terraform"
}
