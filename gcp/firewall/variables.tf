variable "project_id" {
  description = "Project ID where the firewall rule will be created."
  type        = string
}

variable "name" {
  description = "Name of the firewall rule."
  type        = string
}

variable "network" {
  description = "Name or self_link of the network this rule applies to."
  type        = string
}

variable "description" {
  description = "Description of the firewall rule."
  type        = string
  default     = null
}

variable "allow" {
  description = "List of allowing protocols and ports."
  type        = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = []
}

variable "deny" {
  description = "List of denying protocols and ports."
  type        = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = []
}

variable "source_ranges" {
  description = "Source IP ranges."
  type        = list(string)
  default     = []
}

variable "source_tags" {
  description = "Source tags."
  type        = list(string)
  default     = []
}

variable "target_tags" {
  description = "Target tags."
  type        = list(string)
  default     = []
}

variable "priority" {
  description = "Priority of the rule."
  type        = number
  default     = 1000
}
