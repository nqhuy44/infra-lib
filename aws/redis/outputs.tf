output "replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Address of the primary endpoint (for non-cluster mode)"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Address of the reader endpoint (for non-cluster mode)"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address (for cluster mode)"
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
}

output "member_clusters" {
  description = "List of node IDs in the cluster"
  value       = aws_elasticache_replication_group.this.member_clusters
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.this.port
}

output "parameter_group_name" {
  description = "Name of the parameter group used"
  value       = aws_elasticache_replication_group.this.parameter_group_name
}

output "subnet_group_name" {
  description = "Name of the subnet group used"
  value       = aws_elasticache_replication_group.this.subnet_group_name
}
