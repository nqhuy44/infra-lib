variable "name" {
  description = "Name for the Redis replication group"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for resource naming"
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the Redis replication group"
  type        = string
  default     = null
}

# --- Node Configuration ---
variable "node_type" {
  description = "ElastiCache instance type (e.g. cache.t3.small)"
  type        = string
  default     = "cache.t3.small"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

# --- Cluster Mode Settings ---
variable "cluster_mode_enabled" {
  description = "Flag to enable cluster mode (using num_node_groups + replicas_per_node_group instead of num_cache_clusters)"
  type        = bool
  default     = false
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (primary and replicas) when NOT using cluster mode"
  type        = number
  default     = 1
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for Redis cluster mode"
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes in each node group"
  type        = number
  default     = 1
}

# --- Networking ---
variable "subnet_ids" {
  description = "List of VPC subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "create_subnet_group" {
  description = "Create subnet group"
  type        = bool
  default     = true
}

variable "subnet_group_name" {
  description = "Subnet group name if not creating one"
  type        = string
  default     = null
}

variable "subnet_group_description" {
  description = "Description for subnet group"
  type        = string
  default     = null
}

# --- Parameter Group ---
variable "create_parameter_group" {
  description = "Create parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Parameter group name if not creating one"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Redis parameter group family (e.g. redis7)"
  type        = string
  default     = "redis7.0"
}

variable "parameter_group_description" {
  description = "Description for parameter group"
  type        = string
  default     = null
}

variable "parameters" {
  description = "Redis parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# --- Multi-AZ & Failover ---
variable "multi_az_enabled" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

variable "preferred_cache_cluster_azs" {
  description = "List of preferred AZs for cache clusters"
  type        = list(string)
  default     = null
}

# --- Auth & Encryption ---
variable "auth_token" {
  description = "Auth token for password protecting Redis (transit encryption must be enabled)"
  type        = string
  default     = null
  sensitive   = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption at rest"
  type        = string
  default     = null
}

# --- Backup & Maintenance ---
variable "snapshot_name" {
  description = "Name of a snapshot to restore from"
  type        = string
  default     = null
}

variable "snapshot_arns" {
  description = "ARNs of snapshots to restore from"
  type        = list(string)
  default     = null
}

variable "snapshot_window" {
  description = "Daily time range for taking snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "mon:05:00-mon:06:00"
}

variable "notification_topic_arn" {
  description = "ARN of SNS topic for notifications"
  type        = string
  default     = null
}

# --- Advanced Settings ---
variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately or during maintenance window"
  type        = bool
  default     = false
}

variable "auth_token_update_strategy" {
  description = "Strategy to use when updating the auth token. Valid values are SET and ROTATE."
  type        = string
  default     = "SET"
  validation {
    condition     = contains(["SET", "ROTATE"], var.auth_token_update_strategy)
    error_message = "Valid values for auth_token_update_strategy are SET and ROTATE."
  }
}

# --- Tagging ---
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
