locals {
  asg_name = var.name

  # Merge default root volume settings with user overrides
  root_volume = merge({
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = null
    kms_key_id            = null
    delete_on_termination = true
    device_name           = "/dev/xvda"
    tags                  = var.tags
  }, var.root_volume)
}

resource "aws_launch_template" "this" {
  name_prefix   = "${local.asg_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  update_default_version = true

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null && var.iam_instance_profile != "" ? [1] : []
    content {
      name = can(regex("^arn:", var.iam_instance_profile)) ? null : var.iam_instance_profile
      arn  = can(regex("^arn:", var.iam_instance_profile)) ? var.iam_instance_profile : null
    }
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  vpc_security_group_ids = sort(var.vpc_security_group_ids)

  user_data      = var.user_data

  block_device_mappings {
    device_name = lookup(local.root_volume, "device_name", "/dev/xvda")

    ebs {
      volume_type           = lookup(local.root_volume, "volume_type", null)
      volume_size           = lookup(local.root_volume, "volume_size", null)
      iops                  = lookup(local.root_volume, "iops", null)
      throughput            = lookup(local.root_volume, "throughput", null)
      encrypted             = lookup(local.root_volume, "encrypted", null)
      kms_key_id            = lookup(local.root_volume, "kms_key_id", null)
      delete_on_termination = lookup(local.root_volume, "delete_on_termination", true)
    }
  }

  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options.instance_metadata_tags
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = local.asg_name
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, lookup(local.root_volume, "tags", {}))
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "this" {
  name                      = local.asg_name
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  vpc_zone_identifier       = var.vpc_zone_identifier
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  termination_policies      = var.termination_policies
  target_group_arns         = var.target_group_arns
  max_instance_lifetime     = var.max_instance_lifetime
  capacity_rebalance        = var.capacity_rebalance
  protect_from_scale_in     = var.protect_from_scale_in
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  wait_for_elb_capacity     = var.wait_for_elb_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = tostring(aws_launch_template.this.default_version)
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = local.asg_name })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Instance refresh configuration for rolling updates
  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null && var.instance_refresh != {} ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      
      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null && instance_refresh.value.preferences != {} ? [instance_refresh.value.preferences] : []
        content {
          min_healthy_percentage = preferences.value.min_healthy_percentage
          instance_warmup        = preferences.value.instance_warmup
          checkpoint_percentages = preferences.value.checkpoint_percentages
          checkpoint_delay       = preferences.value.checkpoint_delay
          scale_in_protected_instances = preferences.value.scale_in_protected_instances
          standby_instances      = preferences.value.standby_instances
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

# Trigger instance refresh when AMI changes using null_resource
# Note: This requires AWS CLI to be installed and configured with appropriate permissions
resource "null_resource" "instance_refresh_trigger" {
  count = var.instance_refresh != null && var.instance_refresh != {} ? 1 : 0
  
  # Trigger when AMI changes
  triggers = {
    ami_id = var.ami_id
    asg_name = aws_autoscaling_group.this.name
  }
  
  # Use AWS CLI to start instance refresh
  provisioner "local-exec" {
    command = <<-EOT
      echo "Checking instance refresh status for ASG: ${aws_autoscaling_group.this.name}"
      
      # Check if instance refresh is already in progress
      REFRESH_STATUS=$(aws autoscaling describe-instance-refreshes \
        --auto-scaling-group-name ${aws_autoscaling_group.this.name} \
        --region ${data.aws_region.current.name} \
        --query 'InstanceRefreshes[0].Status' \
        --output text 2>/dev/null || echo "None")
      
      if [ "$REFRESH_STATUS" = "InProgress" ] || [ "$REFRESH_STATUS" = "Pending" ]; then
        echo "Instance refresh already in progress for ASG: ${aws_autoscaling_group.this.name}"
        echo "Current status: $REFRESH_STATUS"
        echo "Skipping new instance refresh request"
      else
        echo "Starting new instance refresh for ASG: ${aws_autoscaling_group.this.name}"
        aws autoscaling start-instance-refresh \
          --auto-scaling-group-name ${aws_autoscaling_group.this.name} \
          --preferences MinHealthyPercentage=${var.instance_refresh.preferences.min_healthy_percentage},InstanceWarmup=${var.instance_refresh.preferences.instance_warmup} \
          --region ${data.aws_region.current.name}
      fi
    EOT
  }
  
  # Log on destroy
  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      echo "Instance refresh trigger destroyed for ASG: ${self.triggers.asg_name}"
    EOT
  }
}

# Get current AWS region
data "aws_region" "current" {}

# =============================================================================
# AUTO SCALING POLICIES
# =============================================================================

# Target Tracking Scaling Policies
resource "aws_autoscaling_policy" "target_tracking" {
  for_each = var.enable_scaling_policies ? var.target_tracking_scaling_policies : {}

  name                   = "${local.asg_name}-target-tracking-${each.key}"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value     = each.value.target_value
    disable_scale_in = each.value.disable_scale_in

    # Use predefined metric specification if available, otherwise use customized
    dynamic "predefined_metric_specification" {
      for_each = each.value.predefined_metric_specification != null ? [each.value.predefined_metric_specification] : [{
        predefined_metric_type = "ASGAverageCPUUtilization"
        resource_label        = null
      }]
      content {
        predefined_metric_type = predefined_metric_specification.value.predefined_metric_type
        resource_label        = predefined_metric_specification.value.resource_label
      }
    }

    dynamic "customized_metric_specification" {
      for_each = each.value.custom_metric_specification != null ? [each.value.custom_metric_specification] : []
      content {
        metric_name = customized_metric_specification.value.metric_name
        namespace   = customized_metric_specification.value.namespace
        statistic   = customized_metric_specification.value.statistic
        unit        = customized_metric_specification.value.unit
      }
    }
  }
}

# Step Scaling Policies
resource "aws_autoscaling_policy" "step_scaling" {
  for_each = var.enable_scaling_policies ? var.step_scaling_policies : {}

  name                   = "${local.asg_name}-step-scaling-${each.key}"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "StepScaling"
  adjustment_type        = each.value.adjustment_type
  cooldown               = each.value.cooldown
  metric_aggregation_type = each.value.metric_aggregation_type
  min_adjustment_magnitude = each.value.min_adjustment_magnitude

  dynamic "step_adjustment" {
    for_each = each.value.scaling_adjustments
    content {
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
    }
  }
}

# Simple Scaling Policies
resource "aws_autoscaling_policy" "simple_scaling" {
  for_each = var.enable_scaling_policies ? var.simple_scaling_policies : {}

  name                   = "${local.asg_name}-simple-scaling-${each.key}"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "SimpleScaling"
  adjustment_type        = each.value.adjustment_type
  cooldown               = each.value.cooldown
  scaling_adjustment     = each.value.scaling_adjustment
}

# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

# Standard CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "scaling_alarms" {
  for_each = var.enable_scaling_policies ? var.cloudwatch_alarms : {}

  alarm_name          = "${local.asg_name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions
  treat_missing_data  = each.value.treat_missing_data
  unit                = each.value.unit
  datapoints_to_alarm = each.value.datapoints_to_alarm
  extended_statistic  = each.value.extended_statistic
  evaluate_low_sample_count_percentiles = each.value.evaluate_low_sample_count_percentiles

  dimensions = each.value.dimensions


  tags = merge(var.tags, {
    Name = "${local.asg_name}-${each.key}"
  })
}

# Memory Utilization Alarms (requires CloudWatch agent)
resource "aws_cloudwatch_metric_alarm" "memory_alarms" {
  for_each = var.enable_scaling_policies && var.memory_utilization_alarms ? {
    high_memory = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "MemoryUtilization"
      namespace           = "CWAgent"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "This metric monitors memory utilization"
      treat_missing_data  = "breaching"
    }
    low_memory = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "MemoryUtilization"
      namespace           = "CWAgent"
      period              = 300
      statistic           = "Average"
      threshold           = 20
      alarm_description   = "This metric monitors memory utilization"
      treat_missing_data  = "notBreaching"
    }
  } : {}

  alarm_name          = "${local.asg_name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = merge(var.tags, {
    Name = "${local.asg_name}-${each.key}"
  })
}

# Custom Metrics Alarms
resource "aws_cloudwatch_metric_alarm" "custom_metrics_alarms" {
  for_each = var.enable_scaling_policies ? var.custom_metrics_alarms : {}

  alarm_name          = "${local.asg_name}-custom-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions
  treat_missing_data  = each.value.treat_missing_data
  unit                = each.value.unit

  dimensions = each.value.dimensions

  tags = merge(var.tags, {
    Name = "${local.asg_name}-custom-${each.key}"
  })
}

# =============================================================================
# SCHEDULED ACTIONS
# =============================================================================

resource "aws_autoscaling_schedule" "scheduled_actions" {
  for_each = var.enable_scaling_policies ? var.scheduled_actions : {}

  scheduled_action_name  = "${local.asg_name}-${each.key}"
  min_size              = each.value.min_size
  max_size              = each.value.max_size
  desired_capacity      = each.value.desired_capacity
  start_time            = each.value.start_time
  end_time              = each.value.end_time
  recurrence            = each.value.recurrence
  time_zone             = each.value.time_zone
  autoscaling_group_name = aws_autoscaling_group.this.name
}

# =============================================================================
# PREDICTIVE SCALING
# =============================================================================
# Note: Predictive scaling is not supported in the current AWS provider version
# This feature will be added when the provider supports it
