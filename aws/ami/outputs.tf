output "dlm_policy_id" {
  description = "ID of the DLM lifecycle policy"
  value       = one(aws_dlm_lifecycle_policy.this[*].id)
}

output "ami_now_id" {
  description = "ID of the one-off AMI if created"
  value       = one(aws_ami_from_instance.now[*].id)
}

output "manual_ami_ids" {
  description = "IDs of manually triggered AMIs keyed by trigger token"
  value       = { for k, v in aws_ami_from_instance.manual : k => v.id }
}


