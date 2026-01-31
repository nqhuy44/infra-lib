resource "aws_globalaccelerator_accelerator" "this" {
  name            = var.name
  ip_address_type = var.ip_address_type
  enabled         = var.enabled

  dynamic "attributes" {
    for_each = var.flow_logs_enabled != null || var.flow_logs_s3_bucket != null || var.flow_logs_s3_prefix != null ? [1] : []
    content {
      flow_logs_enabled   = var.flow_logs_enabled
      flow_logs_s3_bucket = var.flow_logs_s3_bucket
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

resource "aws_globalaccelerator_listener" "this" {
  for_each = var.listeners

  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = lookup(each.value, "client_affinity", "NONE")
  protocol        = each.value.protocol

  dynamic "port_range" {
    for_each = each.value.port_ranges != null ? each.value.port_ranges : []
    content {
      from_port = port_range.value.from_port
      to_port   = port_range.value.to_port
    }
  }
}

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = var.endpoint_groups

  listener_arn          = aws_globalaccelerator_listener.this[each.value.listener_key].id
  endpoint_group_region = each.value.region

  health_check_interval_seconds = lookup(each.value, "health_check_interval", 30)
  health_check_path             = lookup(each.value, "health_check_path", "/")
  health_check_port             = lookup(each.value, "health_check_port", 80)
  health_check_protocol         = lookup(each.value, "health_check_protocol", "TCP")
  threshold_count               = lookup(each.value, "threshold_count", 3)
  traffic_dial_percentage       = lookup(each.value, "traffic_dial_percentage", 100)

  dynamic "endpoint_configuration" {
    for_each = each.value.endpoints
    content {
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = lookup(endpoint_configuration.value, "weight", 128)
      client_ip_preservation_enabled = lookup(endpoint_configuration.value, "client_ip_preservation_enabled", true)
    }
  }
}
