variable "name" {
  description = "Name prefix to use for resources (ASG, Launch Template)"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_zone_identifier" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
}

variable "min_size" {
  description = "The minimum size of the Auto Scaling Group"
  type        = number
}

variable "max_size" {
  description = "The maximum size of the Auto Scaling Group"
  type        = number
}

variable "desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  type        = number
}

variable "health_check_type" {
  description = "Controls how health checking is done. Valid values are EC2 or ELB"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the Auto Scaling Group should be terminated"
  type        = list(string)
  default     = []
}

variable "protect_from_scale_in" {
  description = "Allows setting instance protection. The Auto Scaling Group will not select instances with this setting for termination during scale in events"
  type        = bool
  default     = false
}

variable "capacity_rebalance" {
  description = "Whether capacity rebalance is enabled. If enabled, the Auto Scaling Group attempts to launch a replacement instance whenever a rebalance notification is received"
  type        = bool
  default     = false
}

variable "max_instance_lifetime" {
  description = "Maximum instance lifetime in seconds. Set null to disable"
  type        = number
  default     = null
}

variable "target_group_arns" {
  description = "A set of Application Load Balancer target group ARNs, for use with Application or Network Load Balancing"
  type        = list(string)
  default     = []
}

# Launch template parameters
variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name to use for instances"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile name or ARN to assign to instances"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with instances"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "User data (plain text)"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "User data (base64-encoded)"
  type        = string
  default     = null
}

variable "enable_detailed_monitoring" {
  description = "If true, detailed monitoring will be enabled"
  type        = bool
  default     = false
}

variable "root_volume" {
  description = "Root volume configuration for instances in the group"
  type        = object({
    volume_type = optional(string, "gp3")
    volume_size = optional(number, 20)
    encrypted   = optional(bool)
    kms_key_id  = optional(string)
    delete_on_termination = optional(bool, true)
    iops       = optional(number)
    throughput = optional(number)
    device_name = optional(string, "/dev/xvda")
    tags        = optional(map(string), {})
  })
  default = {}
}

variable "additional_ebs_volumes" {
  description = "List of additional EBS volumes to attach to each instance via launch template"
  type = list(object({
    device_name           = string
    volume_type           = optional(string, "gp3")
    volume_size           = number
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool, true)
    tags                  = optional(map(string), {})
  }))
  default = []
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "optional")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "disabled")
  })
  default = {}
}

# Rolling update configuration
variable "instance_refresh" {
  description = "Instance refresh configuration for rolling updates"
  type = object({
    strategy = optional(string, "Rolling")
    preferences = optional(object({
      min_healthy_percentage = optional(number, 50)
      instance_warmup        = optional(number, 300)
      checkpoint_percentages = optional(list(number), [20, 50, 100])
      checkpoint_delay       = optional(number, 3600)
      scale_in_protected_instances = optional(string, "Ignore")
      standby_instances      = optional(string, "Ignore")
    }), {})
  })
  default = {}
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out"
  type        = string
  default     = "10m"
}

variable "wait_for_elb_capacity" {
  description = "Setting this will cause Terraform to wait for exactly this number of healthy instances in all attached load balancers on both create and update operations"
  type        = number
  default     = null
}

# Auto Scaling Policies
variable "enable_scaling_policies" {
  description = "Enable auto scaling policies and CloudWatch alarms"
  type        = bool
  default     = true
}

variable "target_tracking_scaling_policies" {
  description = "Target tracking scaling policies for the Auto Scaling Group"
  type = map(object({
    target_value                = number
    disable_scale_in           = optional(bool, false)
    estimated_instance_warmup  = optional(number, 300)
    predefined_metric_specification = optional(object({
      predefined_metric_type = string
      resource_label        = optional(string)
    }), null)
    custom_metric_specification = optional(object({
      metric_name = string
      namespace   = string
      statistic   = string
      unit        = optional(string)
    }), null)
  }))
  default = {
    cpu = {
      target_value                = 70.0
      disable_scale_in           = false
      estimated_instance_warmup  = 300
      predefined_metric_specification = {
        predefined_metric_type = "ASGAverageCPUUtilization"
        resource_label        = null
      }
    }
  }
}

variable "step_scaling_policies" {
  description = "Step scaling policies for the Auto Scaling Group"
  type = map(object({
    adjustment_type          = string
    cooldown                = optional(number, 300)
    metric_aggregation_type = optional(string, "Average")
    min_adjustment_magnitude = optional(number)
    scaling_adjustments = list(object({
      metric_interval_lower_bound = optional(number)
      metric_interval_upper_bound = optional(number)
      scaling_adjustment          = number
    }))
    alarm_actions = optional(list(string), [])
    ok_actions    = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
  }))
  default = {}
}

variable "simple_scaling_policies" {
  description = "Simple scaling policies for the Auto Scaling Group"
  type = map(object({
    adjustment_type     = string
    cooldown           = optional(number, 300)
    scaling_adjustment = number
    alarm_actions      = optional(list(string), [])
    ok_actions         = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
  }))
  default = {}
}

# CloudWatch Alarms
variable "cloudwatch_alarms" {
  description = "CloudWatch alarms for scaling triggers"
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    threshold_metric_id = optional(string)
    alarm_description   = optional(string)
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    treat_missing_data  = optional(string, "missing")
    unit                = optional(string)
    dimensions = optional(map(string), {})
    datapoints_to_alarm = optional(number)
    extended_statistic  = optional(string)
    evaluate_low_sample_count_percentiles = optional(string)
  }))
  default = {
    high_cpu = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "This metric monitors ec2 cpu utilization"
      treat_missing_data  = "breaching"
    }
    low_cpu = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 20
      alarm_description   = "This metric monitors ec2 cpu utilization"
      treat_missing_data  = "notBreaching"
    }
  }
}

variable "enable_detailed_monitoring_alarms" {
  description = "Enable detailed monitoring alarms (requires detailed monitoring to be enabled)"
  type        = bool
  default     = false
}

variable "memory_utilization_alarms" {
  description = "Enable memory utilization alarms (requires CloudWatch agent)"
  type        = bool
  default     = false
}

variable "custom_metrics_alarms" {
  description = "Custom metrics alarms configuration"
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_description   = string
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    treat_missing_data  = optional(string, "missing")
    unit                = optional(string)
    dimensions = optional(map(string), {})
  }))
  default = {}
}

# Scaling Schedule
variable "scheduled_actions" {
  description = "Scheduled actions for the Auto Scaling Group"
  type = map(object({
    min_size         = number
    max_size         = number
    desired_capacity = number
    start_time       = optional(string)
    end_time         = optional(string)
    recurrence       = optional(string)
    time_zone        = optional(string)
  }))
  default = {}
}

# Predictive Scaling
# Note: Predictive scaling variables are commented out as they are not supported
# in the current AWS provider version. These will be uncommented when support is added.
