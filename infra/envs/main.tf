
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



# Network outputs
output "vpc_id" { value = module.network.vpc_id }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
output "private_app_subnet_ids" { value = module.network.private_app_subnet_ids }
output "private_db_subnet_ids" { value = module.network.private_db_subnet_ids }

