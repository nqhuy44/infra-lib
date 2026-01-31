variable "name" {
  description = "Name of the VPC peering connection"
  type        = string
}

variable "requester_vpc_id" {
  description = "ID of the requester VPC"
  type        = string
}

variable "accepter_vpc_id" {
  description = "ID of the accepter VPC"
  type        = string
}

variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC"
  type        = string
}

variable "peer_region" {
  description = "Region of the accepter VPC (if different from provider region)"
  type        = string
  default     = null
}

variable "auto_accept" {
  description = "Whether to automatically accept the peering connection request"
  type        = bool
  default     = true
}

variable "requester_route_table_ids" {
  description = "List of route table IDs in the requester VPC where routes to the accepter VPC should be added"
  type        = list(string)
  default     = []
}

variable "accepter_route_table_ids" {
  description = "List of route table IDs in the accepter VPC where routes to the accepter VPC should be added"
  type        = list(string)
  default     = []
}

variable "enable_dns_resolution" {
  description = "Enable DNS resolution between VPCs"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the peering connection"
  type        = map(string)
  default     = {}
}
