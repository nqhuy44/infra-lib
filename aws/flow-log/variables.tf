variable "enabled" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to be used on all resources as prefix/identifier"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to attach the flow log to. Required if subnet_id, eni_id, transit_gateway_id, and transit_gateway_attachment_id are not specified"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID to attach the flow log to. Mutually exclusive with vpc_id, eni_id, transit_gateway_id, and transit_gateway_attachment_id"
  type        = string
  default     = null
}

variable "eni_id" {
  description = "Elastic Network Interface ID to attach the flow log to. Mutually exclusive with vpc_id, subnet_id, transit_gateway_id, and transit_gateway_attachment_id"
  type        = string
  default     = null
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID to attach the flow log to. Mutually exclusive with vpc_id, subnet_id, eni_id, and transit_gateway_attachment_id"
  type        = string
  default     = null
}

variable "transit_gateway_attachment_id" {
  description = "Transit Gateway Attachment ID to attach the flow log to. Mutually exclusive with vpc_id, subnet_id, eni_id, and transit_gateway_id"
  type        = string
  default     = null
}

variable "traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "traffic_type must be one of: ACCEPT, REJECT, ALL"
  }
}

variable "log_destination_type" {
  description = "The type of the logging destination. Valid values: cloud-watch-logs, s3, kinesis-data-firehose"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3", "kinesis-data-firehose"], var.log_destination_type)
    error_message = "log_destination_type must be one of: cloud-watch-logs, s3, kinesis-data-firehose"
  }
}

variable "log_destination" {
  description = "ARN of the logging destination. Required when using existing resources (not creating new ones). For CloudWatch Logs, provide log group ARN. For S3, provide bucket ARN. For Kinesis, provide delivery stream ARN. Not needed if create_s3_bucket or create_cloudwatch_log_group is true"
  type        = string
  default     = null
}

variable "max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid values: 60 (1 minute) or 600 (10 minutes)"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.max_aggregation_interval)
    error_message = "max_aggregation_interval must be either 60 or 600"
  }
}

variable "log_format" {
  description = "The fields to include in the flow log record, in the order in which they should appear. For more information, see Flow Log Records in the Amazon VPC User Guide"
  type        = string
  default     = null
}

variable "destination_options" {
  description = "Describes the destination options for a flow log. Only applicable when log_destination_type is s3"
  type = object({
    file_format                = optional(string)
    hive_compatible_partitions = optional(bool)
    per_hour_partition         = optional(bool)
  })
  default = null
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

######################
# S3 Bucket Variables
######################
variable "create_s3_bucket" {
  description = "Whether to create an S3 bucket for the flow log. Only applicable when log_destination_type is s3. If false, you must provide log_destination with an existing bucket ARN"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to create. Required when create_s3_bucket is true. Provide bucket name only, not ARN"
  type        = string
  default     = null
}

variable "s3_bucket_force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket when the bucket is destroyed"
  type        = bool
  default     = false
}

variable "s3_bucket_encryption_enabled" {
  description = "Whether to enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_kms_key_arn" {
  description = "ARN of the KMS key to use for S3 bucket encryption. If not specified, AES256 encryption will be used"
  type        = string
  default     = null
}

variable "s3_bucket_lifecycle_rule" {
  description = "Lifecycle rule for S3 bucket objects"
  type = object({
    expiration_days            = number
    transition_to_ia_days      = optional(number)
    transition_to_glacier_days = optional(number)
  })
  default = null
}

######################
# IAM Role Variables
######################
variable "create_iam_role" {
  description = "Whether to create an IAM role for the flow log. Only applicable when log_destination_type is cloud-watch-logs"
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Name of the IAM role to create. If not specified, a name will be generated"
  type        = string
  default     = null
}

variable "iam_role_policy_name" {
  description = "Name of the IAM role policy. If not specified, a name will be generated"
  type        = string
  default     = null
}

######################
# CloudWatch Log Group Variables
######################
variable "create_cloudwatch_log_group" {
  description = "Whether to create a CloudWatch Log Group for the flow log. Only applicable when log_destination_type is cloud-watch-logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group. If not specified, a name will be generated"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}
