######################
# Repository Configuration
######################
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
}

variable "encryption_type" {
  description = "Encryption type for the repository. Must be one of: AES256 or KMS"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for encryption. Only required if encryption_type is KMS"
  type        = string
  default     = null
}

# Removed scan_on_push variable since it's now deprecated

######################
# Repository Policy
######################
variable "repository_policy" {
  description = "JSON policy document to apply to the ECR repository"
  type        = string
  default     = null
}

######################
# Lifecycle Policy
######################
variable "lifecycle_policy" {
  description = "JSON lifecycle policy document to apply to the ECR repository"
  type        = string
  default     = null
}

######################
# Registry Scan Configuration
######################
variable "create_registry_scan_config" {
  description = "Whether to create registry scanning configuration"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Registry scan type. Must be one of: BASIC or ENHANCED"
  type        = string
  default     = "BASIC"
}

variable "registry_scan_rules" {
  description = "List of scan rules for the registry"
  type = list(object({
    scan_frequency = string
    filters = list(object({
      filter      = string
      filter_type = string
    }))
  }))
  default = []
}

######################
# Pull Through Cache Configuration
######################
variable "pull_through_cache_rules" {
  description = "Map of pull through cache rules configurations"
  type = map(object({
    ecr_repository_prefix = string
    upstream_registry_url = string
    credential_arn        = optional(string)
  }))
  default = {}
}

######################
# Tags
######################
variable "tags" {
  description = "A map of tags to add to the ECR repository"
  type        = map(string)
  default     = {}
}
