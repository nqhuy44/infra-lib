# --- VPC Outputs ---
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# --- Internet Gateway Outputs ---
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# --- Subnet Outputs ---
output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in aws_subnet.main : k => v.id }
}

output "subnet_arns" {
  description = "Map of subnet names to ARNs"
  value       = { for k, v in aws_subnet.main : k => v.arn }
}

output "subnet_cidr_blocks" {
  description = "Map of subnet names to CIDR blocks"
  value       = { for k, v in aws_subnet.main : k => v.cidr_block }
}

output "subnet_availability_zones" {
  description = "Map of subnet names to availability zones"
  value       = { for k, v in aws_subnet.main : k => v.availability_zone }
}

# --- Grouped Subnet Outputs ---
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    for k, v in aws_subnet.main : v.id
    if lookup(var.subnets[k], "type", "") == "public"
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    for k, v in aws_subnet.main : v.id
    if lookup(var.subnets[k], "type", "") == "private"
  ]
}

output "isolated_subnet_ids" {
  description = "List of isolated subnet IDs"
  value = [
    for k, v in aws_subnet.main : v.id
    if lookup(var.subnets[k], "type", "") == "isolated"
  ]
}

# --- All Subnet CIDRs as List ---
output "subnet_cidrs" {
  description = "List of all subnet CIDR blocks"
  value       = [for v in aws_subnet.main : v.cidr_block]
}

# --- NAT Gateway Outputs ---
output "nat_gateway_ids" {
  description = "Map of NAT Gateway names to IDs"
  value       = { for k, v in aws_nat_gateway.main : k => v.id }
}

output "nat_gateway_public_ips" {
  description = "Map of NAT Gateway names to public IPs"
  value       = { for k, v in aws_nat_gateway.main : k => v.public_ip }
}

output "elastic_ip_ids" {
  description = "Map of Elastic IP names to IDs"
  value       = { for k, v in aws_eip.nat : k => v.id }
}

output "elastic_ip_public_ips" {
  description = "Map of Elastic IP names to public IPs"
  value       = { for k, v in aws_eip.nat : k => v.public_ip }
}

# --- Route Table Outputs ---
output "route_table_ids" {
  description = "Map of route table names to IDs"
  value       = { for k, v in aws_route_table.main : k => v.id }
}

# --- Convenience Outputs for ALB/ELB ---
output "public_subnet_ids_by_az" {
  description = "Map of AZ to public subnet IDs"
  value = {
    for az in var.availability_zones : az => [
      for k, v in aws_subnet.main : v.id
      if lookup(var.subnets[k], "type", "") == "public" && v.availability_zone == az
    ]
  }
}

output "private_subnet_ids_by_az" {
  description = "Map of AZ to private subnet IDs"
  value = {
    for az in var.availability_zones : az => [
      for k, v in aws_subnet.main : v.id
      if lookup(var.subnets[k], "type", "") == "private" && v.availability_zone == az
    ]
  }
}
