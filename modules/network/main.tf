resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  # Add timeouts to prevent long waits during destroy
  timeouts {
    create = "5m"
    delete = "5m"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : idx => { cidr = cidr, az = var.azs[idx] } }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${each.key}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

# NAT Gateway(s)
resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${count.index}"
  })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = values(aws_subnet.public)[var.single_nat_gateway ? 0 : count.index].id
  tags = merge(var.tags, {
    Name = "${var.name}-nat-${count.index}"
  })
}

# Private app subnets
resource "aws_subnet" "private_app" {
  for_each          = { for idx, cidr in var.private_app_subnet_cidrs : idx => { cidr = cidr, az = var.azs[idx] } }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, {
    Name                              = "${var.name}-private-app-${each.key}"
    Tier                              = "app"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_route_table" "private_app" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_app_subnet_cidrs)) : 1
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-private-app-rt-${count.index}"
  })
}

resource "aws_route" "private_app_nat" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_app_subnet_cidrs)) : 0
  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private_app" {
  for_each  = aws_subnet.private_app
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_app[
    var.single_nat_gateway ? 0 : tonumber(each.key)
  ].id
}

# Private DB subnets (no internet route by default)
resource "aws_subnet" "private_db" {
  for_each          = { for idx, cidr in var.private_db_subnet_cidrs : idx => { cidr = cidr, az = var.azs[idx] } }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, {
    Name = "${var.name}-private-db-${each.key}"
    Tier = "db"
  })
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-private-db-rt"
  })
}

resource "aws_route_table_association" "private_db" {
  for_each       = aws_subnet.private_db
  route_table_id = aws_route_table.private_db.id
  subnet_id      = each.value.id
}

# Optional VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.name}-flow-logs"
  retention_in_days = var.flow_logs_retention_in_days
  tags              = var.tags
}

resource "aws_iam_role" "flow" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-logs"
  role  = aws_iam_role.flow[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  log_destination      = aws_cloudwatch_log_group.flow[0].arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.flow[0].arn
  vpc_id               = aws_vpc.this.id
}

# VPC cleanup resource to handle remaining dependencies during destroy
resource "null_resource" "vpc_cleanup" {
  triggers = {
    vpc_id     = aws_vpc.this.id
    aws_region = data.aws_region.current.region
  }

  depends_on = [
    aws_vpc.this,
    aws_internet_gateway.this,
    aws_nat_gateway.this,
    aws_subnet.public,
    aws_subnet.private_app,
    aws_subnet.private_db,
    aws_route_table.public,
    aws_route_table.private_app,
    aws_route_table.private_db
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      # Clean up any remaining AWS Load Balancer Controller security groups
      echo "Cleaning up remaining security groups in VPC ${self.triggers.vpc_id}..."
      aws ec2 describe-security-groups \
        --region "${self.triggers.aws_region}" \
        --filters "Name=vpc-id,Values=${self.triggers.vpc_id}" \
        --query "SecurityGroups[?GroupName!='default'].GroupId" \
        --output text | tr '\t' '\n' | while read -r sg_id; do
        if [ -n "$sg_id" ]; then
          echo "Deleting security group: $sg_id"
          aws ec2 delete-security-group --region "${self.triggers.aws_region}" --group-id "$sg_id" || true
        fi
      done

      # Clean up any remaining network interfaces (only unattached ones)
      echo "Cleaning up remaining unattached network interfaces in VPC ${self.triggers.vpc_id}..."
      aws ec2 describe-network-interfaces \
        --region "${self.triggers.aws_region}" \
        --filters "Name=vpc-id,Values=${self.triggers.vpc_id}" "Name=status,Values=available" \
        --query "NetworkInterfaces[].NetworkInterfaceId" \
        --output text | tr '\t' '\n' | while read -r eni_id; do
        if [ -n "$eni_id" ]; then
          echo "Deleting unattached network interface: $eni_id"
          aws ec2 delete-network-interface --region "${self.triggers.aws_region}" --network-interface-id "$eni_id" || true
        fi
      done

      # Clean up any VPC endpoints
      echo "Cleaning up VPC endpoints in VPC ${self.triggers.vpc_id}..."
      aws ec2 describe-vpc-endpoints \
        --region "${self.triggers.aws_region}" \
        --filters "Name=vpc-id,Values=${self.triggers.vpc_id}" \
        --query "VpcEndpoints[].VpcEndpointId" \
        --output text | tr '\t' '\n' | while read -r endpoint_id; do
        if [ -n "$endpoint_id" ]; then
          echo "Deleting VPC endpoint: $endpoint_id"
          aws ec2 delete-vpc-endpoint --region "${self.triggers.aws_region}" --vpc-endpoint-id "$endpoint_id" || true
        fi
      done
    EOF

    on_failure = continue
  }

  lifecycle {
    create_before_destroy = false
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

# Optional NACLs (basic defaults)
resource "aws_network_acl" "public" {
  count  = var.enable_nacls ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-nacl" })
}

resource "aws_network_acl_rule" "public_ingress" {
  count          = var.enable_nacls ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_egress" {
  count          = var.enable_nacls ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "public" {
  for_each       = var.enable_nacls ? aws_subnet.public : {}
  network_acl_id = aws_network_acl.public[0].id
  subnet_id      = each.value.id
}
