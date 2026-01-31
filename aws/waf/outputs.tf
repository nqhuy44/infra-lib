output "web_acl_id" {
  description = "ID of the WAF WebACL"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "ARN of the WAF WebACL"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "Name of the WAF WebACL"
  value       = aws_wafv2_web_acl.this.name
}

output "web_acl_capacity" {
  description = "Capacity of the WAF WebACL"
  value       = aws_wafv2_web_acl.this.capacity
}

output "ip_sets" {
  description = "Map of IP sets created"
  value       = aws_wafv2_ip_set.this
}

output "arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.arn
}

output "id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.id
}
