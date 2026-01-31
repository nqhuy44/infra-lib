output "arn" {
  description = "ARN of the NLB"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "DNS name of the NLB"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Route 53 zone ID of the NLB"
  value       = aws_lb.this.zone_id
}

output "id" {
  description = "ID of the NLB"
  value       = aws_lb.this.id
}

output "target_groups" {
  description = "Map of target groups created"
  value = {
    for k, tg in aws_lb_target_group.this : k => {
      arn  = tg.arn
      id   = tg.id
      name = tg.name
    }
  }
}

output "listeners" {
  description = "Map of listeners created"
  value = {
    for k, listener in aws_lb_listener.this : k => {
      arn  = listener.arn
      id   = listener.id
      port = listener.port
    }
  }
}
