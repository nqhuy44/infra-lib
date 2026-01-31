# --- Mode Selection ---
variable "create_single_log_group" {
  description = "Whether to create a single log group or multiple log groups"
  type        = bool
  default     = false
}

# --- Single Log Group Configuration ---
variable "log_group_name" {
  description = "Name of the single log group to create"
  type        = string
  default     = null
}

variable "retention_in_days" {
  description = "Retention period in days for the single log group"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.retention_in_days)
    error_message = "Retention period must be one of the valid CloudWatch Log Group retention values."
  }
}

variable "kms_key_id" {
  description = "KMS Key ID for encrypting the single log group"
  type        = string
  default     = null
}

variable "skip_destroy" {
  description = "Set to true if you do not wish the log group to be deleted at destroy time"
  type        = bool
  default     = false
}

# --- Multiple Log Groups Configuration ---
variable "log_groups" {
  description = "Map of log groups to create with their configurations"
  type = map(object({
    retention_in_days = optional(number)
    kms_key_id        = optional(string)
    skip_destroy      = optional(bool)
    tags              = optional(map(string), {})
    log_streams       = optional(list(string), [])
    metric_filters = optional(list(object({
      name    = string
      pattern = string
      metric_transformation = object({
        name          = string
        namespace     = string
        value         = optional(string, "1")
        default_value = optional(string)
        unit          = optional(string, "None")
      })
    })), [])
    subscription_filters = optional(list(object({
      name            = string
      filter_pattern  = optional(string, "")
      destination_arn = string
      role_arn        = optional(string)
      distribution    = optional(string)
    })), [])
  }))
  default = {}
}

# --- Default Values for Multiple Log Groups ---
variable "default_retention_in_days" {
  description = "Default retention period in days for multiple log groups"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.default_retention_in_days)
    error_message = "Default retention period must be one of the valid CloudWatch Log Group retention values."
  }
}

variable "default_kms_key_id" {
  description = "Default KMS Key ID for encrypting multiple log groups"
  type        = string
  default     = null
}

variable "default_skip_destroy" {
  description = "Default skip_destroy setting for multiple log groups"
  type        = bool
  default     = false
}

# --- Log Streams (for single log group) ---
variable "log_streams" {
  description = "List of log stream names to create in the single log group"
  type        = list(string)
  default     = []
}

# --- Metric Filters (for single log group) ---
variable "metric_filters" {
  description = "List of metric filters to create for the single log group"
  type = list(object({
    name    = string
    pattern = string
    metric_transformation = object({
      name          = string
      namespace     = string
      value         = optional(string, "1")
      default_value = optional(string)
      unit          = optional(string, "None")
    })
  }))
  default = []
}

# --- Subscription Filters (for single log group) ---
variable "subscription_filters" {
  description = "List of subscription filters to create for the single log group"
  type = list(object({
    name            = string
    filter_pattern  = optional(string, "")
    destination_arn = string
    role_arn        = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

# --- Common Configuration ---
variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}