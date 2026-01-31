output "secret_id" {
  description = "ID of the secret"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.this.name
}

output "secret_version_id" {
  description = "ID of the secret version (null if no content provided)"
  value       = length(aws_secretsmanager_secret_version.this) > 0 ? aws_secretsmanager_secret_version.this[0].version_id : null
}

output "secret_version_arn" {
  description = "ARN of the secret version (null if no content provided)"
  value       = length(aws_secretsmanager_secret_version.this) > 0 ? aws_secretsmanager_secret_version.this[0].arn : null
}

output "has_secret_version" {
  description = "Whether the secret has a version with content"
  value       = length(aws_secretsmanager_secret_version.this) > 0
}

output "secret_type" {
  description = "Type of secret content"
  value = length(var.secret_key_value) > 0 ? "key-value" : (
    var.secret_string != null ? "string" : (
      var.secret_binary != null ? "binary" : "empty"
    )
  )
}

output "secret_schema" {
  description = "List of keys in the secret schema (empty if not key-value type)"
  value       = keys(var.secret_key_value)
}

output "secret_schema_count" {
  description = "Number of keys in the secret schema"
  value       = length(var.secret_key_value)
}

output "environment" {
  description = "Environment tag value"
  value       = var.environment
}

output "uses_kms_encryption" {
  description = "Whether the secret uses custom KMS encryption"
  value       = var.kms_key_id != null
}

output "rotation_enabled" {
  description = "Whether rotation is enabled"
  value       = length(aws_secretsmanager_secret_rotation.this) > 0
}