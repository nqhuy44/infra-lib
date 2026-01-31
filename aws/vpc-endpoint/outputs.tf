output "endpoint_id" {
  description = "Endpoint ID"
  value       = aws_vpc_endpoint.this.id
}

output "endpoint_arn" {
  description = "Endpoint ARN"
  value       = aws_vpc_endpoint.this.arn
}

output "endpoint_cidr_blocks" {
  description = "The list of CIDR blocks for the exposed AWS service. Applicable for endpoints of type Gateway"
  value       = try(aws_vpc_endpoint.this.cidr_blocks, null)
}

output "endpoint_dns_entry" {
  description = "The DNS entries for the VPC Endpoint. Applicable for endpoints of type Interface"
  value       = try(aws_vpc_endpoint.this.dns_entry, null)
}

output "endpoint_network_interface_ids" {
  description = "One or more network interfaces for the VPC Endpoint. Applicable for endpoints of type Interface"
  value       = try(aws_vpc_endpoint.this.network_interface_ids, null)
}


################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(aws_security_group.this[0].arn, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = try(aws_security_group.this[0].id, null)
}
