######################
# Locals
######################
locals {
  # Determine the log destination based on whether S3 bucket is created or existing destination is provided
  flow_log_destination = (
    var.log_destination_type == "s3" && var.create_s3_bucket
    ? aws_s3_bucket.flow_log[0].arn
    : var.log_destination_type == "cloud-watch-logs" && var.create_cloudwatch_log_group
    ? aws_cloudwatch_log_group.flow_log[0].arn
    : var.log_destination
  )
}

######################
# S3 Bucket for Flow Logs
######################
resource "aws_s3_bucket" "flow_log" {
  count = var.enabled && var.log_destination_type == "s3" && var.create_s3_bucket ? 1 : 0

  bucket        = var.s3_bucket_name
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(
    {
      Name = var.s3_bucket_name
    },
    var.tags
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_log" {
  count = var.enabled && var.log_destination_type == "s3" && var.create_s3_bucket && var.s3_bucket_lifecycle_rule != null ? 1 : 0

  bucket = aws_s3_bucket.flow_log[0].id

  rule {
    id     = "flow-log-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.s3_bucket_lifecycle_rule.expiration_days
    }

    dynamic "transition" {
      for_each = var.s3_bucket_lifecycle_rule.transition_to_ia_days != null ? [1] : []
      content {
        days          = var.s3_bucket_lifecycle_rule.transition_to_ia_days
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.s3_bucket_lifecycle_rule.transition_to_glacier_days != null ? [1] : []
      content {
        days          = var.s3_bucket_lifecycle_rule.transition_to_glacier_days
        storage_class = "GLACIER"
      }
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_log" {
  count = var.enabled && var.log_destination_type == "s3" && var.create_s3_bucket && var.s3_bucket_encryption_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_log[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_bucket_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.s3_bucket_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "flow_log" {
  count = var.enabled && var.log_destination_type == "s3" && var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.flow_log[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "flow_log" {
  count = var.enabled && var.log_destination_type == "s3" && var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.flow_log[0].id
  policy = data.aws_iam_policy_document.s3_bucket_policy[0].json

  depends_on = [aws_s3_bucket_public_access_block.flow_log]
}

data "aws_caller_identity" "current" {
  count = var.enabled && var.log_destination_type == "s3" && var.create_s3_bucket ? 1 : 0
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  count = var.enabled && var.log_destination_type == "s3" && var.create_s3_bucket ? 1 : 0

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.flow_log[0].arn]
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.flow_log[0].arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

######################
# VPC Flow Log
######################
resource "aws_flow_log" "this" {
  count = var.enabled ? 1 : 0

  iam_role_arn                  = var.log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log[0].arn : null
  log_destination               = local.flow_log_destination
  log_destination_type          = var.log_destination_type
  traffic_type                  = var.traffic_type
  vpc_id                        = var.vpc_id
  subnet_id                     = var.subnet_id
  eni_id                        = var.eni_id
  transit_gateway_id            = var.transit_gateway_id
  transit_gateway_attachment_id = var.transit_gateway_attachment_id

  max_aggregation_interval = var.max_aggregation_interval
  log_format               = var.log_format

  dynamic "destination_options" {
    for_each = var.destination_options != null ? [var.destination_options] : []
    content {
      file_format                = lookup(destination_options.value, "file_format", "plain-text")
      hive_compatible_partitions = lookup(destination_options.value, "hive_compatible_partitions", false)
      per_hour_partition         = lookup(destination_options.value, "per_hour_partition", false)
    }
  }

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

######################
# IAM Role for CloudWatch Logs
######################
resource "aws_iam_role" "flow_log" {
  count = var.enabled && var.log_destination_type == "cloud-watch-logs" && var.create_iam_role ? 1 : 0

  name               = var.iam_role_name != null ? var.iam_role_name : "${var.name}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json

  tags = merge(
    {
      Name = var.iam_role_name != null ? var.iam_role_name : "${var.name}-flow-log-role"
    },
    var.tags
  )
}

data "aws_iam_policy_document" "assume_role" {
  count = var.enabled && var.log_destination_type == "cloud-watch-logs" && var.create_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

######################
# IAM Role Policy for CloudWatch Logs
######################
resource "aws_iam_role_policy" "flow_log" {
  count = var.enabled && var.log_destination_type == "cloud-watch-logs" && var.create_iam_role ? 1 : 0

  name   = var.iam_role_policy_name != null ? var.iam_role_policy_name : "${var.name}-flow-log-policy"
  role   = aws_iam_role.flow_log[0].id
  policy = data.aws_iam_policy_document.flow_log_policy[0].json
}

data "aws_iam_policy_document" "flow_log_policy" {
  count = var.enabled && var.log_destination_type == "cloud-watch-logs" && var.create_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

######################
# CloudWatch Log Group
######################
resource "aws_cloudwatch_log_group" "flow_log" {
  count = var.enabled && var.log_destination_type == "cloud-watch-logs" && var.create_cloudwatch_log_group ? 1 : 0

  name              = var.cloudwatch_log_group_name != null ? var.cloudwatch_log_group_name : "/aws/vpc/flow-log/${var.name}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(
    {
      Name = var.cloudwatch_log_group_name != null ? var.cloudwatch_log_group_name : "/aws/vpc/flow-log/${var.name}"
    },
    var.tags
  )
}
