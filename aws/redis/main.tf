locals {
  # Create consistent resource naming
  name_prefix = var.name_prefix != null ? var.name_prefix : var.name

  # Determine final parameter group name
  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.custom[0].name : var.parameter_group_name

  # Determine final subnet group name
  subnet_group_name = var.create_subnet_group ? aws_elasticache_subnet_group.custom[0].name : var.subnet_group_name

  # Tags to apply to all resources
  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

# --- ElastiCache Subnet Group ---
resource "aws_elasticache_subnet_group" "custom" {
  count = var.create_subnet_group ? 1 : 0

  name        = "${local.name_prefix}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = var.subnet_group_description != null ? var.subnet_group_description : "Subnet group for ${var.name} Redis cluster"

  tags = local.tags
}

# --- ElastiCache Parameter Group ---
resource "aws_elasticache_parameter_group" "custom" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${local.name_prefix}-params"
  family      = var.parameter_group_family # Should be "redis7" not "redis7.0"
  description = var.parameter_group_description != null ? var.parameter_group_description : "Parameter group for ${var.name} Redis cluster"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.tags
}

# --- ElastiCache Redis Replication Group ---
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = var.description != null ? var.description : "${var.name} Redis cluster"

  # Node configuration
  node_type      = var.node_type
  engine_version = var.engine_version
  port           = var.port

  # Network configuration
  subnet_group_name  = local.subnet_group_name
  security_group_ids = var.security_group_ids

  # Configuration settings
  parameter_group_name = local.parameter_group_name

  # Conditionally set parameters based on cluster mode
  # Only one set of these parameters can be used at a time
  num_cache_clusters = var.cluster_mode_enabled ? null : var.num_cache_clusters

  # Only set these when using cluster mode
  num_node_groups         = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group = var.cluster_mode_enabled ? var.replicas_per_node_group : null

  # Multi-AZ & Failover
  multi_az_enabled            = var.multi_az_enabled
  automatic_failover_enabled  = var.automatic_failover_enabled
  preferred_cache_cluster_azs = var.preferred_cache_cluster_azs

  # Auth & Encryption
  auth_token                 = var.auth_token
  auth_token_update_strategy = var.auth_token_update_strategy
  transit_encryption_enabled = var.transit_encryption_enabled
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.kms_key_id

  # Backup & maintenance
  snapshot_name            = var.snapshot_name
  snapshot_arns            = var.snapshot_arns
  snapshot_window          = var.snapshot_window
  snapshot_retention_limit = var.snapshot_retention_limit
  maintenance_window       = var.maintenance_window
  notification_topic_arn   = var.notification_topic_arn

  # Advanced settings
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = local.tags
}
