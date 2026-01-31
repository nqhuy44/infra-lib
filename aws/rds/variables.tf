variable "identifier" {
  description = "The name of the RDS instance or cluster"
  type        = string
}

variable "engine" {
  description = "The database engine to use (mysql, postgres, aurora-mysql, aurora-postgresql)"
  type        = string
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
  type        = number
  default     = 0 # Disabled by default
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of io1 or io2"
  type        = number
  default     = null
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN."
  type        = string
  default     = null
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Password for the master DB user. Not required if manage_master_user_password is true."
  type        = string
  sensitive   = true
  default     = null # Make it optional with a default value
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = null
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = null
}

# Subnet and Security Group Configuration
variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
}

variable "create_db_subnet_group" {
  description = "Whether to create a database subnet group"
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. Only used if create_db_subnet_group = false"
  type        = string
  default     = null
}

# Parameter Group Configuration
variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "mysql8.0" # Default to MySQL 8.0
}

variable "create_db_parameter_group" {
  description = "Whether to create a database parameter group"
  type        = bool
  default     = false
}

variable "parameters" {
  description = "A list of DB parameters to apply"
  type        = list(map(string))
  default     = []
}

variable "cluster_parameters" {
  description = "A list of DB cluster parameters to apply (Aurora only)"
  type        = list(map(string))
  default     = []
}

# Option Group Configuration (MySQL only)
variable "create_db_option_group" {
  description = "Whether to create a database option group"
  type        = bool
  default     = false
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = "8.0" # Default to MySQL 8.0
}

variable "options" {
  description = "A list of Options to apply"
  type        = any
  default     = []
}

# Backup and Maintenance Configuration
variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = null # Will be set in locals if null
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = null # Will be set in locals if null
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "delete_automated_backups" {
  description = "Specifies whether to remove automated backups immediately after the DB instance is deleted"
  type        = bool
  default     = true
}

# Enhanced Monitoring and Performance Insights
variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance"
  type        = number
  default     = 0 # 0 means disabled
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data"
  type        = number
  default     = 7 # 7 days (free tier)
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

# Aurora Specific Configuration
variable "aurora_instance_count" {
  description = "Number of instances to create in the Aurora cluster"
  type        = number
  default     = 1
}

variable "aurora_serverless" {
  description = "Specifies whether to create an Aurora Serverless v2 cluster"
  type        = bool
  default     = false
}

variable "serverlessv2_min_capacity" {
  description = "Minimum capacity for Aurora Serverless v2"
  type        = number
  default     = 0.5
}

variable "serverlessv2_max_capacity" {
  description = "Maximum capacity for Aurora Serverless v2"
  type        = number
  default     = 1
}

# CloudWatch Logs Exports
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs"
  type        = list(string)
  default     = []
}

# Additional Configuration
variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Controls if instance is publicly accessible"
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = true
}

variable "manage_master_user_password" {
  description = "Set to true to manage the master user password in AWS Secrets Manager"
  type        = bool
  default     = false
}

variable "master_user_secret_kms_key_id" {
  description = "The ARN or ID of the KMS key to encrypt the master user password secret in Secrets Manager"
  type        = string
  default     = null
}

variable "allow_major_version_upgrade" {
  description = "Indicates whether major version upgrades are allowed when modifying the DB instance/cluster."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
