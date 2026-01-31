variable "project_id" {
  description = "Project ID where the VM will be created."
  type        = string
}

variable "name" {
  description = "Name of the instance."
  type        = string
}

variable "machine_type" {
  description = "Machine type to create (e.g., e2-micro)."
  type        = string
}

variable "zone" {
  description = "Zone to create the instance in."
  type        = string
}

variable "tags" {
  description = "Network tags."
  type        = list(string)
  default     = []
}

variable "boot_disk_image" {
  description = "Image to use for the boot disk."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "boot_disk_size" {
  description = "Size of the boot disk in GB."
  type        = number
  default     = 10
}

variable "boot_disk_type" {
  description = "Type of the boot disk (e.g., pd-standard, pd-ssd, pd-balanced)."
  type        = string
  default     = "pd-standard"
  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd", "pd-extreme"], var.boot_disk_type)
    error_message = "The boot_disk_type must be one of: pd-standard, pd-balanced, pd-ssd, pd-extreme."
  }
}

variable "additional_disks" {
  description = "List of additional data disks to create and attach to the instance."
  type = list(object({
    name        = string
    size        = number
    type        = optional(string, "pd-standard")
    device_name = optional(string)
  }))
  default = []
}

variable "network" {
  description = "Name or self_link of the network to attach to."
  type        = string
}

variable "subnetwork" {
  description = "Name or self_link of the subnetwork to attach to."
  type        = string
}

variable "assign_public_ip" {
  description = "If true, assigns a public IPv4 address to the instance."
  type        = bool
  default     = false
}

variable "static_public_ip" {
  description = "The static external IP address to assign to the instance. Requires assign_public_ip to be true."
  type        = string
  default     = null
}

variable "spot_instance" {
  description = "If true, provision as a Spot VM (preemptible)."
  type        = bool
  default     = false
}

variable "enable_ipv6" {
  description = "If true, enable IPv6 on the network interface."
  type        = bool
  default     = false
}

variable "metadata" {
  description = "Metadata key/value pairs."
  type        = map(string)
  default     = {}
}

variable "metadata_startup_script" {
  description = "Startup script to run when the instance starts."
  type        = string
  default     = null
}

variable "service_account" {
  description = "Service account to attach to the instance."
  type = object({
    email  = string
    scopes = list(string)
  })
  default = null
}

variable "ssh_keys" {
  description = "List of SSH keys to inject into the instance metadata. Each object should contain 'user' and 'public_key'."
  type = list(object({
    user       = string
    public_key = string
  }))
  default = []
}

variable "boot_disk_auto_delete" {
  description = "Whether the boot disk should be auto-deleted when the instance is deleted."
  type        = bool
  default     = true
}

variable "instance_status" {
  description = "The desired status of the instance (RUNNING or TERMINATED)."
  type        = string
  default     = "RUNNING"
}
