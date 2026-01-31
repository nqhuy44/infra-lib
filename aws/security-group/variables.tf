variable "name" {
  description = "Name tag for the Security Group. This will also be used as the resource name if name_prefix is not set."
  type        = string
}

variable "description" {
  description = "Description for the Security Group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "The VPC ID where the Security Group will be created."
  type        = string
}

variable "ingress_rules" {
  description = <<-EOT
    List of ingress rules for the security group. Each rule is an object with attributes like:
    - description (string, optional)
    - from_port (number)
    - to_port (number)
    - protocol (string, e.g., "tcp", "udp", "icmp", "-1" for all)
    - cidr_blocks (list(string), optional)
    - ipv6_cidr_blocks (list(string), optional)
    - prefix_list_ids (list(string), optional)
    - security_group_id (string, optional, ID of a source SG) - Mutually exclusive with cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, self.
    - self (bool, optional, set to true to allow traffic from the SG itself) - Mutually exclusive with other source types.
  EOT
  type = list(object({
    description       = optional(string)
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_blocks       = optional(list(string))
    ipv6_cidr_blocks  = optional(list(string))
    prefix_list_ids   = optional(list(string))
    security_group_id = optional(string) # Use this for source_security_group_id
    self              = optional(bool)
  }))
  default = []
}

variable "egress_rules" {
  description = <<-EOT
    List of egress rules for the security group. Same structure as ingress_rules.
    Common default is to allow all outbound traffic.
  EOT
  type = list(object({
    description       = optional(string)
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_blocks       = optional(list(string))
    ipv6_cidr_blocks  = optional(list(string))
    prefix_list_ids   = optional(list(string))
    security_group_id = optional(string) # Use this for destination security_group_id
    self              = optional(bool)
  }))
  default = [ # Default to allow all outbound
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

variable "tags" {
  description = "A map of additional tags to assign to the Security Group."
  type        = map(string)
  default     = {}
}
