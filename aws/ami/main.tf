locals {
  dlm_description = coalesce(var.description, "Lifecycle policy for AMIs created from EC2 instances")
  manual_tokens_kept = var.manual_retention_count > 0 && length(var.manual_triggers) > var.manual_retention_count ? slice(
    var.manual_triggers,
    length(var.manual_triggers) - var.manual_retention_count,
    length(var.manual_triggers)
  ) : var.manual_triggers
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_dlm_lifecycle_policy" "this" {
  count              = var.enable_dlm ? 1 : 0
  description        = local.dlm_description
  execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSDataLifecycleManagerDefaultRole"
  state              = var.policy_state
  tags               = var.tags

  policy_details {
    policy_type    = "IMAGE_MANAGEMENT"
    resource_types = ["INSTANCE"]

    target_tags = var.target_tags

    schedule {
      name = var.name

      create_rule {
        interval      = var.schedule_interval
        interval_unit = var.schedule_interval_unit
        times         = var.schedule_times
      }

      retain_rule {
        count = var.retention_count
      }

      copy_tags = var.copy_tags
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_ami_from_instance" "now" {
  count               = var.create_ami_now && var.instance_id != null ? 1 : 0
  name                = "${var.name}-${formatdate("YYYYMMDD", timestamp())}-${random_id.suffix.hex}"
  description         = "One-off AMI created by Terraform from instance ${var.instance_id}"
  source_instance_id  = var.instance_id
  snapshot_without_reboot = var.ami_now_no_reboot
  tags                = merge(var.tags, { "Name" = "${var.name}-${var.ami_now_name_suffix}" })
  
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_ami_from_instance" "manual" {
  for_each            = var.instance_id != null ? toset(local.manual_tokens_kept) : []
  name                = "${var.name}-${each.value}-${random_id.manual_suffix[each.value].hex}"
  description         = "Manually triggered AMI from instance ${var.instance_id} (token: ${each.value})"
  source_instance_id  = var.instance_id
  snapshot_without_reboot = var.ami_now_no_reboot
  tags                = merge(var.tags, { "Name" = "${var.name}-manual-${each.value}" })
}

resource "random_id" "manual_suffix" {
  for_each    = var.instance_id != null ? toset(local.manual_tokens_kept) : []
  byte_length = 3
}


