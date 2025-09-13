
module "network" {
  source = "../../modules/network"

  name                     = "${var.project_prefix}-${local.env}"
  cidr_block               = var.vpc_cidr
  azs                      = local.azs
  public_subnet_cidrs      = local.public_subnet_cidrs
  private_app_subnet_cidrs = local.private_app_subnet_cidrs
  private_db_subnet_cidrs  = local.private_db_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_flow_logs   = var.enable_flow_logs
  enable_nacls       = var.enable_nacls
  tags               = local.tags
}

module "application" {
  source = "../../modules/application"

  name        = "${var.project_prefix}-${local.env}"
  environment = var.env_name

  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_app_subnet_ids = module.network.private_app_subnet_ids
  private_db_subnet_ids  = module.network.private_db_subnet_ids

  certificate_arn = var.certificate_arn
  domain_name     = var.domain_name
  subdomain       = var.subdomain

  web_instance_type    = var.web_instance_type
  web_min_capacity     = var.web_min_capacity
  web_max_capacity     = var.web_max_capacity
  web_desired_capacity = var.web_desired_capacity

  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version    = var.db_engine_version
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password

  tags = local.tags

  depends_on = [module.network]
}

# Network outputs
output "vpc_id" { value = module.network.vpc_id }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
output "private_app_subnet_ids" { value = module.network.private_app_subnet_ids }
output "private_db_subnet_ids" { value = module.network.private_db_subnet_ids }

# Application outputs
output "application_url" {
  description = "URL of the deployed application"
  value       = module.application.application_url
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.application.load_balancer_dns_name
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.application.database_endpoint
  sensitive   = true
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.application.auto_scaling_group_name
}

output "full_domain" {
  description = "Full domain name of the application"
  value       = module.application.full_domain
}
