# --- General Configuration ---
variable "create" {
  description = "Whether to create the Elastic IP resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for the Elastic IPs"
  type        = string
  default     = "eip"
}

variable "number_of_eips" {
  description = "Number of Elastic IPs to create"
  type        = number
  default     = 1
}

# --- EIP Configuration ---
variable "network_border_group" {
  description = "The network border group to create the EIP within"
  type        = string
  default     = null
}

variable "public_ipv4_pool" {
  description = "The public IPv4 pool from which to allocate the Elastic IP"
  type        = string
  default     = null
}

variable "eip_names" {
  description = "Explicit names for the Elastic IPs (overrides name prefix)"
  type        = list(string)
  default     = null
}

# --- Association Configuration ---
variable "associate_with_instance" {
  description = "Whether to associate the EIPs with EC2 instances"
  type        = bool
  default     = false
}

variable "create_separate_association" {
  description = "Whether to create a separate EIP association resource (useful for changing associations without recreating EIPs)"
  type        = bool
  default     = false
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to associate with the EIPs"
  type        = list(string)
  default     = null
}

variable "network_interface_ids" {
  description = "List of network interface IDs to associate with the EIPs"
  type        = list(string)
  default     = null
}

# --- Tagging ---
variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "eip_tags" {
  description = "Additional tags for the Elastic IPs"
  type        = map(string)
  default     = {}
}