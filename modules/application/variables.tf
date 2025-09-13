variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "private_db_subnet_ids" {
  description = "Private subnet IDs for RDS"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for the application"
  type        = string
}

variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3a.micro"
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
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}