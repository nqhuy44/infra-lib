# --- Single Log Group Outputs ---
output "log_group_name" {
  description = "Name of the single log group"
  value       = var.create_single_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

output "log_group_arn" {
  description = "ARN of the single log group"
  value       = var.create_single_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}

output "log_group_retention_in_days" {
  description = "Retention period of the single log group"
  value       = var.create_single_log_group ? aws_cloudwatch_log_group.this[0].retention_in_days : null
}

# --- Multiple Log Groups Outputs ---
output "log_groups" {
  description = "Map of all created log groups with their details"
  value = {
    for name, group in aws_cloudwatch_log_group.multiple : name => {
      name              = group.name
      arn               = group.arn
      retention_in_days = group.retention_in_days
      kms_key_id        = group.kms_key_id
      skip_destroy      = group.skip_destroy
    }
  }
}

output "log_group_names" {
  description = "List of all log group names"
  value = var.create_single_log_group ? [aws_cloudwatch_log_group.this[0].name] : [
    for name, group in aws_cloudwatch_log_group.multiple : group.name
  ]
}

output "log_group_arns" {
  description = "List of all log group ARNs"
  value = var.create_single_log_group ? [aws_cloudwatch_log_group.this[0].arn] : [
    for name, group in aws_cloudwatch_log_group.multiple : group.arn
  ]
}

# --- Log Streams Outputs ---
output "log_streams" {
  description = "Map of created log streams"
  value = merge(
    # Single log group streams
    var.create_single_log_group ? {
      for i, stream in aws_cloudwatch_log_stream.single_group_streams : var.log_streams[i] => {
        name           = stream.name
        log_group_name = stream.log_group_name
        arn            = stream.arn
      }
    } : {},
    # Multiple log groups streams
    {
      for key, stream in aws_cloudwatch_log_stream.multiple_group_streams : key => {
        name           = stream.name
        log_group_name = stream.log_group_name
        arn            = stream.arn
      }
    }
  )
}

# --- Metric Filters Outputs ---
output "metric_filters" {
  description = "Map of created metric filters"
  value = merge(
    # Single log group metric filters
    var.create_single_log_group ? {
      for i, filter in aws_cloudwatch_log_metric_filter.single_group_filters : var.metric_filters[i].name => {
        name           = filter.name
        log_group_name = filter.log_group_name
        pattern        = filter.pattern
      }
    } : {},
    # Multiple log groups metric filters
    {
      for key, filter in aws_cloudwatch_log_metric_filter.multiple_group_filters : key => {
        name           = filter.name
        log_group_name = filter.log_group_name
        pattern        = filter.pattern
      }
    }
  )
}

# --- Subscription Filters Outputs ---
output "subscription_filters" {
  description = "Map of created subscription filters"
  value = merge(
    # Single log group subscription filters
    var.create_single_log_group ? {
      for i, filter in aws_cloudwatch_log_subscription_filter.single_group_subscriptions : var.subscription_filters[i].name => {
        name            = filter.name
        log_group_name  = filter.log_group_name
        filter_pattern  = filter.filter_pattern
        destination_arn = filter.destination_arn
      }
    } : {},
    # Multiple log groups subscription filters
    {
      for key, filter in aws_cloudwatch_log_subscription_filter.multiple_group_subscriptions : key => {
        name            = filter.name
        log_group_name  = filter.log_group_name
        filter_pattern  = filter.filter_pattern
        destination_arn = filter.destination_arn
      }
    }
  )
}

# --- Summary Outputs ---
output "summary" {
  description = "Summary of created CloudWatch resources"
  value = {
    mode                         = var.create_single_log_group ? "single" : "multiple"
    log_groups_created           = var.create_single_log_group ? 1 : length(aws_cloudwatch_log_group.multiple)
    log_streams_created          = length(aws_cloudwatch_log_stream.single_group_streams) + length(aws_cloudwatch_log_stream.multiple_group_streams)
    metric_filters_created       = length(aws_cloudwatch_log_metric_filter.single_group_filters) + length(aws_cloudwatch_log_metric_filter.multiple_group_filters)
    subscription_filters_created = length(aws_cloudwatch_log_subscription_filter.single_group_subscriptions) + length(aws_cloudwatch_log_subscription_filter.multiple_group_subscriptions)
  }
}

# --- WAF Integration Outputs ---
output "waf_log_destination_arns" {
  description = "ARNs suitable for WAF logging destination"
  value = var.create_single_log_group ? [aws_cloudwatch_log_group.this[0].arn] : [
    for name, group in aws_cloudwatch_log_group.multiple : group.arn
  ]
}

# --- Specific outputs for common use cases ---
output "application_log_group_arn" {
  description = "ARN of application log group (if exists)"
  value       = try(aws_cloudwatch_log_group.multiple["application"].arn, null)
}

output "waf_log_group_arn" {
  description = "ARN of WAF log group (if exists)"
  value       = try(aws_cloudwatch_log_group.multiple["waf"].arn, null)
}

output "vpc_flow_log_group_arn" {
  description = "ARN of VPC Flow log group (if exists)"
  value       = try(aws_cloudwatch_log_group.multiple["vpc-flow-logs"].arn, null)
}