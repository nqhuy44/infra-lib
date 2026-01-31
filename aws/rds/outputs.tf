output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = try(aws_db_instance.this[0].id, "")
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = try(aws_db_instance.this[0].arn, "")
}

output "rds_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = try(aws_db_instance.this[0].endpoint, "")
}

output "rds_instance_status" {
  description = "The status of the RDS instance"
  value       = try(aws_db_instance.this[0].status, "")
}

output "db_subnet_group_id" {
  description = "The ID of the DB subnet group"
  value       = try(aws_db_subnet_group.this[0].id, "")
}

output "db_subnet_group_arn" {
  description = "The ARN of the DB subnet group"
  value       = try(aws_db_subnet_group.this[0].arn, "")
}

output "db_parameter_group_id" {
  description = "The ID of the DB parameter group"
  value       = try(aws_db_parameter_group.this[0].id, "")
}

output "db_parameter_group_arn" {
  description = "The ARN of the DB parameter group"
  value       = try(aws_db_parameter_group.this[0].arn, "")
}

# Aurora specific outputs
output "cluster_id" {
  description = "The ID of the RDS cluster"
  value       = try(aws_rds_cluster.this[0].id, "")
}

output "cluster_arn" {
  description = "The ARN of the RDS cluster"
  value       = try(aws_rds_cluster.this[0].arn, "")
}

output "cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = try(aws_rds_cluster.this[0].endpoint, "")
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the cluster"
  value       = try(aws_rds_cluster.this[0].reader_endpoint, "")
}

output "cluster_port" {
  description = "The port on which the DB accepts connections"
  value       = try(aws_rds_cluster.this[0].port, local.port)
}

# Common outputs
output "db_instance_port" {
  description = "The port on which the DB accepts connections"
  value       = local.port
}

output "db_instance_name" {
  description = "The database name"
  value       = var.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = var.username
  sensitive   = true
}

output "security_group_ids" {
  description = "Security group IDs associated with the database"
  value       = var.vpc_security_group_ids
}
