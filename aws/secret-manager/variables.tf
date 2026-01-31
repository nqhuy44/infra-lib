# --- Required Variables ---
variable "name" {
  description = "Name of the secret"
  type        = string
}

# --- Secret Content (at least one must be provided) ---
variable "secret_key_value" {
  description = "Secret as key-value pairs (can be empty for schema-only or contain actual values)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "secret_string" {
  description = "Secret value as a plain string"
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_binary" {
  description = "Secret value as binary data (base64 encoded)"
  type        = string
  default     = null
  sensitive   = true
}

# --- Optional Variables ---
variable "description" {
  description = "Description of the secret"
  type        = string
  default     = "Secret managed by Terraform"
}

variable "environment" {
  description = "Environment tag for the secret"
  type        = string
  default     = "development"
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting the secret"
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Number of days to retain secret after deletion (0-30)"
  type        = number
  default     = 30
}

variable "force_overwrite_replica_secret" {
  description = "Whether to overwrite a secret with the same name in the destination region"
  type        = bool
  default     = false
}

variable "version_stages" {
  description = "List of version stages for the secret version"
  type        = list(string)
  default     = ["AWSCURRENT"]
}

variable "replica_regions" {
  description = "List of regions to replicate the secret to"
  type = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}

variable "resource_policy" {
  description = "JSON policy document for the secret"
  type        = string
  default     = null
}

variable "enable_rotation" {
  description = "Whether to enable automatic rotation"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function for secret rotation"
  type        = string
  default     = null
}

variable "rotation_interval_days" {
  description = "Number of days between automatic rotations"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}