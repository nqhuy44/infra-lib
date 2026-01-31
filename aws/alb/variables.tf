variable "name" {
  description = "The name of the ALB"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the ALB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the ALB will be deployed"
  type        = list(string)
  default     = []
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the ALB"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "Whether to drop invalid header fields"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Whether to enable HTTP/2 for the ALB"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "The idle timeout value, in seconds"
  type        = number
  default     = 60
}

variable "ip_address_type" {
  description = "The IP address type for the ALB. Valid values are ipv4 or dualstack"
  type        = string
  default     = "ipv4"
}

variable "subnet_mapping" {
  description = "A list of subnet mapping blocks describing the subnets to attach to the ALB"
  type        = any
  default     = {}
}

# Access Logs
variable "access_logs_enabled" {
  description = "Whether to enable access logs"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 bucket prefix for access logs"
  type        = string
  default     = ""
}

# WAF
# variable "waf_web_acl_arn" {
#   description = "ARN of the WAF WebACL to associate with the ALB (optional)"
#   type        = string
#   default     = null
# }

# Target Groups
variable "target_groups" {
  description = "A map of target group configurations"
  type        = any
  default     = {}
}

# Listeners
variable "listeners" {
  description = "A map of listener configurations"
  type        = any
  default     = {}
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
