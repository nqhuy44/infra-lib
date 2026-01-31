variable "create_instance" {
  description = "Controls if EC2 instance should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = "instance"
}

variable "ami_id" {
  description = "ID of AMI to use for the instance"
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "AMI ID must be a valid AWS AMI identifier (e.g., ami-0abcdef1234567890)."
  }
}

variable "instance_type" {
  description = "The type of instance to run"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS EC2 instance type (e.g., t3.micro, m5.large, g4dn.xlarge)."
  }
}

variable "state" {
  description = "Desired state of the EC2 instance (e.g., 'running', 'stopped'). If null, no state change is applied."
  type        = string
  default     = "running"
  # state only support stopped and running, not accept null
  validation {
    condition     = contains(["running", "stopped"], var.state)
    error_message = "State must be 'running' or 'stopped'."
  }
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance"
  type        = string
  default     = null
}

variable "enable_detailed_monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = null
}

variable "placement_group" {
  description = "The Placement Group to start the instance in"
  type        = string
  default     = null
}

variable "user_data" {
  description = "The user data to provide when launching the instance (plain text)"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "The user data to provide when launching the instance (base64-encoded)"
  type        = string
  default     = null
}

variable "hibernation" {
  description = "If true, the instance will support hibernation"
  type        = bool
  default     = false
}

variable "encrypt_all_volumes" {
  description = "If true, all EBS volumes will be encrypted (unless explicitly configured otherwise)"
  type        = bool
  default     = true
}

variable "encrypt_root_volume" {
  description = "If true, the root volume will be encrypted. If null, uses encrypt_all_volumes value"
  type        = bool
  default     = null
}

variable "kms_key_id" {
  description = "The KMS key to use for encryption"
  type        = string
  default     = null
}

variable "root_volume" {
  description = "Root volume configuration for the instance"
  type        = any
  default     = {}
}

variable "ebs_volumes" {
  description = "List of additional EBS volumes to attach to the instance"
  type        = list(any)
  default     = []
}

variable "network_interfaces" {
  description = <<-EOT
    List of additional network interfaces to create and attach.
    Each object should contain:
      - device_index (number, required)
      - subnet_id (string, required)
      - security_groups (list(string), required)
      - private_ip (string, optional)
      - delete_on_termination (bool, optional)
      - tags (map(string), optional)
  EOT
  type = list(object({
    device_index          = number
    subnet_id             = string
    security_groups       = list(string)
    private_ip            = optional(string)
    delete_on_termination = optional(bool)
    tags                  = optional(map(string))
  }))
  default = []
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "optional")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "enabled") # Changed default to enabled for better tagging
  })
  default = {}

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_options.http_endpoint)
    error_message = "HTTP endpoint must be either 'enabled' or 'disabled'."
  }

  validation {
    condition     = contains(["required", "optional"], var.metadata_options.http_tokens)
    error_message = "HTTP tokens must be either 'required' or 'optional'."
  }

  validation {
    condition     = var.metadata_options.http_put_response_hop_limit >= 1 && var.metadata_options.http_put_response_hop_limit <= 64
    error_message = "HTTP put response hop limit must be between 1 and 64."
  }

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_options.instance_metadata_tags)
    error_message = "Instance metadata tags must be either 'enabled' or 'disabled'."
  }
}

variable "cpu_credits" {
  description = "The credit option for CPU usage (unlimited or standard)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "CPU credits must be either 'standard' or 'unlimited'."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# variable "volume_tags" {
#   description = "A map of tags to add to all EBS volumes"
#   type        = map(string)
#   default     = {}
# }

variable "enable_primary_ipv6" {
  description = "Number of IPv6 addresses to associate with the primary network interface"
  type        = bool
  default     = false
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs."
  type        = bool
  default     = true # Default to enabled (AWS default)
}

variable "gpu_enabled" {
  description = "Whether the instance should be equipped with a GPU"
  type        = bool
  default     = false
}

variable "gpu_instance_type_prefixes" {
  description = "List of instance type prefixes that support GPUs (used for validation)"
  type        = list(string)
  default     = ["g3", "g4", "g5", "p2", "p3", "p4", "p5", "dl1", "trn1", "inf1", "vt1"]
}

variable "gpu_driver_options" {
  description = "Configuration options for GPU drivers (if needed)"
  type        = map(string)
  default     = {}
}

variable "disable_api_termination" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "The private IP address to assign to the instance (within subnet range)"
  type        = string
  default     = null
}


variable "tenancy" {
  description = "Tenancy of the instance (default, dedicated, or host)"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "Tenancy must be 'default', 'dedicated', or 'host'."
  }
}

variable "host_id" {
  description = "ID of a dedicated host for the instance (required when tenancy = host)"
  type        = string
  default     = null
}

variable "cpu_core_count" {
  description = "Sets the number of CPU cores for the instance"
  type        = number
  default     = null
}

variable "cpu_threads_per_core" {
  description = "Sets the number of CPU threads per core for the instance"
  type        = number
  default     = null
}

variable "enclave_options" {
  description = "Enable Nitro Enclaves on the instance"
  type = object({
    enabled = optional(bool, false)
  })
  default = {}
}