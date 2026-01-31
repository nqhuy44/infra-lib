output "vpc_peering_connection_id" {
  description = "The ID of the VPC Peering Connection"
  value       = aws_vpc_peering_connection.this.id
}

output "vpc_peering_connection_status" {
  description = "The status of the VPC Peering Connection"
  value       = aws_vpc_peering_connection.this.accept_status
}

output "requester_routes" {
  description = "The route objects created in the requester VPC route tables"
  value       = aws_route.requester_routes
}

output "accepter_routes" {
  description = "The route objects created in the accepter VPC route tables"
  value       = aws_route.accepter_routes
}
