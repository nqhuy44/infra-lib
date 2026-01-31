######################
# General
######################
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = null
}

variable "bucket_prefix" {
  description = "Creates a unique bucket name beginning with the specified prefix"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Whether to allow deleting the bucket with objects still inside"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to the bucket"
  type        = map(string)
  default     = {}
}

######################
# Access Control
######################
variable "acl" {
  description = "The canned ACL to apply to the bucket"
  type        = string
  default     = null
}

variable "object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced"
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "attach_policy" {
  description = "Whether to attach a policy to the bucket"
  type        = bool
  default     = false
}

variable "policy" {
  description = "The bucket policy as a JSON document"
  type        = string
  default     = null
}

######################
# Public Access Block
######################
variable "block_public_access" {
  description = "Whether to enable public access block for the bucket"
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

######################
# Versioning
######################
variable "versioning_enabled" {
  description = "Whether to enable versioning for the bucket"
  type        = bool
  default     = false
}

######################
# Encryption
######################
variable "encryption_enabled" {
  description = "Whether to enable server-side encryption for the bucket"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm. Valid values: AES256, aws:kms"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for encryption (only needed if sse_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Whether to use S3 Bucket Keys for SSE-KMS"
  type        = bool
  default     = true
}

######################
# Lifecycle Rules
######################
variable "lifecycle_rules" {
  description = "List of lifecycle rules to configure for the bucket"
  type        = any
  default     = []
}

######################
# CORS Configuration
######################
variable "cors_rules" {
  description = "List of CORS rules to configure for the bucket"
  type        = any
  default     = []
}

######################
# Logging
######################
variable "logging_enabled" {
  description = "Whether to enable logging for the bucket"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "The name of the bucket where you want S3 to store server access logs"
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "The prefix to use for all log object keys"
  type        = string
  default     = "logs/"
}

######################
# Website Configuration
######################
variable "website_enabled" {
  description = "Whether to enable website configuration for the bucket"
  type        = bool
  default     = false
}

variable "website_index_document" {
  description = "The name of the index document for the website"
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "The name of the error document for the website"
  type        = string
  default     = null
}

variable "website_routing_rules" {
  description = "A list of routing rules for the website"
  type        = any
  default     = null
}

######################
# Object Lock Configuration
######################
variable "object_lock_enabled" {
  description = "Whether to enable object lock for the bucket"
  type        = bool
  default     = false
}

######################
# Event Notification
######################
variable "event_notifications" {
  description = "List of event notifications to configure for the bucket"
  type        = any
  default     = []
}