variable "name" {
  description = "Name of the Global Accelerator"
  type        = string
}

variable "enabled" {
  description = "Whether the accelerator is enabled"
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "IP address type for the accelerator. Valid values are IPV4 or DUAL_STACK"
  type        = string
  default     = "IPV4"

  validation {
    condition     = contains(["IPV4", "DUAL_STACK"], var.ip_address_type)
    error_message = "Valid values for ip_address_type are IPV4 or DUAL_STACK."
  }
}

variable "flow_logs_enabled" {
  description = "Whether flow logs are enabled"
  type        = bool
  default     = false
}

variable "flow_logs_s3_bucket" {
  description = "S3 bucket for flow logs"
  type        = string
  default     = null
}

variable "flow_logs_s3_prefix" {
  description = "S3 prefix for flow logs"
  type        = string
  default     = null
}

variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    protocol        = string
    client_affinity = optional(string, "NONE")
    port_ranges = list(object({
      from_port = number
      to_port   = number
    }))
  }))

  validation {
    condition = alltrue([
      for k, v in var.listeners : contains(["TCP", "UDP"], v.protocol)
    ])
    error_message = "Valid values for protocol are TCP or UDP."
  }
}

variable "endpoint_groups" {
  description = "Map of endpoint group configurations"
  type = map(object({
    listener_key            = string
    region                  = string
    health_check_interval   = optional(number)
    health_check_path       = optional(string)
    health_check_port       = optional(number)
    health_check_protocol   = optional(string)
    threshold_count         = optional(number)
    traffic_dial_percentage = optional(number)
    endpoints = list(object({
      endpoint_id                    = string
      weight                         = optional(number)
      client_ip_preservation_enabled = optional(bool)
    }))
  }))
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
