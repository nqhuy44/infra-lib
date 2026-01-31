variable "name" {
  description = "The name of the CloudTrail trail"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for CloudTrail logs (must exist)"
  type        = string
}

variable "include_global_service_events" {
  description = "Whether the trail is publishing events from global services"
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Whether the trail is created in all regions"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Whether log file integrity validation is enabled"
  type        = bool
  default     = true
}

variable "is_organization_trail" {
  description = "Whether the trail is an AWS Organizations trail"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ARN to encrypt CloudTrail logs"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Enable logging for the trail"
  type        = bool
  default     = true
}

variable "event_selectors" {
  description = "List of event selector blocks"
  type = list(object({
    read_write_type           = optional(string)
    include_management_events = optional(bool)
    data_resources = optional(list(object({
      type   = string
      values = list(string)
    })))
  }))
  default = []
}

variable "cloud_watch_logs_group_arn" {
  description = "The ARN of the CloudWatch Logs group to which CloudTrail logs will be delivered."
  type        = string
  default     = null
}

variable "cloud_watch_logs_role_arn" {
  description = "The ARN of the IAM role for CloudWatch Logs delivery."
  type        = string
  default     = null
}

variable "advanced_event_selectors" {
  description = "List of advanced event selector blocks for fine-grained event logging."
  type = list(object({
    name = string
    field_selectors = list(object({
      field           = string
      equals          = optional(list(string))
      starts_with     = optional(list(string))
      ends_with       = optional(list(string))
      not_equals      = optional(list(string))
      not_starts_with = optional(list(string))
      not_ends_with   = optional(list(string))
    }))
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}