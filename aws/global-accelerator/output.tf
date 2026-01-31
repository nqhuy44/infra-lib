output "accelerator_id" {
  description = "ID of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.this.id
}

output "accelerator_arn" {
  description = "ARN of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.this.arn
}

output "dns_name" {
  description = "DNS name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.this.dns_name
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.this.hosted_zone_id
}

output "ip_sets" {
  description = "IP address set of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.this.ip_sets
}

output "listeners" {
  description = "Map of listeners created"
  value = {
    for k, listener in aws_globalaccelerator_listener.this : k => {
      id  = listener.id
      arn = listener.id
    }
  }
}

output "endpoint_groups" {
  description = "Map of endpoint groups created"
  value = {
    for k, eg in aws_globalaccelerator_endpoint_group.this : k => {
      id = eg.id
    }
  }
}
