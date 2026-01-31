output "id" {
  description = "The ID of the instance"
  value       = try(aws_instance.this[0].id, null)
}

output "arn" {
  description = "The ARN of the instance"
  value       = try(aws_instance.this[0].arn, null)
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value       = try(aws_instance.this[0].private_ip, null)
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable"
  value       = try(aws_instance.this[0].public_ip, null)
}

output "primary_network_interface_id" {
  description = "The ID of the instance's primary network interface"
  value       = try(aws_instance.this[0].primary_network_interface_id, null)
}

output "instance" {
  description = "The instance object with all attributes"
  value       = try(aws_instance.this[0], null)
}

output "security_groups" {
  description = "List of associated security groups of the instance"
  value       = try(aws_instance.this[0].security_groups, null)
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = try(aws_instance.this[0].id, null)
}

output "has_gpu" {
  description = "Whether the instance has a GPU attached"
  value       = var.gpu_enabled
}

output "gpu_info" {
  description = "GPU information for the instance type (when available)"
  value = var.gpu_enabled ? {
    instance_type = var.instance_type
    # This is a simplified example - in production you might query AWS for actual GPU count/memory
    estimated_gpu_count = (
      contains(["g5.xlarge", "g4dn.xlarge", "p3.2xlarge"], var.instance_type) ? 1 :
      contains(["g5.2xlarge", "g4dn.2xlarge", "p3.8xlarge"], var.instance_type) ? 1 :
      contains(["g5.4xlarge", "g4dn.4xlarge", "p3.16xlarge"], var.instance_type) ? 2 :
      contains(["g5.8xlarge", "g4dn.8xlarge"], var.instance_type) ? 4 :
      contains(["g5.16xlarge", "g4dn.16xlarge"], var.instance_type) ? 8 :
      "unknown"
    )
  } : null
}

output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider"
  value       = try(aws_instance.this[0].tags_all, {})
}
