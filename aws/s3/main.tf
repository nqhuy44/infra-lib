locals {
  is_public_acl = contains(["public-read", "public-read-write"], var.acl != null ? var.acl : "")
}

######################
# S3 Bucket
######################
resource "aws_s3_bucket" "this" {
  bucket              = var.bucket_name
  bucket_prefix       = var.bucket_prefix
  force_destroy       = var.force_destroy
  object_lock_enabled = var.object_lock_enabled

  tags = merge(
    {
      Name = var.bucket_name != null ? var.bucket_name : var.bucket_prefix
    },
    var.tags
  )
}

######################
# S3 Bucket ACL
######################
resource "aws_s3_bucket_acl" "this" {
  count = var.acl != null ? 1 : 0

  bucket = aws_s3_bucket.this.id
  acl    = var.acl

  depends_on = [
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_public_access_block.this
  ]
}

######################
# S3 Bucket Ownership Controls
######################
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

######################
# S3 Bucket Policy
######################
resource "aws_s3_bucket_policy" "this" {
  count = var.attach_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = var.policy

  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}

######################
# S3 Bucket Versioning
######################
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

######################
# S3 Bucket Server-Side Encryption
######################
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.encryption_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

######################
# S3 Bucket Public Access Block
######################
resource "aws_s3_bucket_public_access_block" "this" {
  count = (var.block_public_access || local.is_public_acl) ? 1 : 0

  bucket = aws_s3_bucket.this.id

  block_public_acls       = local.is_public_acl ? false : var.block_public_acls
  block_public_policy     = local.is_public_acl ? false : var.block_public_policy
  ignore_public_acls      = local.is_public_acl ? false : var.ignore_public_acls
  restrict_public_buckets = local.is_public_acl ? false : var.restrict_public_buckets

  depends_on = [
    aws_s3_bucket.this
  ]
}

######################
# S3 Bucket Lifecycle Rules
######################
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = try(rule.value.id, rule.key)
      status = try(rule.value.enabled, true) ? "Enabled" : "Disabled"

      # Filter - can contain prefix, tags, size, etc.
      dynamic "filter" {
        for_each = try(rule.value.filter, null) != null ? [rule.value.filter] : []
        content {
          prefix = try(filter.value.prefix, null)

          dynamic "tag" {
            for_each = try(filter.value.tags, {})
            content {
              key   = tag.key
              value = tag.value
            }
          }

          object_size_greater_than = try(filter.value.object_size_greater_than, null)
          object_size_less_than    = try(filter.value.object_size_less_than, null)
        }
      }

      # Prefix filter (older style)
      dynamic "filter" {
        for_each = try(rule.value.prefix, null) != null && try(rule.value.filter, null) == null ? [rule.value.prefix] : []
        content {
          prefix = filter.value
        }
      }

      # Empty filter when neither is specified
      dynamic "filter" {
        for_each = try(rule.value.prefix, null) == null && try(rule.value.filter, null) == null ? [true] : []
        content {}
      }

      # Transitions
      dynamic "transition" {
        for_each = try(rule.value.transitions, [])
        content {
          days          = try(transition.value.days, null)
          date          = try(transition.value.date, null)
          storage_class = transition.value.storage_class
        }
      }

      # Expiration
      dynamic "expiration" {
        for_each = try(rule.value.expiration, null) != null ? [rule.value.expiration] : []
        content {
          days                         = try(expiration.value.days, null)
          date                         = try(expiration.value.date, null)
          expired_object_delete_marker = try(expiration.value.expired_object_delete_marker, null)
        }
      }

      # Noncurrent Version Expiration
      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration, null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      # Noncurrent Version Transitions
      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_version_transitions, [])
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Abort Incomplete Multipart Upload
      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_incomplete_multipart_upload_days, null) != null ? [rule.value.abort_incomplete_multipart_upload_days] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

######################
# S3 Bucket CORS Configuration
######################
resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      id              = try(cors_rule.value.id, cors_rule.key)
      allowed_headers = try(cors_rule.value.allowed_headers, [])
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = try(cors_rule.value.expose_headers, [])
      max_age_seconds = try(cors_rule.value.max_age_seconds, null)
    }
  }
}

######################
# S3 Bucket Logging
######################
resource "aws_s3_bucket_logging" "this" {
  count = var.logging_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

######################
# S3 Bucket Website Configuration
######################
resource "aws_s3_bucket_website_configuration" "this" {
  count = var.website_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.website_index_document
  }

  dynamic "error_document" {
    for_each = var.website_error_document != null ? [var.website_error_document] : []
    content {
      key = error_document.value
    }
  }

  dynamic "routing_rule" {
    for_each = var.website_routing_rules != null ? var.website_routing_rules : []
    content {
      condition {
        key_prefix_equals               = try(routing_rule.value.condition.key_prefix_equals, null)
        http_error_code_returned_equals = try(routing_rule.value.condition.http_error_code_returned_equals, null)
      }

      redirect {
        host_name               = try(routing_rule.value.redirect.host_name, null)
        http_redirect_code      = try(routing_rule.value.redirect.http_redirect_code, null)
        protocol                = try(routing_rule.value.redirect.protocol, null)
        replace_key_prefix_with = try(routing_rule.value.redirect.replace_key_prefix_with, null)
        replace_key_with        = try(routing_rule.value.redirect.replace_key_with, null)
      }
    }
  }
}

######################
# S3 Bucket Event Notification
######################

resource "aws_s3_bucket_notification" "this" {
  count = length(var.event_notifications) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "lambda_function" {
    for_each = [for n in var.event_notifications : n if n.lambda_function != null]
    content {
      lambda_function_arn = lambda_function.value.lambda_function.arn
      events              = lambda_function.value.lambda_function.events
      filter_prefix       = try(lambda_function.value.lambda_function.filter_prefix, null)
      filter_suffix       = try(lambda_function.value.lambda_function.filter_suffix, null)
    }
  }

  dynamic "queue" {
    for_each = [for n in var.event_notifications : n if n.queue != null]
    content {
      queue_arn     = queue.value.queue.arn
      events        = queue.value.queue.events
      filter_prefix = try(queue.value.queue.filter_prefix, null)
      filter_suffix = try(queue.value.queue.filter_suffix, null)
    }
  }

  dynamic "topic" {
    for_each = [for n in var.event_notifications : n if n.topic != null]
    content {
      topic_arn     = topic.value.topic.arn
      events        = topic.value.topic.events
      filter_prefix = try(topic.value.topic.filter_prefix, null)
      filter_suffix = try(topic.value.topic.filter_suffix, null)
    }
  }

  depends_on = [
    aws_s3_bucket.this,
  ]
}