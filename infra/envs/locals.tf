locals {
  # Normalize env name for resource naming
  env = var.env_name

  tags = merge(var.tags, {
    Environment = local.env
    ManagedBy   = "terraform"
  })

  # Compute AZs
  _available_azs = data.aws_availability_zones.available.names
  azs            = coalesce(var.azs, slice(local._available_azs, 0, var.az_count))

  # Auto-derive subnet CIDRs if not provided: split VPC into /20 blocks:
  #  - public: first N
  #  - private app: next N
  #  - private db: next N
  _subnet_pool         = [for i in range(0, length(local.azs) * 3) : cidrsubnet(var.vpc_cidr, 4, i)]
  _public_default      = slice(local._subnet_pool, 0, length(local.azs))
  _private_app_default = slice(local._subnet_pool, length(local.azs), length(local.azs) * 2)
  _private_db_default  = slice(local._subnet_pool, length(local.azs) * 2, length(local.azs) * 3)

  public_subnet_cidrs      = coalesce(var.public_subnet_cidrs, local._public_default)
  private_app_subnet_cidrs = coalesce(var.private_app_subnet_cidrs, local._private_app_default)
  private_db_subnet_cidrs  = coalesce(var.private_db_subnet_cidrs, local._private_db_default)
}
