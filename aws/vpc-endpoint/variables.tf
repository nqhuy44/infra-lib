
variable "name" {
  description = "Name of the VPC Endpoint"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region where the VPC Endpoint belongs to"
  type        = string
  default     = ""
}


variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used"
  type        = string
  default     = null
}

variable "endpoint_service" {
  description = "Endpoint Service with the type of string"
  type        = string
  default     = ""
}

variable "endpoint_service_type" {
  description = "Endpoint Service Type with the type of string"
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "Default security group IDs to associate with the VPC endpoints"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Default subnets IDs to associate with the VPC endpoints"
  type        = list(string)
  default     = []
}

variable "subnet_configurations" {
  description = "A map of interface endpoints containing their properties and configurations"
  type = list(object({
    ipv4      = string
    ipv6      = string
    subnet_id = string
  }))
  default = []
}

variable "dns_options_list" {
  description = "A map of DNS Option"
  type = list(object({
    dns_record_ip_type                             = string   # Valid values are: ipv4, dualstack, service-defined, ipv6
    private_dns_only_for_inbound_resolver_endpoint = bool
  }))
  default = [{
    dns_record_ip_type = "ipv4"
    private_dns_only_for_inbound_resolver_endpoint = false
  }]
}


variable "route_table_ids" {
  description = "Default route table IDs to associate with the VPC endpoints"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Define maximum timeout for creating, updating, and deleting VPC endpoint resources"
  type        = map(string)
  default     = {}
}

variable "private_dns_enabled" {
  description = "Ensures that requests that use the public service endpoints, such as requests made through an AWS SDK, resolve to your VPC endpoint"
  type        = bool
  default     = true
}

