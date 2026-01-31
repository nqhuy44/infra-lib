######################
# CloudWatch Log Groups
######################
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_single_log_group ? 1 : 0

  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id
  skip_destroy      = var.skip_destroy

  tags = var.tags
}

# Multiple log groups
resource "aws_cloudwatch_log_group" "multiple" {
  for_each = var.log_groups

  name              = each.key
  retention_in_days = try(each.value.retention_in_days, var.default_retention_in_days)
  kms_key_id        = try(each.value.kms_key_id, var.default_kms_key_id)
  skip_destroy      = try(each.value.skip_destroy, var.default_skip_destroy)

  tags = merge(
    var.tags,
    try(each.value.tags, {})
  )
}

######################
# CloudWatch Log Streams
######################
resource "aws_cloudwatch_log_stream" "single_group_streams" {
  count = var.create_single_log_group && length(var.log_streams) > 0 ? length(var.log_streams) : 0

  name           = var.log_streams[count.index]
  log_group_name = aws_cloudwatch_log_group.this[0].name

  depends_on = [aws_cloudwatch_log_group.this]
}

# Log streams for multiple log groups
resource "aws_cloudwatch_log_stream" "multiple_group_streams" {
  for_each = local.log_group_stream_combinations

  name           = each.value.stream_name
  log_group_name = each.value.log_group_name

  depends_on = [aws_cloudwatch_log_group.multiple]
}

######################
# CloudWatch Log Metric Filters
######################
resource "aws_cloudwatch_log_metric_filter" "single_group_filters" {
  count = var.create_single_log_group && length(var.metric_filters) > 0 ? length(var.metric_filters) : 0

  name           = var.metric_filters[count.index].name
  pattern        = var.metric_filters[count.index].pattern
  log_group_name = aws_cloudwatch_log_group.this[0].name

  metric_transformation {
    name          = var.metric_filters[count.index].metric_transformation.name
    namespace     = var.metric_filters[count.index].metric_transformation.namespace
    value         = try(var.metric_filters[count.index].metric_transformation.value, "1")
    default_value = try(var.metric_filters[count.index].metric_transformation.default_value, null)
    unit          = try(var.metric_filters[count.index].metric_transformation.unit, "None")
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

# Metric filters for multiple log groups
resource "aws_cloudwatch_log_metric_filter" "multiple_group_filters" {
  for_each = local.log_group_filter_combinations

  name           = each.value.filter_name
  pattern        = each.value.pattern
  log_group_name = each.value.log_group_name

  metric_transformation {
    name          = each.value.metric_transformation.name
    namespace     = each.value.metric_transformation.namespace
    value         = try(each.value.metric_transformation.value, "1")
    default_value = try(each.value.metric_transformation.default_value, null)
    unit          = try(each.value.metric_transformation.unit, "None")
  }

  depends_on = [aws_cloudwatch_log_group.multiple]
}

######################
# CloudWatch Log Subscription Filters
######################
resource "aws_cloudwatch_log_subscription_filter" "single_group_subscriptions" {
  count = var.create_single_log_group && length(var.subscription_filters) > 0 ? length(var.subscription_filters) : 0

  name            = var.subscription_filters[count.index].name
  log_group_name  = aws_cloudwatch_log_group.this[0].name
  filter_pattern  = try(var.subscription_filters[count.index].filter_pattern, "")
  destination_arn = var.subscription_filters[count.index].destination_arn
  role_arn        = try(var.subscription_filters[count.index].role_arn, null)
  distribution    = try(var.subscription_filters[count.index].distribution, null)

  depends_on = [aws_cloudwatch_log_group.this]
}

# Subscription filters for multiple log groups
resource "aws_cloudwatch_log_subscription_filter" "multiple_group_subscriptions" {
  for_each = local.log_group_subscription_combinations

  name            = each.value.subscription_name
  log_group_name  = each.value.log_group_name
  filter_pattern  = try(each.value.filter_pattern, "")
  destination_arn = each.value.destination_arn
  role_arn        = try(each.value.role_arn, null)
  distribution    = try(each.value.distribution, null)

  depends_on = [aws_cloudwatch_log_group.multiple]
}

######################
# Local calculations for combinations
######################
locals {
  # Create combinations of log groups and their streams
  log_group_stream_combinations = merge([
    for group_name, group_config in var.log_groups : {
      for stream_name in try(group_config.log_streams, []) : "${group_name}-${stream_name}" => {
        log_group_name = group_name
        stream_name    = stream_name
      }
    }
  ]...)

  # Create combinations of log groups and their metric filters
  log_group_filter_combinations = merge([
    for group_name, group_config in var.log_groups : {
      for filter in try(group_config.metric_filters, []) : "${group_name}-${filter.name}" => {
        log_group_name        = group_name
        filter_name           = filter.name
        pattern               = filter.pattern
        metric_transformation = filter.metric_transformation
      }
    }
  ]...)

  # Create combinations of log groups and their subscription filters
  log_group_subscription_combinations = merge([
    for group_name, group_config in var.log_groups : {
      for subscription in try(group_config.subscription_filters, []) : "${group_name}-${subscription.name}" => {
        log_group_name    = group_name
        subscription_name = subscription.name
        filter_pattern    = try(subscription.filter_pattern, "")
        destination_arn   = subscription.destination_arn
        role_arn          = try(subscription.role_arn, null)
        distribution      = try(subscription.distribution, null)
      }
    }
  ]...)
}