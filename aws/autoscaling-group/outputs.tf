output "asg_id" {
  description = "The Auto Scaling Group ID"
  value       = aws_autoscaling_group.this.id
}

output "asg_arn" {
  description = "The Auto Scaling Group ARN"
  value       = aws_autoscaling_group.this.arn
}

output "asg_name" {
  description = "The Auto Scaling Group name"
  value       = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  description = "The Launch Template ID"
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "The Launch Template ARN"
  value       = aws_launch_template.this.arn
}

output "launch_template_latest_version" {
  description = "The latest version of the Launch Template"
  value       = aws_launch_template.this.latest_version
}

output "desired_capacity" {
  description = "Desired capacity of the ASG"
  value       = aws_autoscaling_group.this.desired_capacity
}

output "min_size" {
  description = "Minimum size of the ASG"
  value       = aws_autoscaling_group.this.min_size
}

output "max_size" {
  description = "Maximum size of the ASG"
  value       = aws_autoscaling_group.this.max_size
}

output "instance_refresh_enabled" {
  description = "Whether instance refresh is enabled for rolling updates"
  value       = var.instance_refresh != null && var.instance_refresh != {}
}

output "instance_refresh_strategy" {
  description = "Instance refresh strategy"
  value       = var.instance_refresh != null && var.instance_refresh != {} ? var.instance_refresh.strategy : null
}

output "instance_refresh_trigger_id" {
  description = "Instance refresh trigger resource ID"
  value       = var.instance_refresh != null && var.instance_refresh != {} ? null_resource.instance_refresh_trigger[0].id : null
}

# Scaling Policies Outputs
output "target_tracking_scaling_policies" {
  description = "Target tracking scaling policies"
  value = {
    for k, v in aws_autoscaling_policy.target_tracking : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

output "step_scaling_policies" {
  description = "Step scaling policies"
  value = {
    for k, v in aws_autoscaling_policy.step_scaling : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

output "simple_scaling_policies" {
  description = "Simple scaling policies"
  value = {
    for k, v in aws_autoscaling_policy.simple_scaling : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

# Predictive scaling outputs are not available in current AWS provider version

# CloudWatch Alarms Outputs
output "scaling_alarms" {
  description = "CloudWatch scaling alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.scaling_alarms : k => {
      name = v.alarm_name
      arn  = v.arn
    }
  }
}

output "memory_alarms" {
  description = "CloudWatch memory utilization alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.memory_alarms : k => {
      name = v.alarm_name
      arn  = v.arn
    }
  }
}

output "custom_metrics_alarms" {
  description = "CloudWatch custom metrics alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.custom_metrics_alarms : k => {
      name = v.alarm_name
      arn  = v.arn
    }
  }
}

# Scheduled Actions Outputs
output "scheduled_actions" {
  description = "Scheduled actions for the Auto Scaling Group"
  value = {
    for k, v in aws_autoscaling_schedule.scheduled_actions : k => {
      name = v.scheduled_action_name
    }
  }
}

# Scaling Configuration Summary
output "scaling_enabled" {
  description = "Whether auto scaling is enabled"
  value       = var.enable_scaling_policies
}

output "scaling_policies_count" {
  description = "Total number of scaling policies created"
  value = (
    length(aws_autoscaling_policy.target_tracking) +
    length(aws_autoscaling_policy.step_scaling) +
    length(aws_autoscaling_policy.simple_scaling)
  )
}

output "cloudwatch_alarms_count" {
  description = "Total number of CloudWatch alarms created"
  value = (
    length(aws_cloudwatch_metric_alarm.scaling_alarms) +
    length(aws_cloudwatch_metric_alarm.memory_alarms) +
    length(aws_cloudwatch_metric_alarm.custom_metrics_alarms)
  )
}
