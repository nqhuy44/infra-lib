resource "aws_efs_file_system" "this" {
  creation_token                  = var.creation_token != null ? var.creation_token : var.name
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  tags                            = var.tags

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != null || var.transition_to_primary_storage_class != null ? [1] : []
    content {
      transition_to_ia                    = var.transition_to_ia
      transition_to_primary_storage_class = var.transition_to_primary_storage_class
    }
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = var.security_group_ids
}

resource "aws_efs_backup_policy" "this" {
  count = var.backup_policy_enabled ? 1 : 0

  file_system_id = aws_efs_file_system.this.id
  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_access_point" "this" {
  count = var.create_access_point ? 1 : 0

  file_system_id = aws_efs_file_system.this.id
  posix_user {
    gid            = var.access_point_posix_user_gid
    uid            = var.access_point_posix_user_uid
    secondary_gids = var.access_point_posix_user_secondary_gids
  }
  root_directory {
    path = var.access_point_root_directory_path
    creation_info {
      owner_gid   = var.access_point_root_directory_owner_gid
      owner_uid   = var.access_point_root_directory_owner_uid
      permissions = var.access_point_root_directory_permissions
    }
  }
  tags = var.access_point_tags
}

resource "aws_efs_file_system_policy" "this" {
  count = var.attach_file_system_policy ? 1 : 0

  file_system_id = aws_efs_file_system.this.id
  policy         = var.file_system_policy
}

resource "aws_efs_replication_configuration" "this" {
  count = var.enable_replica ? 1 : 0

  source_file_system_id = aws_efs_file_system.this.id
  destination {
    availability_zone_name = var.replica_availability_zone_name
    file_system_id         = var.replica_file_system_id
    kms_key_id             = var.replica_kms_key_id
    region                 = var.replica_region
  }
}
