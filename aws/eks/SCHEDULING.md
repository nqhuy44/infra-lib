# EKS Node Group Scheduled Scaling

This document provides a quick reference guide for the scheduled scaling feature added to the EKS Terraform module.

## Overview

The scheduled scaling feature allows you to automatically scale your EKS node groups up and down based on time-based schedules. This is ideal for:

- **Cost optimization**: Scale down non-production environments during off-hours
- **Predictable workloads**: Match capacity to known usage patterns
- **Development environments**: Completely shut down outside business hours
- **CI/CD runners**: Scale based on team working hours

## Quick Start

### 1. Define Your Node Groups

```hcl
eks_managed_node_groups = {
  dev-workloads = {
    instance_types = ["t3a.2xlarge"]
    min_size       = 1
    max_size       = 20
    desired_size   = 5
  }
}
```

### 2. Add Scheduling Configuration (Using Your Local Timezone - Recommended!)

```hcl
node_group_schedules = {
  dev-workloads = {
    timezone_offset = 7  # Set your timezone offset (e.g., 7 for UTC+7, -5 for UTC-5)
    
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      hour         = 20    # 8 PM in YOUR local time
      minute       = 0
      days         = "MON-FRI"
    }
    scale_up = {
      min_size     = 1
      max_size     = 20
      desired_size = 5
      hour         = 6     # 6 AM in YOUR local time
      minute       = 0
      days         = "MON-FRI"
    }
  }
}
```

**That's it!** The module automatically converts your local time to UTC. No manual conversion needed!

### Alternative: Using UTC Cron Expressions (Legacy Method)

If you prefer to use traditional cron expressions in UTC:

```hcl
node_group_schedules = {
  dev-workloads = {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      recurrence   = "0 20 * * MON-FRI"  # Manual UTC time
    }
    scale_up = {
      min_size     = 1
      max_size     = 20
      desired_size = 5
      recurrence   = "0 6 * * MON-FRI"   # Manual UTC time
    }
  }
}
```

## Timezone Support

The module now supports **automatic timezone conversion**! You can specify schedules in your local time, and the module will handle the UTC conversion automatically.

### Common Timezone Offsets

| Region/City | Timezone | Offset | timezone_offset Value |
|-------------|----------|--------|----------------------|
| 🇺🇸 New York (EST/EDT) | UTC-5/-4 | Winter: -5, Summer: -4 | `-5` or `-4` |
| 🇺🇸 Los Angeles (PST/PDT) | UTC-8/-7 | Winter: -8, Summer: -7 | `-8` or `-7` |
| 🇬🇧 London (GMT/BST) | UTC+0/+1 | Winter: 0, Summer: +1 | `0` or `1` |
| 🇩🇪 Berlin/Paris (CET/CEST) | UTC+1/+2 | Winter: +1, Summer: +2 | `1` or `2` |
| 🇦🇪 Dubai | UTC+4 | Year-round | `4` |
| 🇮🇳 India | UTC+5:30 | Year-round* | `5` (Note: .5 not supported) |
| 🇨🇳 China/Singapore | UTC+8 | Year-round | `8` |
| 🇹🇭 Bangkok/Hanoi/Jakarta | UTC+7 | Year-round | `7` |
| 🇯🇵 Tokyo | UTC+9 | Year-round | `9` |
| 🇦🇺 Sydney (AEDT/AEST) | UTC+11/+10 | Summer: +11, Winter: +10 | `11` or `10` |

*Note: Timezones with 30/45-minute offsets (like India UTC+5:30) are not fully supported. Use the nearest hour offset.

### Days Format Reference

| Days Value | Description |
|------------|-------------|
| `"MON-FRI"` | Monday through Friday (weekdays) |
| `"*"` | Every day |
| `"MON"` | Mondays only |
| `"MON,WED,FRI"` | Specific days (comma-separated) |
| `"SAT,SUN"` | Weekends only |
| `"MON-THU"` | Monday through Thursday |

## Cron Expression Reference (Legacy Method)

If you prefer using traditional cron expressions, you'll need to manually convert to UTC.

Format: `minute hour day-of-month month day-of-week`

| Expression | Description |
|------------|-------------|
| `0 20 * * MON-FRI` | 8 PM UTC, Monday through Friday |
| `0 6 * * MON-FRI` | 6 AM UTC, Monday through Friday |
| `0 22 * * *` | 10 PM UTC, every day |
| `0 18 * * FRI` | 6 PM UTC, every Friday |
| `0 8 * * MON` | 8 AM UTC, every Monday |
| `30 12 * * 1-5` | 12:30 PM UTC, Monday through Friday |
| `0 0 * * SAT,SUN` | Midnight UTC, weekends only |

**Important**: When using `recurrence`, all times must be in **UTC timezone**.

## Timezone Examples by Region

### Asia Pacific

**Bangkok/Hanoi/Jakarta (UTC+7)**
```hcl
node_group_schedules = {
  workloads = {
    timezone_offset = 7
    scale_down = {
      hour   = 23    # 11 PM local
      minute = 30
      days   = "MON-FRI"
      # ... other settings
    }
    scale_up = {
      hour   = 7     # 7 AM local
      minute = 30
      days   = "MON-FRI"
      # ... other settings
    }
  }
}
```

**Singapore/Beijing/Perth (UTC+8)**
```hcl
timezone_offset = 8
scale_down = { hour = 22, minute = 0, days = "MON-FRI" }  # 10 PM local
scale_up = { hour = 8, minute = 0, days = "MON-FRI" }     # 8 AM local
```

**Tokyo/Seoul (UTC+9)**
```hcl
timezone_offset = 9
scale_down = { hour = 21, minute = 0, days = "MON-FRI" }  # 9 PM local
scale_up = { hour = 7, minute = 0, days = "MON-FRI" }     # 7 AM local
```

**Sydney (UTC+10/+11)**
```hcl
timezone_offset = 11  # Summer (AEDT), use 10 for Winter (AEST)
scale_down = { hour = 20, minute = 0, days = "MON-FRI" }  # 8 PM local
scale_up = { hour = 6, minute = 0, days = "MON-FRI" }     # 6 AM local
```

### Europe

**London (UTC+0/+1)**
```hcl
timezone_offset = 1  # Summer (BST), use 0 for Winter (GMT)
scale_down = { hour = 20, minute = 0, days = "MON-FRI" }  # 8 PM local
scale_up = { hour = 8, minute = 0, days = "MON-FRI" }     # 8 AM local
```

**Berlin/Paris/Madrid (UTC+1/+2)**
```hcl
timezone_offset = 2  # Summer (CEST), use 1 for Winter (CET)
scale_down = { hour = 22, minute = 0, days = "MON-FRI" }  # 10 PM local
scale_up = { hour = 7, minute = 0, days = "MON-FRI" }     # 7 AM local
```

### Americas

**New York (UTC-5/-4)**
```hcl
timezone_offset = -4  # Summer (EDT), use -5 for Winter (EST)
scale_down = { hour = 20, minute = 0, days = "MON-FRI" }  # 8 PM local
scale_up = { hour = 6, minute = 0, days = "MON-FRI" }     # 6 AM local
```

**Los Angeles (UTC-8/-7)**
```hcl
timezone_offset = -7  # Summer (PDT), use -8 for Winter (PST)
scale_down = { hour = 22, minute = 0, days = "MON-FRI" }  # 10 PM local
scale_up = { hour = 7, minute = 0, days = "MON-FRI" }     # 7 AM local
```

**São Paulo (UTC-3)**
```hcl
timezone_offset = -3
scale_down = { hour = 19, minute = 0, days = "MON-FRI" }  # 7 PM local
scale_up = { hour = 8, minute = 0, days = "MON-FRI" }     # 8 AM local
```

## Common Patterns

### Pattern 1: Weekday Business Hours Only

Scale down outside 9 AM - 6 PM local time on weekdays:

```hcl
node_group_schedules = {
  dev-workloads = {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      recurrence   = "0 22 * * MON-FRI"  # Adjust for your timezone
    }
    scale_up = {
      min_size     = 2
      max_size     = 20
      desired_size = 5
      recurrence   = "0 13 * * MON-FRI"  # Adjust for your timezone
    }
  }
}
```

**Cost Savings**: ~70% (running 9 hours/day × 5 days = 45 hours/week vs 168 hours)

### Pattern 2: Weekend Shutdown

Keep running during the week, shut down on weekends:

```hcl
node_group_schedules = {
  staging-cluster = {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      recurrence   = "0 18 * * FRI"  # Friday 6 PM
    }
    scale_up = {
      min_size     = 2
      max_size     = 15
      desired_size = 4
      recurrence   = "0 8 * * MON"   # Monday 8 AM
    }
  }
}
```

**Cost Savings**: ~30% (running 120 hours/week vs 168 hours)

### Pattern 3: Minimal Overnight Capacity

Reduce capacity at night but maintain minimum nodes:

```hcl
node_group_schedules = {
  production-workers = {
    scale_down = {
      min_size     = 2      # Keep minimum nodes running
      max_size     = 10
      desired_size = 2
      recurrence   = "0 22 * * *"  # 10 PM every day
    }
    scale_up = {
      min_size     = 5
      max_size     = 50
      desired_size = 10
      recurrence   = "0 6 * * *"   # 6 AM every day
    }
  }
}
```

**Cost Savings**: ~40-50% depending on usage

### Pattern 4: Multiple Node Groups with Different Schedules

```hcl
node_group_schedules = {
  # Development workloads - aggressive cost savings
  dev-workloads = {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      recurrence   = "0 20 * * MON-FRI"
    }
    scale_up = {
      min_size     = 1
      max_size     = 20
      desired_size = 5
      recurrence   = "0 6 * * MON-FRI"
    }
  }
  
  # GitHub runners - scale down later (after builds complete)
  github-runners = {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      recurrence   = "0 23 * * *"  # 11 PM every day
    }
    scale_up = {
      min_size     = 1
      max_size     = 10
      desired_size = 3
      recurrence   = "0 5 * * MON-FRI"  # 5 AM weekdays
    }
  }
  
  # Note: System node group has no schedule - always running
}
```

## Best Practices

### 1. **Don't Schedule System/Critical Node Groups**
- Keep at least one node group running 24/7 for system components (CoreDNS, monitoring, etc.)
- Only schedule application/workload node groups

### 2. **Graceful Shutdown**
- Use Kubernetes Pod Disruption Budgets (PDBs) to ensure graceful pod evictions
- Set appropriate termination grace periods on your pods
- Consider using node taints/tolerations to control pod placement

### 3. **Testing**
- Test schedules in non-production first
- Verify workloads recover correctly after scale-up
- Monitor for issues during the first few schedule cycles

### 4. **Monitoring**
```bash
# Check scheduled actions
aws autoscaling describe-scheduled-actions \
  --auto-scaling-group-name <asg-name>

# View via Terraform outputs
terraform output node_group_scheduled_actions
terraform output node_group_asg_names
```

### 5. **Combine with Cluster Autoscaler**
- Scheduled scaling sets the boundaries (min/max/desired)
- Cluster Autoscaler handles dynamic scaling within those boundaries
- Enable both for optimal cost and performance

```hcl
enable_cluster_autoscaler = true

node_group_schedules = {
  workloads = {
    scale_down = {
      min_size     = 1      # CA can scale between 1-10
      max_size     = 10
      desired_size = 2
      recurrence   = "0 20 * * MON-FRI"
    }
    scale_up = {
      min_size     = 5      # CA can scale between 5-50
      max_size     = 50
      desired_size = 10
      recurrence   = "0 6 * * MON-FRI"
    }
  }
}
```

## Troubleshooting

### Schedule Not Triggering

1. **Check ASG exists**: `terraform output node_group_asg_names`
2. **Verify schedule created**: `aws autoscaling describe-scheduled-actions`
3. **Check timezone**: Cron expressions use UTC, not your local time
4. **Node group name mismatch**: Keys in `node_group_schedules` must match `eks_managed_node_groups`

### Pods Not Starting After Scale-Up

1. **Check cluster autoscaler logs** (if enabled)
2. **Verify nodes are joining**: `kubectl get nodes`
3. **Check pod events**: `kubectl describe pod <pod-name>`
4. **Ensure sufficient capacity**: Scale-up desired_size should be adequate

### Unexpected Costs

1. **Verify scale-down is working**: Check ASG desired capacity in AWS Console
2. **Check for minimum nodes**: Setting min_size > 0 keeps nodes running
3. **Review other node groups**: Ensure all dev/test groups have schedules
4. **Consider Spot instances**: Use `capacity_type = "SPOT"` for additional savings

## Files Added/Modified

- **variables.tf**: Added `node_group_schedules` variable
- **scheduling.tf**: New file with scheduling resources and data sources
- **outputs.tf**: Added `node_group_scheduled_actions` and `node_group_asg_names` outputs
- **README.md**: Added comprehensive scheduling documentation
- **examples/scheduled-scaling.tf**: Complete usage example

## Technical Details

### How It Works

1. **Data Source**: Discovers Auto Scaling Groups created by EKS managed node groups using tags
2. **Scheduled Actions**: Creates `aws_autoscaling_schedule` resources for each scale-up/down action
3. **Cron-based**: Uses AWS Auto Scaling's native scheduled actions with cron expressions
4. **Per-Node-Group**: Each node group can have independent scale-up and scale-down schedules

### Limitations

- Schedules use UTC timezone only (AWS Auto Scaling limitation)
- Requires EKS managed node groups (not self-managed or Fargate)
- Minimum granularity is 1 minute
- Maximum 125 scheduled actions per Auto Scaling Group

## Additional Resources

- [AWS Auto Scaling Scheduled Actions](https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html)
- [Cron Expression Generator](https://crontab.guru/)
- [EKS Best Practices - Cost Optimization](https://aws.github.io/aws-eks-best-practices/cost_optimization/)
