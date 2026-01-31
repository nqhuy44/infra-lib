# AWS AMI module

Creates AMIs from EC2 instances with retention. You can either:

- Enable AWS DLM lifecycle policy for scheduled AMIs, or
- Trigger AMI creation manually on demand (no schedule).

## Inputs

- `name` (string, required)
- `description` (string, optional)
- `target_tags` (map(string), default `{}`): Instances with these tags are targeted.
- `enable_dlm` (bool, default `false`): If true, create a DLM schedule.
- `schedule_interval` (number, default `24`)
- `schedule_interval_unit` (string: `HOURS|DAYS|WEEKS`, default `HOURS`)
- `schedule_times` (list(string), default `["23:45"]`): UTC times `HH:MM`.
- `retention_count` (number, default `7`)
- `copy_tags` (bool, default `true`)
- `policy_state` (string: `ENABLED|DISABLED`, default `ENABLED`)
- `tags` (map(string), default `{}`)
- `create_ami_now` (bool, default `false`)
- `instance_id` (string, optional)
- `ami_now_name_suffix` (string, default `manual`)
- `ami_now_no_reboot` (bool, default `true`)
- `manual_triggers` (set(string), default `[]`): Add a new token to force-create an AMI.
- `manual_retention_count` (number, default `5`): Keep only the last N manual AMIs (by token order).

## Outputs

- `dlm_policy_id`
- `ami_now_id`
- `manual_ami_ids`

## Example

```hcl
module "ami" {
  source  = "../aws/ami"
  name    = "myapp-ami"
  target_tags = {
    "Backup" = "true"
    "Role"   = "web"
  }
  schedule_interval       = 24
  schedule_interval_unit  = "HOURS"
  schedule_times          = ["01:00"]
  retention_count         = 14
  policy_state            = "ENABLED"
  tags = {
    Project = "myapp"
  }
}

# Manual one-off AMIs (on demand)
module "ami_now" {
  source          = "../aws/ami"
  name            = "myapp-ami"
  enable_dlm      = false
  create_ami_now  = true
  instance_id     = aws_instance.app.id
  ami_now_no_reboot = true
  tags = {
    Project = "myapp"
  }
}

# Trigger additional AMIs by changing the set
module "ami_manual_triggers" {
  source           = "../aws/ami"
  name             = "myapp-ami"
  instance_id      = aws_instance.app.id
  enable_dlm       = false
  manual_triggers  = ["2025-10-01-a", "2025-10-01-b"]
  manual_retention_count = 5
}

## Naming

- One-off immediate AMIs: `<name>-<YYYYMMDD>-<random_suffix>`
- Manual triggers: `<name>-<YYYYMMDD>-<token>-<random_suffix>`
```

## Notes

- This module uses the AWS-managed DLM role `AWSDataLifecycleManagerDefaultRole`. Ensure it exists or create a custom role and adjust if needed.
- `target_tags` drive which instances are targeted by the schedule.
- DLM enforces retention by AMI count per instance.


