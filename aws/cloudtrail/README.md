# AWS CloudTrail Module

This Terraform module creates an AWS CloudTrail trail and associates it with an existing S3 bucket for log storage. It supports advanced configuration including multi-region trails, organization trails, log file validation, KMS encryption, event selectors, advanced event selectors, and CloudWatch Logs integration.

---

## Features

- ✅ **Associate with Existing S3 Bucket** – Use any pre-existing S3 bucket for log storage
- ✅ **Multi-Region & Organization Trails** – Monitor activity across all regions and accounts
- ✅ **Log File Validation** – Enable integrity validation for CloudTrail logs
- ✅ **KMS Encryption** – Encrypt logs with a customer-managed KMS key
- ✅ **Event Selectors & Advanced Event Selectors** – Fine-grained control over which events are logged
- ✅ **CloudWatch Logs Integration** – Stream CloudTrail logs to CloudWatch for real-time monitoring and alerting
- ✅ **Resource Tagging** – Tag your CloudTrail resources

---

## Usage

### Basic CloudTrail with Existing S3 Bucket

```hcl
module "cloudtrail" {
  source          = "../../modules/cloudtrail"
  name            = "my-basic-trail"
  s3_bucket_name  = "my-existing-bucket"
  tags = {
    Environment = "dev"
  }
}
```

### CloudTrail with CloudWatch Logs Integration

```hcl
resource "aws_cloudwatch_log_group" "trail" {
  name = "/aws/cloudtrail/my-trail"
}

resource "aws_iam_role" "cloudtrail_cw_role" {
  name = "cloudtrail-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cw_attach" {
  role       = aws_iam_role.cloudtrail_cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCloudTrailFullAccess"
}

module "cloudtrail" {
  source = "../../modules/cloudtrail"

  name                        = "cw-trail"
  s3_bucket_name              = "my-logs-bucket"
  cloud_watch_logs_group_arn  = aws_cloudwatch_log_group.trail.arn
  cloud_watch_logs_role_arn   = aws_iam_role.cloudtrail_cw_role.arn
  tags = {
    Environment = "production"
    Service     = "audit"
  }
}
```

### CloudTrail with Event Selectors

```hcl
module "cloudtrail" {
  source = "../../modules/cloudtrail"

  name            = "event-selector-trail"
  s3_bucket_name  = "my-logs-bucket"
  event_selectors = [
    {
      read_write_type           = "All"
      include_management_events = true
      data_resources = [
        {
          type   = "AWS::S3::Object"
          values = ["arn:aws:s3:::my-logs-bucket/"]
        }
      ]
    }
  ]
  tags = {
    Environment = "production"
    Compliance  = "pci"
  }
}
```

### CloudTrail with Advanced Event Selectors

```hcl
module "cloudtrail" {
  source = "../../modules/cloudtrail"

  name            = "advanced-selector-trail"
  s3_bucket_name  = "my-logs-bucket"
  advanced_event_selectors = [
    {
      name = "LogOnlyS3DataEvents"
      field_selectors = [
        {
          field  = "eventCategory"
          equals = ["Data"]
        },
        {
          field  = "resources.type"
          equals = ["AWS::S3::Object"]
        }
      ]
    }
  ]
  tags = {
    Environment = "production"
    Compliance  = "pci"
  }
}
```

---

## Input Variables

| Name                          | Description                                                     | Type         | Default | Required |
| ----------------------------- | --------------------------------------------------------------- | ------------ | ------- | -------- |
| name                          | The name of the CloudTrail trail                                | string       | n/a     | yes      |
| s3_bucket_name                | The name of the S3 bucket for CloudTrail logs (must exist)      | string       | n/a     | yes      |
| include_global_service_events | Whether the trail is publishing events from global services     | bool         | true    | no       |
| is_multi_region_trail         | Whether the trail is created in all regions                     | bool         | true    | no       |
| enable_log_file_validation    | Whether log file integrity validation is enabled                | bool         | true    | no       |
| is_organization_trail         | Whether the trail is an AWS Organizations trail                 | bool         | false   | no       |
| kms_key_id                    | KMS key ARN to encrypt CloudTrail logs                          | string       | null    | no       |
| enable_logging                | Enable logging for the trail                                    | bool         | true    | no       |
| event_selectors               | List of event selector blocks                                   | list(object) | []      | no       |
| advanced_event_selectors      | List of advanced event selector blocks for fine-grained logging | list(object) | []      | no       |
| cloud_watch_logs_group_arn    | ARN of the CloudWatch Logs group for log delivery               | string       | null    | no       |
| cloud_watch_logs_role_arn     | ARN of the IAM role for CloudWatch Logs delivery                | string       | null    | no       |
| tags                          | A map of tags to assign to the resource                         | map(string)  | {}      | no       |

---

## Outputs

| Name           | Description                               |
| -------------- | ----------------------------------------- |
| cloudtrail_id  | The name of the trail                     |
| cloudtrail_arn | The ARN of the trail                      |
| home_region    | The region in which the trail was created |

---

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 1.3    |
| aws       | ~> 5.97.0 |

---

## License

This module is released under the MIT License.
