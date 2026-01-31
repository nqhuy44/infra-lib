variable "project_id" {
  description = "The ID of the project where this VPC will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network being created"
  type        = string
}

variable "routing_mode" {
  type        = string
  default     = "GLOBAL"
  description = "The network routing mode (default 'GLOBAL')"
}

variable "subnets" {
  type = list(object({
    subnet_name           = string
    subnet_ip             = string
    subnet_region         = string
    subnet_private_access = optional(bool, false)
    description           = optional(string)
    secondary_ip_range = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    log_config = optional(object({
      aggregation_interval = optional(string)
      flow_sampling        = optional(number)
      metadata             = optional(string)
      metadata_fields      = optional(list(string))
      filter_expr          = optional(string)
    }))
  }))
  description = "The list of subnets being created"
  default     = []
}

variable "mtu" {
  type        = number
  description = "The network MTU (If set to 0, meaning it is not set)"
  default     = 0
}
