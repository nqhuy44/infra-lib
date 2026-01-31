# AWS Auto Scaling Group (ASG) Terraform Module

This module creates an AWS Auto Scaling Group along with a Launch Template, following the conventions used in other modules of this repository.

## Features

- Launch Template with common settings (AMI, instance type, security groups, IAM instance profile, user-data, IMDS options)
- Root EBS volume configuration with encryption support
- Auto Scaling Group with health checks, desired/min/max size, scale-in protection, capacity rebalance
- **Instance Refresh for zero-downtime rolling updates** - automatically handles AMI updates with rolling replacement
- **Comprehensive Auto Scaling Policies** - Target tracking, step scaling, and simple scaling policies
- **CloudWatch Alarms** - CPU, memory, and custom metrics monitoring with automatic scaling triggers
- **Scheduled Actions** - Time-based scaling for predictable workload patterns
- Optional ALB/NLB Target Group attachments
- Propagates tags (including Name) to instances at launch

## Usage

```hcl
module "asg_web" {
  source = "../../devops-terraform-modules/aws/autoscaling-group"

  name                 = "web-asg"
  vpc_zone_identifier  = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  min_size         = 2
  max_size         = 5
  desired_capacity = 3

  ami_id         = data.aws_ami.ubuntu.id
  instance_type  = "t3.micro"
  key_name       = "my-key"
  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOT
    #!/bin/bash
    echo "hello" > /var/tmp/hello.txt
  EOT

  root_volume = {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  target_group_arns = [aws_lb_target_group.web.arn]

  # Enable rolling updates for zero-downtime AMI updates
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
      instance_warmup        = 300
      checkpoint_percentages = [20, 50, 100]
      checkpoint_delay       = 3600
    }
  }

  # Auto Scaling Configuration
  enable_scaling_policies = true

  # Target tracking scaling (recommended for most use cases)
  target_tracking_scaling_policies = {
    cpu = {
      target_value                = 70.0
      disable_scale_in           = false
      estimated_instance_warmup  = 300
    }
  }

  # CloudWatch alarms for additional monitoring
  cloudwatch_alarms = {
    high_cpu = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "High CPU utilization"
    }
    low_cpu = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 20
      alarm_description   = "Low CPU utilization"
    }
  }

  # Memory utilization alarms (requires CloudWatch agent)
  memory_utilization_alarms = true

  # Wait for healthy instances before considering deployment complete
  wait_for_capacity_timeout = "10m"
  wait_for_elb_capacity     = 2

  tags = {
    Environment = "dev"
    Project     = "common"
  }
}
```

## Inputs

### Basic Configuration

- name (string, required): Name prefix for ASG and Launch Template
- vpc_zone_identifier (list(string), required): Subnet IDs for ASG
- min_size, max_size, desired_capacity (number, required)
- health_check_type (string, default "EC2")
- health_check_grace_period (number, default 300)
- termination_policies (list(string), default [])
- protect_from_scale_in (bool, default false)
- capacity_rebalance (bool, default false)
- max_instance_lifetime (number, default null)
- target_group_arns (list(string), default [])
- ami_id (string, required)
- instance_type (string, default "t3.micro")
- key_name (string, default null)
- iam_instance_profile (string, default null)
- vpc_security_group_ids (list(string), default [])
- user_data (string, default null)
- user_data_base64 (string, default null)
- enable_detailed_monitoring (bool, default false)
- root_volume (object, default {}): volume_type, volume_size, encrypted, kms_key_id, delete_on_termination, iops, throughput, device_name, tags
- metadata_options (object, default {}): http_endpoint, http_tokens, http_put_response_hop_limit, instance_metadata_tags
- wait_for_capacity_timeout (string, default "10m"): Timeout for capacity operations
- wait_for_elb_capacity (number, default null): Wait for specific number of healthy instances in load balancer
- tags (map(string), default {})

### Auto Scaling Configuration

- **enable_scaling_policies (bool, default true)**: Enable auto scaling policies and CloudWatch alarms
- **target_tracking_scaling_policies (map(object), default {cpu: {...}}): Target tracking scaling policies**
  - target_value (number): Target value for the metric
  - disable_scale_in (bool, default false): Disable scale-in actions
  - estimated_instance_warmup (number, default 300): Time in seconds for instances to warm up before including in metric calculations (not supported in current AWS provider version)
  - predefined_metric_specification (object, optional): Predefined metric configuration
    - predefined_metric_type (string): Type of predefined metric (ASGAverageCPUUtilization, ASGAverageNetworkIn, etc.)
    - resource_label (string, optional): Resource label for the metric
  - custom_metric_specification (object, optional): Custom metric configuration
    - metric_name (string): Name of the custom metric
    - namespace (string): Namespace of the custom metric
    - statistic (string): Statistic for the metric (Average, Sum, etc.)
    - unit (string, optional): Unit of the metric
    - dimensions (map(string), optional): Dimensions for the metric

- **step_scaling_policies (map(object), default {}): Step scaling policies**
  - adjustment_type (string): Type of adjustment (ChangeInCapacity, ExactCapacity, PercentChangeInCapacity)
  - cooldown (number, default 300): Cooldown period
  - metric_aggregation_type (string, default "Average"): How metrics are aggregated
  - min_adjustment_magnitude (number, optional): Minimum adjustment magnitude
  - min_adjustment_step (number, optional): Minimum adjustment step
  - scaling_adjustments (list(object)): List of scaling adjustments
    - metric_interval_lower_bound (number, optional): Lower bound for metric interval
    - metric_interval_upper_bound (number, optional): Upper bound for metric interval
    - scaling_adjustment (number): Number of instances to add/remove

- **simple_scaling_policies (map(object), default {}): Simple scaling policies**
  - adjustment_type (string): Type of adjustment
  - cooldown (number, default 300): Cooldown period
  - scaling_adjustment (number): Number of instances to add/remove

### CloudWatch Alarms

- **cloudwatch_alarms (map(object), default {high_cpu: {...}, low_cpu: {...}}): CloudWatch alarms**
  - comparison_operator (string): Comparison operator (GreaterThanThreshold, LessThanThreshold, etc.)
  - evaluation_periods (number): Number of periods over which data is compared
  - metric_name (string): Name of the metric
  - namespace (string): Namespace of the metric
  - period (number): Period in seconds over which the statistic is applied
  - statistic (string): Statistic to apply (Average, Sum, Maximum, etc.)
  - threshold (number): Threshold value for the alarm
  - alarm_description (string, optional): Description of the alarm
  - alarm_actions (list(string), default []): Actions to take when alarm state is ALARM
  - ok_actions (list(string), default []): Actions to take when alarm state is OK
  - insufficient_data_actions (list(string), default []): Actions to take when alarm state is INSUFFICIENT_DATA
  - treat_missing_data (string, default "missing"): How to treat missing data
  - unit (string, optional): Unit of the metric
  - dimensions (map(string), optional): Dimensions for the metric

- **enable_detailed_monitoring_alarms (bool, default false)**: Enable detailed monitoring alarms
- **memory_utilization_alarms (bool, default false)**: Enable memory utilization alarms (requires CloudWatch agent)
- **custom_metrics_alarms (map(object), default {}): Custom metrics alarms**

### Scheduled Actions

- **scheduled_actions (map(object), default {}): Scheduled actions for time-based scaling**
  - min_size (number): Minimum size for the scheduled action
  - max_size (number): Maximum size for the scheduled action
  - desired_capacity (number): Desired capacity for the scheduled action
  - start_time (string, optional): Start time for the scheduled action
  - end_time (string, optional): End time for the scheduled action
  - recurrence (string, optional): Recurrence pattern (cron expression)
  - time_zone (string, optional): Time zone for the scheduled action

### Predictive Scaling

- **Note**: Predictive scaling is not currently supported in the AWS provider version used by this module. This feature will be added when the provider supports it.

### Instance Refresh

- **instance_refresh (object, default {}): Rolling update configuration for zero-downtime AMI updates**
  - strategy (string, default "Rolling"): Instance refresh strategy
  - preferences (object): Rolling update preferences
    - min_healthy_percentage (number, default 50): Minimum percentage of healthy instances during update
    - instance_warmup (number, default 300): Time in seconds for instance warmup
    - checkpoint_percentages (list(number), default [20, 50, 100]): Progress checkpoints
    - checkpoint_delay (number, default 3600): Delay between checkpoints
    - scale_in_protected_instances (string, default "Ignore"): How to handle protected instances
    - standby_instances (string, default "Ignore"): How to handle standby instances

## Outputs

### Basic Outputs

- asg_id, asg_arn, asg_name
- launch_template_id, launch_template_arn, launch_template_latest_version
- desired_capacity, min_size, max_size
- instance_refresh_enabled, instance_refresh_strategy, instance_refresh_trigger_id

### Scaling Policy Outputs

- target_tracking_scaling_policies: Map of target tracking scaling policies
- step_scaling_policies: Map of step scaling policies
- simple_scaling_policies: Map of simple scaling policies
- predictive_scaling_policy: Not available in current AWS provider version

### CloudWatch Alarms Outputs

- scaling_alarms: Map of CloudWatch scaling alarms
- memory_alarms: Map of memory utilization alarms
- custom_metrics_alarms: Map of custom metrics alarms

### Scheduled Actions Outputs

- scheduled_actions: Map of scheduled actions

### Scaling Configuration Summary

- scaling_enabled: Whether auto scaling is enabled
- scaling_policies_count: Total number of scaling policies created
- cloudwatch_alarms_count: Total number of CloudWatch alarms created

## Requirements

- Terraform ~> 1.3
- AWS provider ~> 5.97.0
- **AWS CLI** (for rolling updates) - Must be installed and configured with appropriate permissions

See terraform.tf in this module for provider constraints.

## Advanced Usage Examples

### Production-Ready Configuration with Multiple Scaling Policies

```hcl
module "production_asg" {
  source = "../../devops-terraform-modules/aws/autoscaling-group"

  name                 = "production-web-asg"
  vpc_zone_identifier  = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  min_size         = 3
  max_size         = 20
  desired_capacity = 5

  ami_id         = data.aws_ami.ubuntu.id
  instance_type  = "c5.large"
  key_name       = "production-key"
  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Enable comprehensive scaling
  enable_scaling_policies = true

  # Target tracking scaling (primary scaling method)
  target_tracking_scaling_policies = {
    cpu = {
      target_value                = 70.0
      disable_scale_in           = false
      estimated_instance_warmup  = 300
    }
    network_in = {
      target_value                = 1000000000  # 1 GB/s
      disable_scale_in           = false
      estimated_instance_warmup  = 300
      predefined_metric_specification = {
        predefined_metric_type = "ASGAverageNetworkIn"
        resource_label        = null
      }
    }
  }

  # Step scaling for additional control
  step_scaling_policies = {
    high_cpu_step = {
      adjustment_type          = "ChangeInCapacity"
      cooldown                = 300
      metric_aggregation_type = "Average"
      scaling_adjustments = [
        {
          metric_interval_lower_bound = 0
          metric_interval_upper_bound = 10
          scaling_adjustment          = 1
        },
        {
          metric_interval_lower_bound = 10
          metric_interval_upper_bound = 20
          scaling_adjustment          = 2
        },
        {
          metric_interval_lower_bound = 20
          scaling_adjustment          = 3
        }
      ]
    }
  }

  # CloudWatch alarms for monitoring
  cloudwatch_alarms = {
    high_cpu = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "High CPU utilization"
    }
    low_cpu = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 20
      alarm_description   = "Low CPU utilization"
    }
  }

  # Memory utilization alarms (requires CloudWatch agent)
  memory_utilization_alarms = true

  # Custom metrics alarms
  custom_metrics_alarms = {
    high_response_time = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ResponseTime"
      namespace           = "MyApp/Web"
      period              = 300
      statistic           = "Average"
      threshold           = 2000  # 2 seconds
      alarm_description   = "High response time"
      dimensions = {
        Environment = "production"
      }
    }
  }

  # Scheduled actions for predictable traffic patterns
  scheduled_actions = {
    business_hours = {
      min_size         = 5
      max_size         = 15
      desired_capacity = 8
      recurrence       = "0 9 * * MON-FRI"  # 9 AM weekdays
      time_zone        = "UTC"
    }
    night_scale_down = {
      min_size         = 2
      max_size         = 8
      desired_capacity = 3
      recurrence       = "0 22 * * *"  # 10 PM daily
      time_zone        = "UTC"
    }
  }

  # Note: Predictive scaling is not supported in current AWS provider version

  # Instance refresh for rolling updates
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
      instance_warmup        = 300
      checkpoint_percentages = [20, 50, 100]
      checkpoint_delay       = 60
    }
  }

  # Load balancer integration
  target_group_arns = [aws_lb_target_group.web.arn]
  health_check_type = "ELB"
  wait_for_elb_capacity = 3
  wait_for_capacity_timeout = "15m"

  tags = {
    Environment = "production"
    Project     = "web-app"
    Team        = "platform"
  }
}
```

### Development Environment with Simple Scaling

```hcl
module "dev_asg" {
  source = "../../devops-terraform-modules/aws/autoscaling-group"

  name                 = "dev-web-asg"
  vpc_zone_identifier  = [aws_subnet.private_a.id]

  min_size         = 1
  max_size         = 5
  desired_capacity = 2

  ami_id         = data.aws_ami.ubuntu.id
  instance_type  = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]

  # Simple scaling configuration
  enable_scaling_policies = true

  target_tracking_scaling_policies = {
    cpu = {
      target_value = 60.0
    }
  }

  # Basic monitoring
  cloudwatch_alarms = {
    high_cpu = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
    }
  }

  tags = {
    Environment = "dev"
    Project     = "web-app"
  }
}
```

## Rolling Updates for Zero-Downtime AMI Updates

This module supports AWS Auto Scaling Group Instance Refresh for zero-downtime rolling updates. When you update the `ami_id` in your configuration and run `terraform apply`, the module will automatically:

1. **Update the launch template** with the new AMI
2. **Trigger an instance refresh** that launches new instances with the updated AMI
3. **Wait for health checks** to pass on new instances
4. **Terminate old instances** in a rolling fashion
5. **Maintain minimum capacity** throughout the process

### Key Configuration for Rolling Updates

```hcl
instance_refresh = {
  strategy = "Rolling"
  preferences = {
    min_healthy_percentage = 50  # Keep at least 50% healthy during update
    instance_warmup        = 300 # Wait 5 minutes for instances to warm up
    checkpoint_percentages = [20, 50, 100] # Progress checkpoints
    checkpoint_delay       = 3600 # 1 hour delay between checkpoints
  }
}

# Wait for healthy instances in load balancer
wait_for_elb_capacity = 2
wait_for_capacity_timeout = "10m"
```

### How to Trigger Rolling Updates

To perform a rolling AMI update:

1. **Update the AMI ID** in your configuration:

   ```hcl
   ami_id = "ami-0newami1234567890" # New AMI ID
   ```

2. **Run Terraform apply**:

   ```bash
   terraform plan  # Review changes
   terraform apply # Apply changes and trigger rolling update
   ```

3. **Monitor the progress**:
   ```bash
   # Check instance refresh status
   aws autoscaling describe-instance-refreshes --auto-scaling-group-name your-asg-name
   ```

## Best Practices

### 1. Scaling Policy Selection

**Target Tracking Scaling (Recommended)**

- Use for most applications
- Automatically maintains target metric value
- Simpler configuration and management
- Good for CPU, network, and request count metrics

**Step Scaling**

- Use when you need fine-grained control
- Good for complex scaling logic
- Requires CloudWatch alarms
- Better for applications with predictable scaling patterns

**Simple Scaling**

- Use for basic scaling needs
- One scaling action per alarm
- Simpler but less flexible than step scaling

### 2. CloudWatch Alarms Configuration

```hcl
# Good alarm configuration
cloudwatch_alarms = {
  high_cpu = {
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2  # Require 2 consecutive periods
    period              = 300 # 5-minute periods
    statistic           = "Average"
    threshold           = 80
    treat_missing_data  = "breaching"  # Treat missing data as breaching
  }
}
```

### 3. Scaling Cooldowns

- **Scale-out cooldown**: 300-600 seconds (5-10 minutes)
- **Scale-in cooldown**: 300-900 seconds (5-15 minutes)
- **Instance warmup**: 300-600 seconds (5-10 minutes)

### 4. Health Checks

```hcl
# Use ELB health checks for better application health validation
health_check_type = "ELB"
health_check_grace_period = 300  # 5 minutes

# Wait for healthy instances in load balancer
wait_for_elb_capacity = 2
wait_for_capacity_timeout = "10m"
```

### 5. Instance Refresh Best Practices

1. **Use ELB health checks**: Set `health_check_type = "ELB"` for better health validation
2. **Configure appropriate timeouts**: Adjust `wait_for_capacity_timeout` based on your application startup time
3. **Set minimum healthy percentage**: Keep at least 50% of instances healthy during updates
4. **Automatic triggering**: Instance refresh automatically triggers when the AMI changes
5. **Monitor progress**: Use checkpoint percentages to track update progress

### 6. Memory Monitoring

For memory utilization alarms, install the CloudWatch agent:

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Configure for memory monitoring
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

### 7. Cost Optimization

- **Right-size instances**: Choose appropriate instance types
- **Set appropriate thresholds**: Avoid over-scaling
- **Use scheduled actions**: Scale down during off-hours
- **Monitor costs**: Use AWS Cost Explorer to track scaling costs

### 8. Security Considerations

- **IAM permissions**: Ensure ASG has necessary permissions for scaling
- **Security groups**: Configure appropriate security group rules
- **Instance protection**: Use `protect_from_scale_in` for critical instances
- **Encryption**: Enable EBS encryption for data at rest
