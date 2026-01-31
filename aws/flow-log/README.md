# AWS VPC Flow Log Module

This Terraform module creates AWS VPC Flow Logs to capture information about the IP traffic going to and from network interfaces in your VPC, subnet, or specific Elastic Network Interface (ENI). Flow logs can help you with a number of tasks, such as troubleshooting connectivity issues, monitoring traffic, and meeting compliance requirements.

## Features

- ✅ **Multiple Resource Types** - Support for VPC, Subnet, ENI, Transit Gateway, and Transit Gateway Attachment
- ✅ **Flexible Destinations** - CloudWatch Logs, S3, or Kinesis Data Firehose
- ✅ **Automatic IAM Role Creation** - Optional IAM role and policy creation for CloudWatch Logs
- ✅ **CloudWatch Log Group Management** - Optional log group creation with configurable retention
- ✅ **Custom Log Format** - Support for custom log formats
- ✅ **Traffic Filtering** - Capture ACCEPT, REJECT, or ALL traffic
- ✅ **S3 Partitioning** - Hive-compatible and per-hour partitioning options for S3 destinations
- ✅ **KMS Encryption** - Support for encrypted CloudWatch Log Groups
- ✅ **Resource Tagging** - Comprehensive tagging support

## Usage

### Basic VPC Flow Log to CloudWatch Logs

```hcl
module "vpc_flow_log" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name   = "production-vpc"
  vpc_id = "vpc-1234567890abcdef0"

  # CloudWatch Logs is the default destination type
  log_destination_type = "cloud-watch-logs"

  # Module will automatically create CloudWatch Log Group and IAM Role
  create_cloudwatch_log_group = true
  create_iam_role             = true

  # Retain logs for 30 days
  cloudwatch_log_group_retention_in_days = 30

  tags = {
    Environment = "production"
    Project     = "network-monitoring"
  }
}
```

### Flow Log to S3 Bucket with Partitioning

```hcl
module "vpc_flow_log_s3" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name   = "production-vpc"
  vpc_id = "vpc-1234567890abcdef0"

  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::my-existing-flow-logs-bucket"

  # S3 destination options
  destination_options = {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  # Capture only rejected traffic
  traffic_type = "REJECT"

  # 1 minute aggregation interval for faster insights
  max_aggregation_interval = 60

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Auto-Create S3 Bucket for Flow Logs

```hcl
module "vpc_flow_log_new_s3" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name   = "production-vpc"
  vpc_id = "vpc-1234567890abcdef0"

  log_destination_type = "s3"

  # Auto-create S3 bucket - provide bucket name only
  create_s3_bucket = true
  s3_bucket_name   = "my-vpc-flow-logs-bucket"

  # Optional: Enable encryption
  s3_bucket_encryption_enabled = true
  s3_bucket_kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Optional: Configure lifecycle policy
  s3_bucket_lifecycle_rule = {
    expiration_days            = 90
    transition_to_ia_days      = 30
    transition_to_glacier_days = 60
  }

  # S3 destination options
  destination_options = {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Subnet Flow Log with Custom Log Format

```hcl
module "subnet_flow_log" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name      = "private-subnet-a"
  subnet_id = "subnet-1234567890abcdef0"

  log_destination_type = "cloud-watch-logs"

  # Custom log format with additional fields
  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${instance-id} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr}"

  cloudwatch_log_group_retention_in_days = 90

  tags = {
    Environment = "production"
    Subnet      = "private-a"
  }
}
```

### ENI Flow Log

```hcl
module "eni_flow_log" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name   = "web-server-eni"
  eni_id = "eni-1234567890abcdef0"

  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"

  tags = {
    Environment = "production"
    Resource    = "web-server"
  }
}
```

### Flow Log with KMS Encryption

```hcl
module "encrypted_flow_log" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name   = "production-vpc"
  vpc_id = "vpc-1234567890abcdef0"

  log_destination_type = "cloud-watch-logs"

  # Enable KMS encryption for CloudWatch Logs
  cloudwatch_log_group_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  cloudwatch_log_group_retention_in_days = 365

  tags = {
    Environment = "production"
    Compliance  = "pci-dss"
  }
}
```

### Using Existing IAM Role and Log Group

```hcl
module "vpc_flow_log_existing" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name   = "production-vpc"
  vpc_id = "vpc-1234567890abcdef0"

  log_destination_type = "cloud-watch-logs"
  log_destination      = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/vpc/flow-logs"

  # Use existing IAM role and log group
  create_iam_role             = false
  create_cloudwatch_log_group = false

  tags = {
    Environment = "production"
  }
}
```

### Transit Gateway Flow Log

```hcl
module "tgw_flow_log" {
  source = "github.com/your-org/terraform-modules//aws/flow-log?ref=main"

  name               = "transit-gateway"
  transit_gateway_id = "tgw-1234567890abcdef0"

  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::transit-gateway-flow-logs"

  destination_options = {
    file_format                = "parquet"
    hive_compatible_partitions = true
  }

  tags = {
    Environment = "production"
    Purpose     = "network-hub"
  }
}
```

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | ~> 1.3    |
| aws       | ~> 5.97.0 |

## Providers

| Name | Version   |
| ---- | --------- |
| aws  | ~> 5.97.0 |

## Resources

| Name                                                        | Type        |
| ----------------------------------------------------------- | ----------- |
| aws_flow_log.this                                           | resource    |
| aws_iam_role.flow_log                                       | resource    |
| aws_iam_role_policy.flow_log                                | resource    |
| aws_cloudwatch_log_group.flow_log                           | resource    |
| aws_s3_bucket.flow_log                                      | resource    |
| aws_s3_bucket_lifecycle_configuration.flow_log              | resource    |
| aws_s3_bucket_server_side_encryption_configuration.flow_log | resource    |
| aws_s3_bucket_public_access_block.flow_log                  | resource    |
| aws_s3_bucket_policy.flow_log                               | resource    |
| aws_iam_policy_document.assume_role                         | data source |
| aws_iam_policy_document.flow_log_policy                     | data source |
| aws_iam_policy_document.s3_bucket_policy                    | data source |
| aws_caller_identity.current                                 | data source |

## Inputs

| Name                                   | Description                                                                                        | Type          | Default              | Required |
| -------------------------------------- | -------------------------------------------------------------------------------------------------- | ------------- | -------------------- | :------: |
| enabled                                | Whether to enable VPC Flow Logs                                                                    | `bool`        | `true`               |    no    |
| name                                   | Name to be used on all resources as prefix/identifier                                              | `string`      | n/a                  |   yes    |
| vpc_id                                 | VPC ID to attach the flow log to                                                                   | `string`      | `null`               |    no    |
| subnet_id                              | Subnet ID to attach the flow log to                                                                | `string`      | `null`               |    no    |
| eni_id                                 | Elastic Network Interface ID to attach the flow log to                                             | `string`      | `null`               |    no    |
| transit_gateway_id                     | Transit Gateway ID to attach the flow log to                                                       | `string`      | `null`               |    no    |
| transit_gateway_attachment_id          | Transit Gateway Attachment ID to attach the flow log to                                            | `string`      | `null`               |    no    |
| traffic_type                           | The type of traffic to capture (ACCEPT, REJECT, ALL)                                               | `string`      | `"ALL"`              |    no    |
| log_destination_type                   | The type of the logging destination (cloud-watch-logs, s3, kinesis-data-firehose)                  | `string`      | `"cloud-watch-logs"` |    no    |
| log_destination                        | ARN of existing logging destination (not needed if creating new S3 bucket or CloudWatch log group) | `string`      | `null`               |    no    |
| max_aggregation_interval               | Maximum interval for flow log aggregation (60 or 600 seconds)                                      | `number`      | `600`                |    no    |
| log_format                             | Custom log format string                                                                           | `string`      | `null`               |    no    |
| destination_options                    | S3 destination options (file_format, hive_compatible_partitions, per_hour_partition)               | `object`      | `null`               |    no    |
| tags                                   | A map of tags to assign to resources                                                               | `map(string)` | `{}`                 |    no    |
| create_s3_bucket                       | Whether to create an S3 bucket for flow logs (only for s3 destination type)                        | `bool`        | `false`              |    no    |
| s3_bucket_name                         | Name of the S3 bucket to create (provide name only, not ARN)                                       | `string`      | `null`               |    no    |
| s3_bucket_force_destroy                | Whether to force destroy S3 bucket with objects                                                    | `bool`        | `false`              |    no    |
| s3_bucket_encryption_enabled           | Whether to enable server-side encryption for S3 bucket                                             | `bool`        | `true`               |    no    |
| s3_bucket_kms_key_arn                  | ARN of KMS key for S3 bucket encryption                                                            | `string`      | `null`               |    no    |
| s3_bucket_lifecycle_rule               | Lifecycle rule configuration for S3 bucket                                                         | `object`      | `null`               |    no    |
| create_iam_role                        | Whether to create an IAM role for CloudWatch Logs                                                  | `bool`        | `true`               |    no    |
| iam_role_name                          | Name of the IAM role                                                                               | `string`      | `null`               |    no    |
| iam_role_policy_name                   | Name of the IAM role policy                                                                        | `string`      | `null`               |    no    |
| create_cloudwatch_log_group            | Whether to create a CloudWatch Log Group                                                           | `bool`        | `true`               |    no    |
| cloudwatch_log_group_name              | Name of the CloudWatch Log Group                                                                   | `string`      | `null`               |    no    |
| cloudwatch_log_group_retention_in_days | Log retention in days                                                                              | `number`      | `7`                  |    no    |
| cloudwatch_log_group_kms_key_id        | KMS Key ARN for log encryption                                                                     | `string`      | `null`               |    no    |
| tags                                   | A map of tags to assign to resources                                                               | `map(string)` | `{}`                 |    no    |

## Outputs

| Name                      | Description                                   |
| ------------------------- | --------------------------------------------- |
| flow_log_id               | The ID of the Flow Log resource               |
| flow_log_arn              | The ARN of the Flow Log                       |
| iam_role_arn              | The ARN of the IAM role used by the Flow Log  |
| iam_role_name             | The name of the IAM role used by the Flow Log |
| cloudwatch_log_group_name | The name of the CloudWatch Log Group          |
| cloudwatch_log_group_arn  | The ARN of the CloudWatch Log Group           |
| s3_bucket_id              | The ID (name) of the S3 bucket                |
| s3_bucket_arn             | The ARN of the S3 bucket                      |

## Notes

- **Resource Mutually Exclusive**: You must specify exactly one of `vpc_id`, `subnet_id`, `eni_id`, `transit_gateway_id`, or `transit_gateway_attachment_id`.
- **CloudWatch Logs**: When using CloudWatch Logs as the destination, the module can automatically create the required IAM role and CloudWatch Log Group.
- **S3 Destination**:
  - **Auto-create bucket**: Set `create_s3_bucket = true` and provide `s3_bucket_name` (bucket name only, not ARN). The module will create the bucket with appropriate policies.
  - **Existing bucket**: Set `create_s3_bucket = false` and provide `log_destination` with the bucket ARN. Ensure the bucket has the appropriate bucket policy to allow VPC Flow Logs to write to it.
- **Kinesis Data Firehose**: When using Kinesis Data Firehose, ensure the delivery stream is configured to accept flow logs.
- **Log Format**: If not specified, AWS uses the default log format. Custom formats allow you to include additional fields or exclude unnecessary ones.
- **Aggregation Interval**: Setting to 60 seconds provides faster visibility into traffic patterns but may increase costs.

## Examples

For more examples, see the `examples/` directory.

## License

MIT Licensed. See LICENSE for full details.
