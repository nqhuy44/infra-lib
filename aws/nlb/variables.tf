variable "name" {
  description = "Name of the NLB"
  type        = string
}

variable "internal" {
  description = "Whether the NLB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs to place the NLB in"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the NLB will be placed"
  type        = string
}

variable "cross_zone_enabled" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection for the NLB"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = ""
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    name                 = optional(string)
    port                 = number
    protocol             = string
    target_port          = optional(number)
    instance_ids         = list(string)
    deregistration_delay = optional(number)
    preserve_client_ip   = optional(bool)
    proxy_protocol_v2    = optional(bool)
    health_check = object({
      interval            = optional(number)
      path                = optional(string)
      port                = optional(string)
      protocol            = optional(string)
      timeout             = optional(number)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
      matcher             = optional(string, "200-299")
    })
  }))
}

variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port             = number
    protocol         = string
    target_group_key = string
    certificate_arn  = optional(string)
    ssl_policy       = optional(string)
    alpn_policy      = optional(string)
  }))
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the NLB"
  type        = list(string)
  default     = []
}

output "load_balancer_arn" {
  description = "The ARN of the Network Load Balancer"
  value       = aws_lb.this.arn
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
