# AWS RDS Module

This Terraform module creates and manages AWS RDS instances or Aurora clusters with comprehensive support for parameter groups, subnet groups, option groups, and advanced database features. It supports both traditional RDS instances and modern Aurora clusters with Aurora Serverless v2 capabilities.

## Features

- ✅ **Multi-Engine Support**: MySQL, PostgreSQL, and Aurora variants
- ✅ **Instance & Cluster Types**: Standard RDS instances and Aurora clusters
- ✅ **Aurora Serverless v2**: Auto-scaling compute capacity
- ✅ **Security**: Encryption at rest/transit, IAM authentication, Secrets Manager integration
- ✅ **High Availability**: Multi-AZ deployments and Aurora reader replicas
- ✅ **Performance**: Performance Insights, Enhanced Monitoring, custom parameter groups
- ✅ **Backup & Recovery**: Automated backups, point-in-time recovery, snapshots
- ✅ **Monitoring**: CloudWatch integration, log exports, custom metrics
- ✅ **Networking**: VPC integration, subnet groups, security groups

## Usage Examples

### Standard MySQL RDS Instance

```hcl
module "mysql_db" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"

  identifier     = "production-mysql-db"
  engine         = "mysql"
  engine_version = "8.0.35"
  
  # Database configuration
  db_name  = "myapp"
  username = "admin"
  
  # Use AWS Secrets Manager for password management
  manage_master_user_password = true
  master_user_secret_kms_key_id = module.rds_kms_key.key_arn
  
  # Instance configuration
  instance_class        = "db.r6g.large"
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type          = "gp3"
  
  # Network configuration
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.db_security_group.security_group_id]
  
  # High availability
  multi_az = true
  
  # Backup and maintenance
  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  delete_automated_backups = false
  
  # Performance and monitoring
  monitoring_interval               = 60
  monitoring_role_arn              = module.rds_enhanced_monitoring.role_arn
  performance_insights_enabled     = true
  performance_insights_retention_period = 31
  performance_insights_kms_key_id  = module.rds_kms_key.key_arn
  
  # Security
  storage_encrypted     = true
  kms_key_id           = module.rds_kms_key.key_arn
  deletion_protection  = true
  
  # CloudWatch logs
  enabled_cloudwatch_logs_exports = ["error", "general", "slow_query"]
  
  tags = {
    Environment = "production"
    Project     = "web-app"
    Team        = "backend"
    Backup      = "required"
  }
}
```

### PostgreSQL with Custom Parameters

```hcl
module "postgres_db" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"

  identifier     = "analytics-postgres-db"
  engine         = "postgres"
  engine_version = "15.4"
  
  # Database configuration
  db_name  = "analytics"
  username = "dbadmin"
  
  # Use Secrets Manager
  manage_master_user_password = true
  
  # Instance configuration - optimized for analytics workloads
  instance_class        = "db.r6g.2xlarge"
  allocated_storage     = 500
  max_allocated_storage = 5000
  storage_type          = "gp3"
  
  # Network configuration
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.analytics_db_sg.security_group_id]
  
  # Custom parameter group for analytics optimization
  create_db_parameter_group = true
  parameter_group_family    = "postgres15"
  parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements,pg_hint_plan"
    },
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "work_mem"
      value = "256MB"
    },
    {
      name  = "maintenance_work_mem"
      value = "2GB"
    },
    {
      name  = "effective_cache_size"
      value = "12GB"
    },
    {
      name  = "random_page_cost"
      value = "1.1"
    },
    {
      name  = "checkpoint_completion_target"
      value = "0.9"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]
  
  # High availability
  multi_az = true
  
  # Extended backup retention for compliance
  backup_retention_period = 30
  backup_window          = "02:00-03:00"
  maintenance_window     = "sun:03:00-sun:04:00"
  
  # Enhanced monitoring and insights
  monitoring_interval               = 60
  monitoring_role_arn              = module.rds_enhanced_monitoring.role_arn
  performance_insights_enabled     = true
  performance_insights_retention_period = 93  # 3 months
  performance_insights_kms_key_id  = module.analytics_kms_key.key_arn
  
  # Security
  storage_encrypted              = true
  kms_key_id                    = module.analytics_kms_key.key_arn
  iam_database_authentication_enabled = true
  deletion_protection           = true
  
  # Logging
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  tags = {
    Environment = "production"
    Project     = "analytics-platform"
    Team        = "data-engineering"
    Compliance  = "required"
  }
}
```

### Aurora MySQL Cluster

```hcl
module "aurora_mysql_cluster" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"

  identifier     = "webapp-aurora-mysql"
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.04.0"
  
  # Database configuration
  db_name  = "webapp"
  username = "admin"
  
  # Use Secrets Manager for password
  manage_master_user_password = true
  
  # Aurora cluster configuration
  aurora_instance_count = 3  # 1 writer + 2 readers
  instance_class       = "db.r6g.large"
  
  # Network configuration
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.aurora_sg.security_group_id]
  
  # Custom cluster parameter group
  create_db_parameter_group = true
  parameter_group_family    = "aurora-mysql8.0"
  cluster_parameters = [
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
    },
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "innodb_log_file_size"
      value = "134217728"
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    },
    {
      name  = "binlog_format"
      value = "ROW"
    }
  ]
  
  # Backup and maintenance
  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Performance monitoring
  monitoring_interval               = 60
  monitoring_role_arn              = module.rds_enhanced_monitoring.role_arn
  performance_insights_enabled     = true
  performance_insights_retention_period = 31
  
  # Security
  storage_encrypted              = true
  kms_key_id                    = module.aurora_kms_key.key_arn
  iam_database_authentication_enabled = true
  deletion_protection           = true
  
  # CloudWatch logs
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  
  tags = {
    Environment = "production"
    Project     = "web-application"
    Team        = "platform"
    Service     = "aurora-mysql"
  }
}
```

### Aurora PostgreSQL with Serverless v2

```hcl
module "aurora_serverless_postgres" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"

  identifier     = "analytics-aurora-serverless"
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  
  # Database configuration
  db_name  = "analytics"
  username = "postgres"
  
  # Secrets Manager integration
  manage_master_user_password = true
  
  # Aurora Serverless v2 configuration
  aurora_serverless       = true
  aurora_instance_count   = 2  # Min instances for HA
  serverlessv2_min_capacity = 0.5   # 0.5 ACU minimum
  serverlessv2_max_capacity = 16    # 16 ACU maximum
  
  # Network configuration
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.serverless_db_sg.security_group_id]
  
  # Custom parameter group for serverless optimization
  create_db_parameter_group = true
  parameter_group_family    = "aurora-postgresql15"
  cluster_parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "log_statement"
      value = "ddl"
    },
    {
      name  = "log_min_duration_statement"
      value = "5000"
    },
    {
      name  = "auto_explain.log_min_duration"
      value = "10000"  # 10 seconds
    }
  ]
  
  # Backup configuration
  backup_retention_period = 7
  backup_window          = "04:00-05:00"
  maintenance_window     = "sun:05:00-sun:06:00"
  
  # Monitoring
  performance_insights_enabled = true
  
  # Security
  storage_encrypted     = true
  deletion_protection   = false  # Allow deletion for dev/test
  
  # Logging
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  tags = {
    Environment = "development"
    Project     = "analytics-dev"
    Team        = "data-science"
    AutoScaling = "serverless-v2"
  }
}
```

### Multi-Environment RDS Setup

```hcl
# Local variables for environment-specific configurations
locals {
  environments = {
    dev = {
      instance_class              = "db.t3.micro"
      allocated_storage          = 20
      backup_retention_period    = 1
      multi_az                   = false
      deletion_protection        = false
      performance_insights       = false
      monitoring_interval        = 0
    }
    
    staging = {
      instance_class              = "db.t3.small"
      allocated_storage          = 50
      backup_retention_period    = 7
      multi_az                   = false
      deletion_protection        = false
      performance_insights       = true
      monitoring_interval        = 60
    }
    
    production = {
      instance_class              = "db.r6g.large"
      allocated_storage          = 200
      backup_retention_period    = 30
      multi_az                   = true
      deletion_protection        = true
      performance_insights       = true
      monitoring_interval        = 60
    }
  }
  
  environment = "production"  # Change based on deployment
  config      = local.environments[local.environment]
}

module "app_database" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"

  identifier     = "${local.environment}-app-db"
  engine         = "mysql"
  engine_version = "8.0.35"
  
  # Database configuration
  db_name  = "appdb"
  username = "appuser"
  manage_master_user_password = true
  
  # Environment-specific configuration
  instance_class        = local.config.instance_class
  allocated_storage     = local.config.allocated_storage
  max_allocated_storage = local.config.allocated_storage * 5
  
  # Network
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.app_db_sg.security_group_id]
  
  # High availability (production only)
  multi_az = local.config.multi_az
  
  # Backup and retention
  backup_retention_period = local.config.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Monitoring
  monitoring_interval               = local.config.monitoring_interval
  monitoring_role_arn              = local.config.monitoring_interval > 0 ? module.rds_enhanced_monitoring[0].role_arn : null
  performance_insights_enabled     = local.config.performance_insights
  performance_insights_retention_period = local.config.performance_insights ? 7 : null
  
  # Security
  storage_encrypted   = true
  deletion_protection = local.config.deletion_protection
  
  tags = {
    Environment = local.environment
    Project     = "multi-tier-app"
    ManagedBy   = "terraform"
  }
}
```

## Input Variables

### Required Variables

| Name              | Description                    | Type           |
|-------------------|--------------------------------|----------------|
| `identifier`      | Name of the RDS instance/cluster | `string`     |
| `engine`          | Database engine                | `string`       |
| `engine_version`  | Engine version                 | `string`       |
| `subnet_ids`      | List of VPC subnet IDs         | `list(string)` |
| `vpc_security_group_ids` | List of security group IDs | `list(string)` |

### Database Configuration

| Name               | Description                     | Type     | Default  |
|--------------------|---------------------------------|----------|----------|
| `instance_class`   | RDS instance type              | `string` | `"db.t3.micro"` |
| `allocated_storage`| Storage size in GB             | `number` | `20`     |
| `max_allocated_storage` | Max auto-scaling storage  | `number` | `0`      |
| `storage_type`     | Storage type (gp2, gp3, io1)  | `string` | `"gp3"`  |
| `storage_encrypted`| Enable storage encryption      | `bool`   | `true`   |
| `kms_key_id`       | KMS key ARN for encryption     | `string` | `null`   |

### Authentication & Security

| Name                    | Description                          | Type     | Default |
|-------------------------|--------------------------------------|----------|---------|
| `username`              | Master username                      | `string` | `"admin"` |
| `password`              | Master password (if not using Secrets Manager) | `string` | `null` |
| `manage_master_user_password` | Use AWS Secrets Manager for password | `bool` | `false` |
| `master_user_secret_kms_key_id` | KMS key for Secrets Manager | `string` | `null` |
| `iam_database_authentication_enabled` | Enable IAM authentication | `bool` | `false` |
| `port`                  | Database port                        | `number` | `null`  |
| `db_name`               | Initial database name                | `string` | `null`  |

### High Availability & Backup

| Name                     | Description                    | Type     | Default |
|--------------------------|--------------------------------|----------|---------|
| `multi_az`               | Enable Multi-AZ deployment     | `bool`   | `false` |
| `backup_retention_period`| Backup retention in days       | `number` | `7`     |
| `backup_window`          | Backup window (UTC)            | `string` | `null`  |
| `maintenance_window`     | Maintenance window (UTC)       | `string` | `null`  |
| `skip_final_snapshot`    | Skip final snapshot on delete  | `bool`   | `false` |
| `delete_automated_backups` | Delete automated backups     | `bool`   | `true`  |

### Parameter Groups

| Name                      | Description                    | Type     | Default |
|---------------------------|--------------------------------|----------|---------|
| `create_db_parameter_group` | Create custom parameter group | `bool` | `false` |
| `parameter_group_name`    | Existing parameter group name  | `string` | `null`  |
| `parameter_group_family`  | Parameter group family         | `string` | `"mysql8.0"` |
| `parameters`              | List of parameters             | `list(map(string))` | `[]` |
| `cluster_parameters`      | Aurora cluster parameters      | `list(map(string))` | `[]` |

### Option Groups (MySQL only)

| Name                    | Description                  | Type     | Default |
|-------------------------|------------------------------|----------|---------|
| `create_db_option_group` | Create custom option group  | `bool`   | `false` |
| `major_engine_version`  | Major engine version         | `string` | `"8.0"` |
| `options`               | List of options              | `any`    | `[]`    |

### Monitoring & Performance

| Name                              | Description                      | Type     | Default |
|-----------------------------------|----------------------------------|----------|---------|
| `monitoring_interval`             | Enhanced monitoring interval     | `number` | `0`     |
| `monitoring_role_arn`             | IAM role for enhanced monitoring | `string` | `null`  |
| `performance_insights_enabled`    | Enable Performance Insights      | `bool`   | `false` |
| `performance_insights_retention_period` | PI retention period     | `number` | `7`     |
| `performance_insights_kms_key_id` | KMS key for PI                  | `string` | `null`  |
| `enabled_cloudwatch_logs_exports` | Log types to export             | `list(string)` | `[]` |

### Aurora Configuration

| Name                      | Description                    | Type     | Default |
|---------------------------|--------------------------------|----------|---------|
| `aurora_instance_count`   | Number of Aurora instances     | `number` | `1`     |
| `aurora_serverless`       | Enable Aurora Serverless v2    | `bool`   | `false` |
| `serverlessv2_min_capacity` | Min Serverless v2 capacity   | `number` | `0.5`   |
| `serverlessv2_max_capacity` | Max Serverless v2 capacity   | `number` | `1`     |

### Network & Access

| Name                  | Description                    | Type     | Default |
|-----------------------|--------------------------------|----------|---------|
| `create_db_subnet_group` | Create DB subnet group      | `bool`   | `true`  |
| `db_subnet_group_name` | Existing subnet group name    | `string` | `null`  |
| `publicly_accessible` | Make DB publicly accessible   | `bool`   | `false` |

### Maintenance & Updates

| Name                      | Description                    | Type     | Default |
|---------------------------|--------------------------------|----------|---------|
| `auto_minor_version_upgrade` | Enable auto minor upgrades  | `bool`   | `true`  |
| `apply_immediately`       | Apply changes immediately      | `bool`   | `false` |
| `deletion_protection`     | Enable deletion protection     | `bool`   | `true`  |

### Tags

| Name   | Description              | Type            | Default |
|--------|--------------------------|-----------------|---------|
| `tags` | Tags for all resources   | `map(string)`   | `{}`    |

## Outputs

### RDS Instance Outputs

| Name                    | Description                      |
|-------------------------|----------------------------------|
| `rds_instance_id`       | ID of the RDS instance          |
| `rds_instance_arn`      | ARN of the RDS instance         |
| `rds_instance_endpoint` | Connection endpoint             |
| `rds_instance_status`   | Status of the RDS instance      |

### Aurora Cluster Outputs

| Name                       | Description                      |
|----------------------------|----------------------------------|
| `cluster_id`               | ID of the Aurora cluster        |
| `cluster_arn`              | ARN of the Aurora cluster       |
| `cluster_endpoint`         | Writer endpoint                 |
| `cluster_reader_endpoint`  | Reader endpoint                 |
| `cluster_port`             | Port for connections            |

### Common Outputs

| Name                    | Description                      |
|-------------------------|----------------------------------|
| `db_instance_port`      | Database port                   |
| `db_instance_name`      | Database name                   |
| `db_instance_username`  | Master username (sensitive)     |
| `security_group_ids`    | Associated security group IDs   |

### Subnet & Parameter Groups

| Name                     | Description                      |
|--------------------------|----------------------------------|
| `db_subnet_group_id`     | ID of the DB subnet group       |
| `db_subnet_group_arn`    | ARN of the DB subnet group      |
| `db_parameter_group_id`  | ID of the DB parameter group    |
| `db_parameter_group_arn` | ARN of the DB parameter group   |

## Engine Support

### Supported Engines

| Engine              | Standard RDS | Aurora | Serverless v2 |
|---------------------|--------------|--------|---------------|
| `mysql`             | ✅           | ❌     | ❌            |
| `postgres`          | ✅           | ❌     | ❌            |
| `aurora-mysql`      | ❌           | ✅     | ✅            |
| `aurora-postgresql` | ❌           | ✅     | ✅            |

### Version Recommendations

- **MySQL**: `8.0.35` (latest 8.0.x)
- **PostgreSQL**: `15.4` (latest 15.x)
- **Aurora MySQL**: `8.0.mysql_aurora.3.04.0`
- **Aurora PostgreSQL**: `15.4`

## Security Best Practices

### Encryption

```hcl
# KMS key for RDS encryption
module "rds_kms_key" {
  source = "github.com/your-org/terraform-modules//aws/kms?ref=main"
  
  description = "KMS key for RDS encryption"
  key_usage   = "ENCRYPT_DECRYPT"
  
  key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable RDS service permissions"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Purpose = "rds-encryption"
  }
}
```

### Security Groups

```hcl
module "db_security_group" {
  source = "github.com/your-org/terraform-modules//aws/security-group?ref=main"
  
  name_prefix = "rds-mysql-sg"
  vpc_id      = module.vpc.vpc_id
  
  ingress_rules = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.app_security_group.security_group_id
      description              = "MySQL access from application servers"
    }
  ]
  
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound traffic"
    }
  ]
  
  tags = {
    Name = "rds-mysql-security-group"
  }
}
```

### IAM Authentication

```hcl
# IAM policy for database access
resource "aws_iam_policy" "db_access" {
  name = "rds-db-access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${module.mysql_db.rds_instance_id}/app_user"
        ]
      }
    ]
  })
}

# Attach to application role
resource "aws_iam_role_policy_attachment" "app_db_access" {
  role       = module.app_role.role_name
  policy_arn = aws_iam_policy.db_access.arn
}
```

## Monitoring & Alerting

### Enhanced Monitoring IAM Role

```hcl
module "rds_enhanced_monitoring" {
  source = "github.com/your-org/terraform-modules//aws/iam-role?ref=main"
  
  role_name = "rds-enhanced-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
  
  tags = {
    Purpose = "rds-enhanced-monitoring"
  }
}
```

### CloudWatch Alarms

```hcl
# Database connection alarm
resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "${module.mysql_db.rds_instance_id}-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors RDS database connections"
  
  dimensions = {
    DBInstanceIdentifier = module.mysql_db.rds_instance_id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "${module.mysql_db.rds_instance_id}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  
  dimensions = {
    DBInstanceIdentifier = module.mysql_db.rds_instance_id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Backup & Recovery

### Automated Backups

```hcl
# Long-term backup retention
resource "aws_db_instance_automated_backups_replication" "example" {
  source_db_instance_arn = module.mysql_db.rds_instance_arn
  destination_region     = "us-west-2"
  
  kms_key_id = module.backup_kms_key.key_arn
  
  tags = {
    Purpose = "long-term-backup"
  }
}
```

### Manual Snapshots

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier production-mysql-db \
  --db-snapshot-identifier production-mysql-db-manual-$(date +%Y%m%d%H%M%S)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-production-mysql-db \
  --db-snapshot-identifier production-mysql-db-manual-20240101120000
```

## Migration & Upgrades

### Blue-Green Deployment

```hcl
# Create new instance for blue-green deployment
module "mysql_db_new_version" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"
  
  # Same configuration as original but with new engine version
  identifier     = "production-mysql-db-v2"
  engine         = "mysql"
  engine_version = "8.0.36"  # Upgraded version
  
  # ... rest of configuration same as original
  
  tags = merge(
    local.common_tags,
    {
      BlueGreen = "new-version"
      Migration = "in-progress"
    }
  )
}
```

### Cross-Region Read Replica

```hcl
# Read replica in different region
module "mysql_read_replica" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"
  
  providers = {
    aws = aws.us_west_2
  }
  
  identifier              = "production-mysql-db-replica"
  replicate_source_db     = module.mysql_db.rds_instance_arn
  instance_class          = "db.r6g.large"
  auto_minor_version_upgrade = false
  
  # Network in target region
  subnet_ids             = module.vpc_west.database_subnet_ids
  vpc_security_group_ids = [module.replica_sg.security_group_id]
  
  tags = {
    Purpose = "read-replica"
    Region  = "us-west-2"
  }
}
```

## Cost Optimization

### Reserved Instances

```bash
# Purchase Reserved Instance
aws rds purchase-reserved-db-instances-offering \
  --reserved-db-instances-offering-id 12345678-1234-1234-1234-123456789012 \
  --reserved-db-instance-id production-mysql-reserved
```

### Storage Auto Scaling

```hcl
# Enable storage auto scaling
module "cost_optimized_db" {
  source = "github.com/your-org/terraform-modules//aws/rds?ref=main"
  
  # ... other configuration
  
  # Start small and auto-scale
  allocated_storage     = 50
  max_allocated_storage = 1000  # Auto-scale up to 1TB
  
  # Use gp3 for better price/performance
  storage_type = "gp3"
}
```

## Troubleshooting

### Common Issues

1. **Connection Issues**
   ```bash
   # Test connectivity
   mysql -h production-mysql-db.abcdef123456.us-east-1.rds.amazonaws.com -u admin -p
   
   # Check security groups
   aws ec2 describe-security-groups --group-ids sg-12345678
   ```

2. **Performance Issues**
   ```bash
   # Check Performance Insights
   aws rds describe-db-instances --db-instance-identifier production-mysql-db
   
   # Check slow query log
   aws logs describe-log-streams --log-group-name /aws/rds/instance/production-mysql-db/slowquery
   ```

3. **Storage Space**
   ```bash
   # Check storage metrics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/RDS \
     --metric-name FreeStorageSpace \
     --dimensions Name=DBInstanceIdentifier,Value=production-mysql-db \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-01-02T00:00:00Z \
     --period 3600 \
     --statistics Average
   ```

## Requirements

| Name        | Version   |
|-------------|-----------|
| terraform   | ~> 1.3    |
| aws         | ~> 5.97.0 |

## License

This module is released under the MIT License.