variable "region" {
  description = "AWS region for providers"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile to use for authentication (leave empty for default profile)"
  type        = string
  default     = ""
}

variable "env_name" {
  description = "Short environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

# Prefix for naming sample resources (sanitized to [a-z0-9-])
variable "project_prefix" {
  description = "Project prefix used in sample resource names"
  type        = string
  default     = "one-click"
}

# Network inputs
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}
variable "az_count" {
  description = "Number of AZs to use when azs not provided"
  type        = number
  default     = 2
}
variable "azs" {
  description = "Optional list of AZs to use"
  type        = list(string)
  default     = null
}
variable "public_subnet_cidrs" {
  description = "Optional public subnet CIDRs (per AZ)"
  type        = list(string)
  default     = null
}
variable "private_app_subnet_cidrs" {
  description = "Optional private app subnet CIDRs (per AZ)"
  type        = list(string)
  default     = null
}
variable "private_db_subnet_cidrs" {
  description = "Optional private db subnet CIDRs (per AZ)"
  type        = list(string)
  default     = null
}

# Feature flags
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}
variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ"
  type        = bool
  default     = true
}
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}
variable "enable_nacls" {
  description = "Enable Network ACLs"
  type        = bool
  default     = false
}

# ===================================
# Application Configuration
# ===================================

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g., renatomendoza.io)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "example"
}

# ===================================
# Web Tier Configuration
# ===================================

variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "web_min_capacity" {
  description = "Minimum number of web instances"
  type        = number
  default     = 1
}

variable "web_max_capacity" {
  description = "Maximum number of web instances"
  type        = number
  default     = 3
}

variable "web_desired_capacity" {
  description = "Desired number of web instances"
  type        = number
  default     = 2
}

# ===================================
# Database Configuration
# ===================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "sampledb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password (use GitHub Secrets in CI/CD)"
  type        = string
  sensitive   = true
  default     = null
}


