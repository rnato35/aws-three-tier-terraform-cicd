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


