# Timezone Update - Using AWS Native Timezone Support

## ✅ What Changed

### Before (Old Approach):
- Terraform converted local time to UTC (23:30 UTC+7 → 16:30 UTC)
- Sent UTC cron to AWS: `30 16 * * MON-FRI`
- AWS used default UTC timezone
- **Problem**: Cron looked confusing (16:30 instead of 23:30)

### After (New Approach - Better!):
- Keep cron in **local time**: `30 23 * * MON-FRI`
- Set AWS `time_zone` parameter: `Asia/Bangkok`
- AWS handles timezone conversion automatically
- **Benefit**: Cron is readable and shows actual local time!

## 📊 Comparison

| Aspect | Old (UTC Conversion) | New (AWS Timezone) |
|--------|---------------------|-------------------|
| Cron expression | `30 16 * * MON-FRI` (UTC) | `30 23 * * MON-FRI` (local) |
| time_zone | `UTC` (default) | `Asia/Bangkok` |
| Execution time | 16:30 UTC = 23:30 UTC+7 ✅ | 23:30 Asia/Bangkok ✅ |
| Readability | ❌ Confusing (shows UTC) | ✅ Clear (shows local time) |
| DST handling | ❌ Manual updates needed | ✅ AWS handles automatically |
| Maintenance | ❌ Need to recalculate if timezone changes | ✅ Just update timezone_offset |

## 🌍 Supported Timezones

The module now maps timezone offsets to AWS IANA timezone names:

| Offset | Timezone Name | Example Location |
|--------|---------------|------------------|
| -8 | America/Los_Angeles | Pacific Time |
| -5 | America/New_York | Eastern Time |
| 0 | UTC | Universal |
| 1 | Europe/London | UK |
| 2 | Europe/Berlin | Central Europe |
| 7 | Asia/Bangkok | Thailand, Vietnam, Indonesia (West) |
| 8 | Asia/Singapore | Singapore, Malaysia, China |
| 9 | Asia/Tokyo | Japan, Korea |
| 10 | Australia/Sydney | Australian Eastern |

## 📝 Your Configuration

### What You Write (Local Time):
```hcl
node_group_schedules = {
  runners = {
    timezone_offset = 7  # UTC+7
    scale_down = {
      hour   = 23    # 11:30 PM - your local time!
      minute = 30
      days   = "MON-FRI"
      # ... other settings
    }
  }
}
```

### What AWS Creates:
```hcl
resource "aws_autoscaling_schedule" {
  recurrence = "30 23 * * MON-FRI"  # Local time (readable!)
  time_zone  = "Asia/Bangkok"        # AWS handles conversion
}
```

### When It Executes:
- **In Bangkok (UTC+7)**: 23:30 (11:30 PM)
- **In UTC**: 16:30 (AWS converts automatically)
- **If DST existed**: AWS would adjust automatically

## ✅ Benefits

1. **More Readable**: Cron shows actual local time
2. **Less Error-Prone**: No manual timezone math
3. **DST Handling**: AWS handles daylight saving automatically (where applicable)
4. **Clearer Debugging**: When you see `30 23 * * MON-FRI`, you immediately know it's 11:30 PM local
5. **Easier Updates**: Just change `timezone_offset` if you move regions

## 🔍 Example Output

After applying, you'll see:

```hcl
# module.common_infra_nonprod_eks.aws_autoscaling_schedule.node_group_schedules["runners-scale-down"]
resource "aws_autoscaling_schedule" "node_group_schedules" {
  autoscaling_group_name = "eks-common-infra-nonprod-eks-runners-624d-..."
  desired_capacity       = 0
  max_size              = 0
  min_size              = 0
  recurrence            = "30 23 * * MON-FRI"  # 11:30 PM local time!
  time_zone             = "Asia/Bangkok"        # UTC+7 timezone
  scheduled_action_name  = "common-infra-nonprod-eks-runners-scale-down"
}
```

Much clearer than:
```hcl
  recurrence            = "30 16 * * MON-FRI"  # What time is this? 🤔
  time_zone             = "UTC"
```

## 🚀 Migration

If you already have schedules using the old UTC approach:
1. The new plan will show updates to existing resources (changing recurrence and time_zone)
2. **This is safe** - AWS will update the schedules without disruption
3. The actual execution time remains the same

## 📚 AWS Documentation

- [Auto Scaling Scheduled Actions](https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html)
- [Supported Timezones (IANA Database)](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
