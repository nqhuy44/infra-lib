variable "name" {
  description = "Name for the EFS file system (used as creation token if creation_token is not set)"
  type        = string
}

variable "creation_token" {
  description = "A unique name (token) for creating the EFS file system"
  type        = string
  default     = null
}

variable "encrypted" {
  description = "If true, the disk will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "The file system performance mode. Can be 'generalPurpose' or 'maxIO'"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Can be 'bursting', 'provisioned', or 'elastic'"
  type        = string
  default     = "bursting"
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to 'provisioned'"
  type        = number
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "A list of subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the mount target"
  type        = list(string)
}

variable "backup_policy_enabled" {
  description = "Whether to enable EFS automatic backups"
  type        = bool
  default     = true
}

variable "transition_to_ia" {
  description = "Indicates how long it takes to transition files to the IA storage class. Valid values: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS"
  type        = string
  default     = null
}

variable "transition_to_primary_storage_class" {
  description = "Indicates how long it takes to transition files from IA to primary storage class. Valid values: AFTER_1_ACCESS"
  type        = string
  default     = null
}

variable "create_access_point" {
  description = "Whether to create an EFS access point"
  type        = bool
  default     = false
}

variable "access_point_posix_user_gid" {
  description = "The POSIX group ID used for all file system operations using this access point"
  type        = number
  default     = 1000
}

variable "access_point_posix_user_uid" {
  description = "The POSIX user ID used for all file system operations using this access point"
  type        = number
  default     = 1000
}

variable "access_point_posix_user_secondary_gids" {
  description = "Secondary POSIX group IDs used for all file system operations using this access point"
  type        = list(number)
  default     = []
}

variable "access_point_root_directory_path" {
  description = "The path on the EFS file system to expose as the root directory to NFS clients using the access point"
  type        = string
  default     = "/"
}

variable "access_point_root_directory_owner_gid" {
  description = "The POSIX group ID to apply to the root directory"
  type        = number
  default     = 1000
}

variable "access_point_root_directory_owner_uid" {
  description = "The POSIX user ID to apply to the root directory"
  type        = number
  default     = 1000
}

variable "access_point_root_directory_permissions" {
  description = "The POSIX permissions to apply to the root directory, in the format of an octal number"
  type        = string
  default     = "755"
}

variable "access_point_tags" {
  description = "A map of tags to assign to the access point"
  type        = map(string)
  default     = {}
}

variable "attach_file_system_policy" {
  description = "Whether to attach a file system policy to the EFS file system"
  type        = bool
  default     = false
}

variable "file_system_policy" {
  description = "The JSON policy document to attach to the EFS file system"
  type        = string
  default     = null
}

variable "enable_replica" {
  description = "Whether to enable EFS replication"
  type        = bool
  default     = false
}

variable "replica_availability_zone_name" {
  description = "The availability zone name for the replica"
  type        = string
  default     = null
}

variable "replica_kms_key_id" {
  description = "The ARN of the KMS key to use for encrypting the replica"
  type        = string
  default     = null
}

variable "replica_file_system_id" {
  description = "The ID of the source file system to replicate"
  type        = string
  default     = null
}

variable "replica_region" {
  description = "The AWS region in which to create the replica"
  type        = string
  default     = null
}
