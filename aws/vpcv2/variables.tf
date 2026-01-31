variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    type                    = string # "public", "private", "isolated"
    map_public_ip_on_launch = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "nat_gateways" {
  description = "Map of NAT Gateway configurations"
  type = map(object({
    availability_zone = string
    public_subnet_key = string # Which public subnet to place NAT in
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "route_tables" {
  description = "Map of route table configurations"
  type = map(object({
    type            = string           # "public", "private", "isolated", "custom"
    nat_gateway_key = optional(string) # Which NAT gateway to route to (for private tables)
    routes = optional(list(object({
      destination_cidr_block    = string
      gateway_id                = optional(string)
      nat_gateway_id            = optional(string)
      instance_id               = optional(string)
      vpc_peering_connection_id = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "subnet_route_table_associations" {
  description = "Map subnet keys to route table keys"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}