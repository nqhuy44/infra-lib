######################
# Application Load Balancer
######################
resource "aws_lb" "this" {
  name                       = var.name
  internal                   = var.internal
  load_balancer_type         = "application"
  security_groups            = var.security_groups
  subnets                    = var.subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_http2               = var.enable_http2
  idle_timeout               = var.idle_timeout
  ip_address_type            = var.ip_address_type

  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

######################
# Target Groups
######################
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = each.value.name
  vpc_id               = var.vpc_id
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = lookup(each.value, "target_type", "instance")
  deregistration_delay = lookup(each.value, "deregistration_delay", 300)

  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", null) != null ? [each.value.health_check] : []
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      interval            = lookup(health_check.value, "interval", 30)
      path                = lookup(health_check.value, "path", "/")
      port                = lookup(health_check.value, "port", "traffic-port")
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 3)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 3)
      timeout             = lookup(health_check.value, "timeout", 5)
      protocol            = lookup(health_check.value, "protocol", each.value.protocol)
      matcher             = lookup(health_check.value, "matcher", "200")
    }
  }

  dynamic "stickiness" {
    for_each = lookup(each.value, "stickiness", null) != null ? [each.value.stickiness] : []
    content {
      enabled         = lookup(stickiness.value, "enabled", false)
      type            = lookup(stickiness.value, "type", "lb_cookie")
      cookie_duration = lookup(stickiness.value, "cookie_duration", 86400)
      cookie_name     = lookup(stickiness.value, "cookie_name", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

######################
# Target Group Attachments
######################
resource "aws_lb_target_group_attachment" "this" {
  for_each = { for idx, attachment in local.target_group_attachments : idx => attachment }

  target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id        = each.value.target_id
  port             = lookup(each.value, "port", null)
}

######################
# Listeners - HTTP
######################
resource "aws_lb_listener" "http" {
  for_each = { for key, listener in var.listeners : key => listener if lower(listener.protocol) == "http" }

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  dynamic "default_action" {
    for_each = lookup(each.value, "redirect_to_https", false) ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = lookup(each.value, "redirect_port", "443")
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = lookup(each.value, "redirect_to_https", false) ? [] : [1]
    content {
      type             = lookup(each.value, "action_type", "forward")
      target_group_arn = lookup(each.value, "target_group_key", null) != null ? aws_lb_target_group.this[each.value.target_group_key].arn : null

      dynamic "fixed_response" {
        for_each = lookup(each.value, "action_type", "") == "fixed-response" ? [lookup(each.value, "fixed_response", {})] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = lookup(fixed_response.value, "message_body", null)
          status_code  = lookup(fixed_response.value, "status_code", "200")
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-http-${each.value.port}"
    }
  )
}

######################
# Listeners - HTTPS
######################
resource "aws_lb_listener" "https" {
  for_each = { for key, listener in var.listeners : key => listener if lower(listener.protocol) == "https" }

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = lookup(each.value, "ssl_policy", "ELBSecurityPolicy-TLS13-1-2-2021-06") # Modern policy by default
  certificate_arn   = each.value.certificate_arn

  default_action {
    type             = lookup(each.value, "action_type", "forward")
    target_group_arn = lookup(each.value, "target_group_key", null) != null ? aws_lb_target_group.this[each.value.target_group_key].arn : null

    dynamic "fixed_response" {
      for_each = lookup(each.value, "action_type", "") == "fixed-response" ? [lookup(each.value, "fixed_response", {})] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = lookup(fixed_response.value, "message_body", null)
        status_code  = lookup(fixed_response.value, "status_code", "200")
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-https-${each.value.port}"
    }
  )
}

######################
# Additional Listener Certificates (SNI)
######################
resource "aws_lb_listener_certificate" "this" {
  for_each = { for idx, cert in local.additional_certificates : idx => cert }

  listener_arn    = aws_lb_listener.https[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}

######################
# Listener Rules
######################
resource "aws_lb_listener_rule" "this" {
  for_each = { for idx, rule in local.listener_rules : idx => rule }

  listener_arn = contains(keys(aws_lb_listener.http), each.value.listener_key) ? aws_lb_listener.http[each.value.listener_key].arn : aws_lb_listener.https[each.value.listener_key].arn
  priority     = lookup(each.value, "priority", null)

  # Rule conditions
  dynamic "condition" {
    for_each = lookup(each.value, "host_header", null) != null ? [each.value.host_header] : []
    content {
      host_header {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "path_pattern", null) != null ? [each.value.path_pattern] : []
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "http_header", null) != null ? [each.value.http_header] : []
    content {
      http_header {
        http_header_name = condition.value.name
        values           = condition.value.values
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "http_request_method", null) != null ? [each.value.http_request_method] : []
    content {
      http_request_method {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "query_string", null) != null ? [each.value.query_string] : []
    content {
      query_string {
        key   = lookup(condition.value, "key", null)
        value = condition.value.value
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "source_ip", null) != null ? [each.value.source_ip] : []
    content {
      source_ip {
        values = condition.value
      }
    }
  }

  # Action
  action {
    type             = lookup(each.value, "action_type", "forward")
    target_group_arn = lookup(each.value, "target_group_key", null) != null ? aws_lb_target_group.this[each.value.target_group_key].arn : null

    dynamic "redirect" {
      for_each = lookup(each.value, "action_type", "") == "redirect" ? [lookup(each.value, "redirect", {})] : []
      content {
        path        = lookup(redirect.value, "path", "/")
        host        = lookup(redirect.value, "host", "#{host}")
        port        = lookup(redirect.value, "port", "#{port}")
        protocol    = lookup(redirect.value, "protocol", "#{protocol}")
        query       = lookup(redirect.value, "query", "#{query}")
        status_code = lookup(redirect.value, "status_code", "HTTP_302")
      }
    }

    dynamic "fixed_response" {
      for_each = lookup(each.value, "action_type", "") == "fixed-response" ? [lookup(each.value, "fixed_response", {})] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = lookup(fixed_response.value, "message_body", null)
        status_code  = lookup(fixed_response.value, "status_code", "200")
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rule-${each.key}"
    },
  )
}

######################
# WAF Association
######################
# resource "aws_wafv2_web_acl_association" "this" {
#   for_each = var.waf_web_acl_arn != null ? toset([var.waf_web_acl_arn]) : []

#   resource_arn = aws_lb.this.arn
#   web_acl_arn  = each.value
# }

######################
# Local Variables
######################
locals {
  # Process target group attachments
  target_group_attachments = flatten([
    for target_group_key, target_group in var.target_groups : [
      for target_id in lookup(target_group, "instance_ids", []) : {
        target_group_key = target_group_key
        target_id        = target_id
        port             = lookup(target_group, "target_port", target_group.port)
      }
    ]
  ])

  # Process listener rules
  listener_rules = flatten([
    for listener_key, listener in var.listeners : [
      for rule in lookup(listener, "rules", []) : merge(rule, {
        listener_key = listener_key
      })
    ]
  ])

  # Process additional certificates for HTTPS listeners
  additional_certificates = flatten([
    for listener_key, listener in var.listeners : [
      for cert_arn in lookup(listener, "additional_certificate_arns", []) : {
        listener_key    = listener_key
        certificate_arn = cert_arn
      }
    ] if lower(listener.protocol) == "https"
  ])
}
