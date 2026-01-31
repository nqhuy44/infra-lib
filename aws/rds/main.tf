locals {
  # Determine if this is a MySQL or PostgreSQL DB
  is_mysql    = var.engine == "mysql" || var.engine == "aurora-mysql"
  is_postgres = var.engine == "postgres" || var.engine == "aurora-postgresql"

  # Determine if this is an Aurora cluster
  is_aurora = can(regex("^aurora", var.engine))

  port = var.port != null ? var.port : (
    local.is_mysql ? 3306 : local.is_postgres ? 5432 : 1521
  )

  parameter_group_name = var.parameter_group_name != null ? var.parameter_group_name : (
    local.is_aurora ? (
      local.is_mysql ? "default.aurora-mysql8.0" : "default.aurora-postgresql13"
      ) : (
      local.is_mysql ? "default.mysql8.0" : "default.postgres15"
    )
  )

  # Default maintenance and backup windows if not provided
  backup_window      = var.backup_window != null ? var.backup_window : "03:00-06:00"
  maintenance_window = var.maintenance_window != null ? var.maintenance_window : "Sun:07:00-Sun:10:00"
}

# Create DB subnet group
resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = "${var.identifier}-subnet-group"
  description = "Subnet group for ${var.identifier} RDS instance"
  subnet_ids  = var.subnet_ids

  tags = merge(
    var.tags,
    { Name = "${var.identifier}-subnet-group" }
  )
}

# Create parameter group if needed
resource "aws_db_parameter_group" "this" {
  count = (!local.is_aurora && var.create_db_parameter_group) ? 1 : 0

  name        = "${var.identifier}-parameter-group"
  family      = var.parameter_group_family
  description = "Parameter group for ${var.identifier} RDS instance"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    { Name = "${var.identifier}-parameter-group" }
  )
}

# Create cluster parameter group for Aurora if needed
resource "aws_rds_cluster_parameter_group" "this" {
  count = (local.is_aurora && var.create_db_parameter_group) ? 1 : 0

  name        = "${var.identifier}-cluster-parameter-group"
  family      = var.parameter_group_family
  description = "Cluster parameter group for ${var.identifier} Aurora cluster"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    { Name = "${var.identifier}-cluster-parameter-group" }
  )
}

# Create option group for MySQL if needed
resource "aws_db_option_group" "this" {
  count = (!local.is_aurora && local.is_mysql && var.create_db_option_group) ? 1 : 0

  name                     = "${var.identifier}-option-group"
  option_group_description = "Option group for ${var.identifier} RDS instance"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  dynamic "option" {
    for_each = var.options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    var.tags,
    { Name = "${var.identifier}-option-group" }
  )
}

# Create an AWS RDS instance (non-Aurora)
resource "aws_db_instance" "this" {
  count = local.is_aurora ? 0 : 1

  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  iops                  = contains(["io1", "io2"], var.storage_type) ? var.iops : null
  kms_key_id            = var.kms_key_id

  username                            = var.username
  password                            = var.manage_master_user_password ? null : var.password
  manage_master_user_password         = var.manage_master_user_password
  master_user_secret_kms_key_id       = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  parameter_group_name   = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : local.parameter_group_name
  option_group_name      = local.is_mysql && var.create_db_option_group ? aws_db_option_group.this[0].name : null

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible
  db_name             = var.db_name
  port                = local.port

  # Backup and maintenance
  backup_retention_period   = var.backup_retention_period
  backup_window             = local.backup_window
  maintenance_window        = local.maintenance_window
  delete_automated_backups  = var.delete_automated_backups
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYYMMDDHHmmss", timestamp())}"

  # Enhanced monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  # CloudWatch Logs exports
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  # Allow major version upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Apply immediately
  apply_immediately = var.apply_immediately

  tags = merge(
    var.tags,
    { Name = var.identifier }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}

# Create Aurora Cluster 
resource "aws_rds_cluster" "this" {
  count = local.is_aurora ? 1 : 0

  cluster_identifier = var.identifier
  engine             = var.engine
  engine_version     = var.engine_version

  database_name                 = var.db_name
  master_password               = var.manage_master_user_password ? null : var.password
  manage_master_user_password   = var.manage_master_user_password
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  port                          = local.port

  db_subnet_group_name            = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  vpc_security_group_ids          = var.vpc_security_group_ids
  db_cluster_parameter_group_name = local.is_aurora && var.create_db_parameter_group ? aws_rds_cluster_parameter_group.this[0].name : null

  # Encryption
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # Enable IAM authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Backup and maintenance
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = local.backup_window
  preferred_maintenance_window = local.maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYYMMDDHHmmss", timestamp())}"

  # Enhanced monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Serverless v2 scaling properties
  serverlessv2_scaling_configuration {
    min_capacity = var.serverlessv2_min_capacity
    max_capacity = var.serverlessv2_max_capacity
  }

  # Other settings
  apply_immediately   = var.apply_immediately
  deletion_protection = var.deletion_protection

  tags = merge(
    var.tags,
    { Name = var.identifier }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}

# Create Aurora Cluster Instances
resource "aws_rds_cluster_instance" "this" {
  count = local.is_aurora ? var.aurora_instance_count : 0

  identifier         = "${var.identifier}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this[0].id
  engine             = var.engine
  engine_version     = var.engine_version
  instance_class     = local.is_aurora && var.aurora_serverless ? "db.serverless" : var.instance_class

  db_subnet_group_name    = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  db_parameter_group_name = (!local.is_aurora && var.create_db_parameter_group) ? aws_db_parameter_group.this[0].name : var.parameter_group_name

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  # Other settings
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  publicly_accessible        = var.publicly_accessible

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-${count.index + 1}"
    }
  )
}
