# --- Create Controls ---
variable "create_cluster" {
  description = "Whether to create an MSK cluster"
  type        = bool
  default     = true
}

# --- External Cluster Variables (for connector only) ---
variable "external_bootstrap_servers" {
  description = "Bootstrap servers string when not creating a cluster but only a connector"
  type        = string
  default     = ""
}

# --- General Variables ---
variable "name" {
  description = "Name of the MSK cluster"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# --- MSK Cluster Variables ---
variable "kafka_version" {
  description = "The version of Kafka to use for the cluster (e.g., 3.6.0, 3.8.0)"
  type        = string
  default     = "3.8.1"
}

variable "configuration_kafka_versions" {
  description = "List of Kafka versions that the MSK configuration supports. Use this to allow upgrading Kafka without recreating the configuration. If null or empty, defaults to [var.kafka_version]."
  type        = list(string)
  default     = null
}

variable "broker_node_type" {
  description = "The type of EC2 instance to use for Kafka brokers"
  type        = string
  default     = "kafka.t3.small"
}

variable "broker_count" {
  description = "The number of broker nodes"
  type        = number
  default     = 3
  validation {
    condition     = var.broker_count > 0 && var.broker_count <= 30
    error_message = "Broker count must be between 1 and 30."
  }
}

# variable "az_distribution" {
#   description = "Number of broker nodes per availability zone"
#   type        = number
#   default     = 1
#   validation {
#     condition     = var.az_distribution >= 1
#     error_message = "Number of brokers per Availability Zone must be at least 1."
#   }
# }

variable "broker_storage_info" {
  description = "Storage information for broker nodes"
  type        = any
  default = {
    ebs_storage_info = {
      volume_size = 100
    }
  }
}

# --- Network Configuration ---
variable "vpc_id" {
  description = "VPC ID where the MSK cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the MSK cluster"
  type        = list(string)
}

variable "connector_subnet_ids" {
  description = "Subnet IDs for MSK Connect (defaults to cluster subnet_ids if not specified)"
  type        = list(string)
  default     = null
}

variable "security_groups" {
  description = "List of security group IDs for the MSK cluster (required when creating a cluster)"
  type        = list(string)
  validation {
    condition     = length(var.security_groups) > 0
    error_message = "At least one security group must be provided for the MSK cluster."
  }
}

variable "client_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the MSK cluster"
  type        = list(string)
  default     = [""]
}

# --- Authentication and Encryption ---
variable "client_authentication" {
  description = "Client authentication configuration"
  type        = any
  default     = {}
}

variable "encryption_in_transit" {
  description = "Encryption in transit configuration"
  type        = any
  default = {
    client_broker = "TLS"
    in_cluster    = true
  }
}

variable "encryption_at_rest_kms_key_arn" {
  description = "KMS key ARN for encryption at rest"
  type        = string
  default     = null
}

# --- Configuration ---
variable "create_configuration" {
  description = "Whether to create an MSK configuration"
  type        = bool
  default     = false
}

variable "use_existing_configuration" {
  description = "Whether to use an existing MSK configuration instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_configuration_arn" {
  description = "ARN of an existing MSK configuration to use (if use_existing_configuration is true)"
  type        = string
  default     = ""
}

variable "existing_configuration_revision" {
  description = "Revision of the existing MSK configuration to use"
  type        = number
  default     = 1
}

variable "server_properties" {
  description = "Contents of the server.properties file for Kafka broker nodes"
  type        = string
  default     = <<EOF
auto.create.topics.enable=true
delete.topic.enable=true
EOF
}

# --- Monitoring and Logging ---
variable "enhanced_monitoring" {
  description = "Specify the desired enhanced MSK CloudWatch monitoring level"
  type        = string
  default     = "DEFAULT"
  validation {
    condition     = contains(["DEFAULT", "PER_BROKER", "PER_TOPIC_PER_BROKER", "PER_TOPIC_PER_PARTITION"], var.enhanced_monitoring)
    error_message = "Valid values for enhanced_monitoring are DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, or PER_TOPIC_PER_PARTITION."
  }
}

variable "prometheus_jmx_exporter" {
  description = "Indicates whether you want to enable or disable the JMX Exporter"
  type        = bool
  default     = false
}

variable "prometheus_node_exporter" {
  description = "Indicates whether you want to enable or disable the Node Exporter"
  type        = bool
  default     = false
}

variable "logging_cloudwatch" {
  description = "Indicates whether you want to enable or disable streaming broker logs to CloudWatch Logs"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group" {
  description = "Name of CloudWatch Log Group to deliver logs to"
  type        = string
  default     = null
}

variable "logging_s3" {
  description = "Indicates whether you want to enable or disable streaming broker logs to S3"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "Name of the S3 bucket to deliver logs to"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix to append to the S3 folder name logs are delivered to"
  type        = string
  default     = null
}

variable "logging_firehose" {
  description = "Indicates whether you want to enable or disable streaming broker logs to Kinesis Firehose"
  type        = bool
  default     = false
}

variable "firehose_delivery_stream" {
  description = "Name of the Kinesis Firehose delivery stream to deliver logs to"
  type        = string
  default     = null
}

# --- MSK Connect Variables ---
variable "create_connector" {
  description = "Whether to create an MSK connector"
  type        = bool
  default     = false
}

variable "connector_config" {
  description = "Configuration for MSK connector"
  type        = any
  default     = {}
}

variable "connector_authentication_type" {
  description = "Authentication type for MSK connector"
  type        = string
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "IAM", "SCRAM"], var.connector_authentication_type)
    error_message = "Valid values for connector_authentication_type are NONE, IAM, or SCRAM."
  }
}

variable "connector_encryption_type" {
  description = "Encryption type for MSK connector"
  type        = string
  default     = "TLS"
  validation {
    condition     = contains(["PLAINTEXT", "TLS"], var.connector_encryption_type)
    error_message = "Valid values for connector_encryption_type are PLAINTEXT or TLS."
  }
}

variable "connector_security_groups" {
  description = "List of security group IDs for MSK Connect (defaults to cluster security groups if not specified)"
  type        = list(string)
  default     = null
}

# --- S3 Connector Specific Variables ---
variable "create_connector_iam_role" {
  description = "Whether to create IAM role and policies for MSK Connect"
  type        = bool
  default     = false
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that the MSK Connect connector needs access to"
  type        = list(string)
  default     = []
}
