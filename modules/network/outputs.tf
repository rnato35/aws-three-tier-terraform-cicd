output "vpc_id" { value = aws_vpc.this.id }
// For resources created with for_each, convert the map to a list of values before splatting
output "public_subnet_ids" { value = values(aws_subnet.public)[*].id }
output "private_app_subnet_ids" { value = values(aws_subnet.private_app)[*].id }
output "private_db_subnet_ids" { value = values(aws_subnet.private_db)[*].id }
output "igw_id" { value = aws_internet_gateway.this.id }
output "nat_gateway_ids" { value = try(aws_nat_gateway.this[*].id, []) }
