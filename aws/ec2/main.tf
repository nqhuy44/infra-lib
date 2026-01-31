locals {
  # Simply use the provided name or a default
  instance_name = var.name != null ? var.name : "instance"

  # Create a boolean to determine if root volume encryption is needed
  encrypt_root = var.encrypt_root_volume != null ? var.encrypt_root_volume : var.encrypt_all_volumes

  # GPU validation - only validate when GPU is enabled
  is_gpu_instance_type = var.gpu_enabled ? contains([for prefix in var.gpu_instance_type_prefixes :
  can(regex("^${prefix}.*", var.instance_type))], true) : true

  # Default root volume settings merged with any user overrides
  root_volume = merge({
    volume_type = "gp3"
    volume_size = 20
    encrypted   = local.encrypt_root
    kms_key_id  = var.kms_key_id
    tags        = var.tags
  }, var.root_volume)

}

# Add validation for GPU instances
resource "null_resource" "gpu_validation" {
  count = var.create_instance ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.is_gpu_instance_type
      error_message = "When gpu_enabled=true, you must select an instance type that supports GPUs (g3, g4, g5, p2, p3, p4, p5, etc.)"
    }
  }
}

resource "aws_network_interface" "additional" {
  for_each = { for ni in var.network_interfaces : ni.device_index => ni }

  subnet_id       = each.value.subnet_id
  security_groups = each.value.security_groups
  private_ips     = each.value.private_ip != null ? [each.value.private_ip] : null
  tags            = merge(var.tags, try(each.value.tags, {}))
}

# --- EC2 Instance ---
resource "aws_instance" "this" {
  count = var.create_instance ? 1 : 0

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  key_name                    = var.key_name
  monitoring                  = var.enable_detailed_monitoring
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = var.associate_public_ip_address
  availability_zone           = var.availability_zone
  placement_group             = var.placement_group
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  hibernation                 = var.hibernation
  enable_primary_ipv6         = var.enable_primary_ipv6
  source_dest_check           = var.source_dest_check
  disable_api_termination     = var.disable_api_termination
  private_ip                  = var.private_ip
  tenancy                     = var.tenancy
  host_id                     = var.host_id

  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }

  root_block_device {
    volume_type           = local.root_volume.volume_type
    volume_size           = local.root_volume.volume_size
    encrypted             = local.root_volume.encrypted
    kms_key_id            = local.root_volume.encrypted ? local.root_volume.kms_key_id : null
    delete_on_termination = true
  }

  # Additional EBS volumes
  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes

    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = try(ebs_block_device.value.volume_type, "gp3")
      volume_size           = ebs_block_device.value.volume_size
      iops                  = try(ebs_block_device.value.iops, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      encrypted             = try(ebs_block_device.value.encrypted, var.encrypt_all_volumes)
      kms_key_id            = try(ebs_block_device.value.kms_key_id, var.kms_key_id)
      delete_on_termination = try(ebs_block_device.value.delete_on_termination, true)
      tags                  = merge(var.tags, try(ebs_block_device.value.tags, {}))
    }
  }

  # Additional network interfaces
  dynamic "network_interface" {
    for_each = { for ni in var.network_interfaces : ni.device_index => ni }

    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = aws_network_interface.additional[network_interface.value.device_index].id
      delete_on_termination = try(network_interface.value.delete_on_termination, false)
    }
  }

  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options.instance_metadata_tags
  }

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  enclave_options {
    enabled = var.enclave_options.enabled
  }

  tags = merge(var.tags, {
    Name = local.instance_name
  })

  # volume_tags = merge(var.tags, var.volume_tags, {
  #   Name = "${local.instance_name}-volume"
  # })

  lifecycle {
    ignore_changes = [
      tags,
      user_data,
      user_data_base64,
    ]
  }
}

resource "aws_ec2_instance_state" "this" {
  count       = var.create_instance ? 1 : 0
  instance_id = aws_instance.this[0].id
  state       = var.state
}
