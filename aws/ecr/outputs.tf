output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "repository_registry_id" {
  description = "The registry ID of the ECR repository"
  value       = aws_ecr_repository.this.registry_id
}

# Removed public repository outputs as we're focusing on private ECR repositories only
