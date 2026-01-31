resource "aws_cloudtrail" "this" {
  name                          = var.name
  s3_bucket_name                = var.s3_bucket_name
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = var.enable_log_file_validation
  is_organization_trail         = var.is_organization_trail
  kms_key_id                    = var.kms_key_id
  enable_logging                = var.enable_logging
  # CloudWatch Logs integration
  cloud_watch_logs_group_arn = var.cloud_watch_logs_group_arn
  cloud_watch_logs_role_arn  = var.cloud_watch_logs_role_arn

  dynamic "event_selector" {
    for_each = var.event_selectors
    content {
      read_write_type           = lookup(event_selector.value, "read_write_type", null)
      include_management_events = lookup(event_selector.value, "include_management_events", null)
      dynamic "data_resource" {
        for_each = lookup(event_selector.value, "data_resources", [])
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  # Advanced Event Selectors
  dynamic "advanced_event_selector" {
    for_each = var.advanced_event_selectors
    content {
      name = advanced_event_selector.value.name
      dynamic "field_selector" {
        for_each = advanced_event_selector.value.field_selectors
        content {
          field           = field_selector.value.field
          equals          = try(field_selector.value.equals, null)
          starts_with     = try(field_selector.value.starts_with, null)
          ends_with       = try(field_selector.value.ends_with, null)
          not_equals      = try(field_selector.value.not_equals, null)
          not_starts_with = try(field_selector.value.not_starts_with, null)
          not_ends_with   = try(field_selector.value.not_ends_with, null)
        }
      }
    }
  }

  tags = var.tags
}