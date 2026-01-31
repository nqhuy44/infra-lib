output "flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_arn" {
  description = "The ARN of the Flow Log"
  value       = try(aws_flow_log.this[0].arn, null)
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by the Flow Log"
  value       = try(aws_iam_role.flow_log[0].arn, null)
}

output "iam_role_name" {
  description = "The name of the IAM role used by the Flow Log"
  value       = try(aws_iam_role.flow_log[0].name, null)
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.flow_log[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.flow_log[0].arn, null)
}

output "s3_bucket_id" {
  description = "The ID (name) of the S3 bucket"
  value       = try(aws_s3_bucket.flow_log[0].id, null)
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = try(aws_s3_bucket.flow_log[0].arn, null)
}
