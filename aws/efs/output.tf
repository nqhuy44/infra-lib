output "efs_file_system_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "efs_file_system_arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.this.arn
}

output "mount_target_ids" {
  description = "A list of EFS mount target IDs"
  value       = [for mt in aws_efs_mount_target.this : mt.id]
}

output "access_point_id" {
  description = "The ID of the EFS access point"
  value       = try(aws_efs_access_point.this[0].id, null)
}

output "access_point_arn" {
  description = "The ARN of the EFS access point"
  value       = try(aws_efs_access_point.this[0].arn, null)
}

output "replication_configuration_id" {
  description = "The ID of the EFS replication configuration"
  value       = try(aws_efs_replication_configuration.this[0].id, null)
}
