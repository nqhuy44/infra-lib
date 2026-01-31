resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  security_groups = length(var.security_groups) > 0 ? var.security_groups : null

  enable_cross_zone_load_balancing = var.cross_zone_enabled
  enable_deletion_protection       = var.deletion_protection

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

# Target group for the EC2 instance(s)
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name     = each.value.name != null ? each.value.name : "${var.name}-${each.key}"
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  target_type = "instance"

  # Optional attributes
  deregistration_delay = lookup(each.value, "deregistration_delay", 300)
  preserve_client_ip   = lookup(each.value, "preserve_client_ip", null)
  proxy_protocol_v2    = lookup(each.value, "proxy_protocol_v2", false)

  health_check {
    enabled             = true
    interval            = lookup(each.value.health_check, "interval", 30)
    path                = contains(["HTTP", "HTTPS"], lookup(each.value.health_check, "protocol", each.value.protocol)) ? lookup(each.value.health_check, "path", "/") : null
    port                = lookup(each.value.health_check, "port", "traffic-port")
    protocol            = lookup(each.value.health_check, "protocol", each.value.protocol)
    timeout             = lookup(each.value.health_check, "timeout", 10)
    healthy_threshold   = lookup(each.value.health_check, "healthy_threshold", 3)
    unhealthy_threshold = lookup(each.value.health_check, "unhealthy_threshold", 3)
    matcher             = contains(["HTTP", "HTTPS"], lookup(each.value.health_check, "protocol", each.value.protocol)) ? lookup(each.value.health_check, "matcher", "200-299") : null
  }

  tags = merge(
    {
      Name = each.value.name != null ? each.value.name : "${var.name}-${each.key}"
    },
    var.tags
  )
}

# Attach EC2 instances to target groups
resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for pair in flatten([
      for tg_key, tg in var.target_groups : [
        for instance_key, instance_id in tg.instance_ids : {
          id          = "${tg_key}-${instance_key}"
          tg_key      = tg_key
          instance_id = instance_id
          port        = lookup(tg, "target_port", tg.port)
        }
      ]
    ]) : pair.id => pair
  }

  target_group_arn = aws_lb_target_group.this[each.value.tg_key].arn
  target_id        = each.value.instance_id
  port             = each.value.port
}

# Create listeners
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  }

  certificate_arn = var.listeners[each.key].certificate_arn != null ? var.listeners[each.key].certificate_arn : null

  ssl_policy = lookup(each.value, "ssl_policy", null)

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags
  )
}
