output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnets (ALB, NAT gateways)."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private subnets for ECS tasks."
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Isolated subnets for the database."
  value       = aws_subnet.data[*].id
}

output "data_subnet_cidrs" {
  description = "CIDRs of the data subnets."
  value       = aws_subnet.data[*].cidr_block
}

output "nat_public_ips" {
  description = "Elastic IPs of the NAT gateways (useful for third-party allow-lists)."
  value       = aws_eip.nat[*].public_ip
}
