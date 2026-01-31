variable "name" {
  description = "Name of the AMI lifecycle policy and base name for created AMIs"
  type        = string
}

variable "description" {
  description = "Description for the AMI lifecycle policy"
  type        = string
  default     = null
}

variable "enable_dlm" {
  description = "If true, create DLM lifecycle policy (scheduled AMIs). If false, no schedule."
  type        = bool
  default     = false
}

variable "target_tags" {
  description = "Tags that must be present on EC2 instances to target for AMI creation"
  type        = map(string)
  default     = {}
}

variable "schedule_interval" {
  description = "How often to create AMIs"
  type        = number
  default     = 24
}

variable "schedule_interval_unit" {
  description = "Unit for schedule interval: HOURS | DAYS | WEEKS"
  type        = string
  default     = "HOURS"
  validation {
    condition     = contains(["HOURS", "DAYS", "WEEKS"], var.schedule_interval_unit)
    error_message = "schedule_interval_unit must be one of HOURS, DAYS, WEEKS"
  }
}

variable "schedule_times" {
  description = "List of UTC times (HH:MM) when creation should start"
  type        = list(string)
  default     = ["23:45"]
}

variable "retention_count" {
  description = "How many AMIs to retain per instance"
  type        = number
  default     = 7
}

variable "copy_tags" {
  description = "Whether to copy instance tags to AMI and snapshots"
  type        = bool
  default     = true
}

variable "policy_state" {
  description = "State of the lifecycle policy: ENABLED or DISABLED"
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.policy_state)
    error_message = "policy_state must be ENABLED or DISABLED"
  }
}

variable "tags" {
  description = "Resource tags to apply to the lifecycle policy"
  type        = map(string)
  default     = {}
}

variable "create_ami_now" {
  description = "If true, also create a one-off AMI from instance_id"
  type        = bool
  default     = false
}

variable "instance_id" {
  description = "EC2 instance ID for one-off AMI creation when create_ami_now is true"
  type        = string
  default     = null
}

variable "ami_now_name_suffix" {
  description = "Suffix to append to the one-off AMI name"
  type        = string
  default     = "manual"
}

variable "ami_now_no_reboot" {
  description = "If true, AWS does not shut down the instance before creating the image"
  type        = bool
  default     = true
}

variable "manual_triggers" {
  description = "Ordered list of tokens; append a new value to trigger a new AMI."
  type        = list(string)
  default     = []
}

variable "manual_retention_count" {
  description = "How many manual AMIs to keep (by most-recent tokens). 0 disables."
  type        = number
  default     = 5
  validation {
    condition     = var.manual_retention_count >= 0
    error_message = "manual_retention_count must be >= 0"
  }
}


