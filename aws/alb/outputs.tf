output "arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "The canonical hosted zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

output "id" {
  description = "The ID of the ALB"
  value       = aws_lb.this.id
}

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = aws_lb_target_group.this
}

output "http_listeners" {
  description = "Map of HTTP listeners created and their attributes"
  value       = aws_lb_listener.http
}

output "https_listeners" {
  description = "Map of HTTPS listeners created and their attributes"
  value       = aws_lb_listener.https
}

output "listener_rules" {
  description = "Map of listener rules created and their attributes"
  value       = aws_lb_listener_rule.this
}
