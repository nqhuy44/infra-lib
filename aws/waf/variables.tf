variable "name" {
  description = "Name of the WAF WebACL"
  type        = string
}

variable "description" {
  description = "Description of the WAF WebACL"
  type        = string
  default     = "WAF WebACL"
}

variable "scope" {
  description = "Scope of the WAF WebACL. Valid values are CLOUDFRONT, REGIONAL or GLOBAL"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "Scope must be either CLOUDFRONT, REGIONAL, or GLOBAL."
  }
}

variable "default_action" {
  description = "Default action of the WAF WebACL. Valid values are ALLOW or BLOCK"
  type        = string
  default     = "allow"
  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either allow or block."
  }
}

variable "cloudwatch_metrics_enabled" {
  description = "Whether to enable CloudWatch metrics"
  type        = bool
  default     = true
}

variable "metric_name" {
  description = "Name of the CloudWatch metric"
  type        = string
  default     = null
}

variable "sampled_requests_enabled" {
  description = "Whether to enable sample requests"
  type        = bool
  default     = true
}

variable "managed_rule_groups" {
  description = "List of managed rule groups to include in the WebACL"
  type = list(object({
    name                       = string
    priority                   = number
    override_action            = string
    rule_group_name            = string
    vendor_name                = string
    rule_action_overrides      = optional(map(string), {})
    cloudwatch_metrics_enabled = optional(bool)
    metric_name                = optional(string)
    sampled_requests_enabled   = optional(bool)
  }))
  default = []
}

variable "custom_rules" {
  description = "List of custom rules to include in the WebACL"
  type        = any
  default     = []
}

variable "ip_sets" {
  description = "Map of IP sets to create"
  type        = map(any)
  default     = {}
}

# Add these variables
variable "resource_arns" {
  description = "Map of resource ARNs to associate with the WAF"
  type        = map(string)
  default     = {}
}

variable "depends_on_resources" {
  description = "List of resources that must be created before the WAF associations"
  type        = list(any)
  default     = []
}

variable "token_domains" {
  description = "List of domains for CAPTCHA and Challenge actions"
  type        = list(string)
  default     = []
}

variable "regex_pattern_sets" {
  description = "Map of regex pattern sets to create"
  type = map(object({
    description  = optional(string)
    regex_string = string
  }))
  default = {}
}

variable "tags" {
  description = "Map of tags to assign to the WAF WebACL"
  type        = map(string)
  default     = {}
}

# --- Logging Configuration ---
variable "logging_enabled" {
  description = "Whether to enable WAF logging"
  type        = bool
  default     = false
}

variable "log_destination_arn" {
  description = "ARN of the CloudWatch Log Group for WAF logs"
  type        = string
  default     = null
}

variable "logging_config" {
  description = "WAF logging configuration"
  type = object({
    log_all_requests   = optional(bool, false)
    log_blocked_only   = optional(bool, true)
    log_allowed_only   = optional(bool, false)
    log_counted_only   = optional(bool, false)
    log_captcha_only   = optional(bool, false)
    log_challenge_only = optional(bool, false)
    custom_filters = optional(list(object({
      behavior    = string       # KEEP or DROP
      requirement = string       # MEETS_ALL or MEETS_ANY
      actions     = list(string) # ALLOW, BLOCK, COUNT, CAPTCHA, CHALLENGE
      label_conditions = optional(list(object({
        label_name  = string
        label_scope = optional(string, "LABEL") # LABEL or NAMESPACE
      })), [])
    })), [])
  })
  default = {
    log_blocked_only = true
  }
}

variable "redacted_fields" {
  description = "List of fields to redact in WAF logs"
  type = list(object({
    type = string           # method, query_string, uri_path, single_header
    name = optional(string) # Required for single_header type
  }))
  default = []
}