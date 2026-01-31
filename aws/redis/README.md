# AWS ElastiCache Redis Module

This Terraform module provisions AWS ElastiCache Redis instances with support for both cluster mode and non-cluster mode configurations. It provides flexible options for encryption, automatic failover, custom parameter groups, and other advanced features.

## Important: Parameter Group Configuration

⚠️ **Critical Note**: The parameter group MUST match your cluster mode setting. Using mismatched parameter groups will cause errors that cannot be fixed without recreating the Redis instance.

| Configuration                                     | Required Parameter Group    | Description                                        |
| ------------------------------------------------- | --------------------------- | -------------------------------------------------- |
| Cluster Mode (`cluster_mode_enabled = true`)      | `default.redis7.cluster.on` | For sharded Redis with configuration endpoint      |
| Non-Cluster Mode (`cluster_mode_enabled = false`) | `default.redis7`            | For replicated Redis with primary/reader endpoints |

**Warning**: The cluster-enabled parameter cannot be changed for an existing Redis instance. If you need to switch modes, you must create a new Redis instance.

## Redis Endpoint Types

| Mode        | Configuration                                                                                                                                   | Endpoints Available        | Use Case                                 |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------------------------------- |
| Cluster     | `cluster_mode_enabled = true`<br>`parameter_group_name = "*.cluster.on"`                                                                        | Configuration Endpoint     | Horizontal scaling with sharding         |
| Non-Cluster | `cluster_mode_enabled = false`<br>`parameter_group_name = "default.redis7"`<br>`automatic_failover_enabled = true`<br>`num_cache_clusters >= 2` | Primary + Reader Endpoints | High availability with read distribution |
| Single Node | `cluster_mode_enabled = false`<br>`num_cache_clusters = 1`                                                                                      | Primary Endpoint only      | Development/testing                      |

## Usage Examples

### 1. Cluster Mode with Configuration Endpoint (Recommended for Production)

```hcl
# Production Redis with cluster mode for horizontal scaling
module "redis_cluster_production" {
  source = "github.com/your-org/terraform-modules//aws/redis?ref=main"

  name        = "production-redis-cluster"
  description = "Production Redis cluster with sharding for horizontal scaling"
  
  # Node configuration
  node_type      = "cache.r7g.large"
  engine_version = "7.1"
  port           = 6379
  
  # CLUSTER MODE CONFIGURATION - Enables horizontal scaling
  cluster_mode_enabled    = true
  num_node_groups         = 3     # 3 shards for horizontal scaling
  replicas_per_node_group = 2     # 2 replicas per shard for high availability
  
  # CRITICAL: Use cluster-enabled parameter group
  parameter_group_family = "redis7"
  create_parameter_group = false  
  parameter_group_name   = "default.redis7.cluster.on"
  
  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.redis_security_group.security_group_id]
  create_subnet_group = true
  subnet_group_name   = "production-redis-subnet-group"
  
  # High availability and security
  automatic_failover_enabled = true
  multi_az_enabled           = true
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = var.redis_auth_token  # Enable AUTH
  
  # Backup configuration
  snapshot_retention_limit = 14
  snapshot_window         = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"
  
  # Performance and monitoring
  notification_topic_arn = aws_sns_topic.redis_alerts.arn
  
  tags = {
    Environment = "production"
    Application = "web-app"
    Team        = "platform"
    Backup      = "required"
  }
}

# Application configuration using configuration endpoint
resource "aws_ssm_parameter" "redis_config_endpoint" {
  name  = "/app/redis/config-endpoint"
  type  = "String"
  value = module.redis_cluster_production.configuration_endpoint_address
  
  tags = {
    Environment = "production"
    Purpose     = "redis-configuration"
  }
}

# Example application code snippet for cluster mode
locals {
  redis_cluster_config = {
    # Use configuration endpoint for cluster mode
    endpoint = module.redis_cluster_production.configuration_endpoint_address
    port     = module.redis_cluster_production.port
    
    # Client configuration for Redis Cluster
    cluster_mode = true
    
    # Connection settings
    timeout = 5000
    retry_delay_on_failure = 100
    max_redirections = 16
    
    # Authentication
    auth_token = var.redis_auth_token
    
    # TLS settings
    tls_enabled = true
    tls_skip_verify = false
  }
}

# Example: Store configuration in Parameter Store
resource "aws_ssm_parameter" "redis_cluster_config" {
  name  = "/app/redis/cluster-config"
  type  = "SecureString"
  value = jsonencode(local.redis_cluster_config)
  
  tags = {
    Environment = "production"
    Purpose     = "redis-cluster-config"
  }
}
```

### 2. Non-Cluster Mode with Separate Read/Write Endpoints

```hcl
# High-availability Redis with read/write separation
module "redis_read_write_separation" {
  source = "github.com/your-org/terraform-modules//aws/redis?ref=main"

  name        = "ha-redis-read-write"
  description = "High availability Redis with separate read/write endpoints"
  
  # Node configuration
  node_type      = "cache.r7g.xlarge"
  engine_version = "7.1"
  port           = 6379
  
  # NON-CLUSTER MODE CONFIGURATION - Enables read/write separation
  cluster_mode_enabled = false
  num_cache_clusters   = 4  # 1 primary + 3 read replicas
  
  # CRITICAL: Use non-cluster parameter group
  parameter_group_family = "redis7"
  create_parameter_group = false
  parameter_group_name   = "default.redis7"
  
  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.redis_security_group.security_group_id]
  create_subnet_group = true
  subnet_group_name   = "ha-redis-subnet-group"
  
  # REQUIRED for read/write endpoints
  automatic_failover_enabled = true
  multi_az_enabled           = true
  
  # Security
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  
  # Backup configuration
  snapshot_retention_limit = 7
  snapshot_window         = "02:00-04:00"
  maintenance_window      = "sun:04:00-sun:06:00"
  
  # Performance tuning
  apply_immediately = false
  
  tags = {
    Environment = "production"
    Application = "api-service"
    Team        = "backend"
    Purpose     = "read-write-separation"
  }
}

# Application configuration for read/write separation
resource "aws_ssm_parameter" "redis_write_endpoint" {
  name  = "/app/redis/write-endpoint"
  type  = "String"
  value = module.redis_read_write_separation.primary_endpoint_address
  
  tags = {
    Environment = "production"
    Purpose     = "redis-write-endpoint"
  }
}

resource "aws_ssm_parameter" "redis_read_endpoint" {
  name  = "/app/redis/read-endpoint"
  type  = "String"
  value = module.redis_read_write_separation.reader_endpoint_address
  
  tags = {
    Environment = "production"
    Purpose     = "redis-read-endpoint"
  }
}

# Example application configuration for read/write separation
locals {
  redis_read_write_config = {
    # Separate endpoints for read and write operations
    write_endpoint = module.redis_read_write_separation.primary_endpoint_address
    read_endpoint  = module.redis_read_write_separation.reader_endpoint_address
    port          = module.redis_read_write_separation.port
    
    # Connection settings
    timeout = 3000
    pool_size = 20
    
    # Authentication
    auth_token = var.redis_auth_token
    
    # TLS settings
    tls_enabled = true
    
    # Read/write strategy
    read_from_replicas = true
    write_to_primary   = true
  }
}

# Store configuration securely
resource "aws_ssm_parameter" "redis_read_write_config" {
  name  = "/app/redis/read-write-config"
  type  = "SecureString"
  value = jsonencode(local.redis_read_write_config)
  
  tags = {
    Environment = "production"
    Purpose     = "redis-read-write-config"
  }
}
```

### 3. Development Environment (Single Node)

```hcl
# Simple Redis for development
module "redis_development" {
  source = "github.com/your-org/terraform-modules//aws/redis?ref=main"

  name        = "development-redis"
  description = "Development Redis instance"
  
  # Small node for development
  node_type      = "cache.t4g.micro"
  engine_version = "7.1"
  
  # Single node configuration
  cluster_mode_enabled = false
  num_cache_clusters   = 1  # Single node
  
  # Use default parameter group
  parameter_group_family = "redis7"
  create_parameter_group = false
  parameter_group_name   = "default.redis7"
  
  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.dev_redis_sg.security_group_id]
  
  # Simplified settings for development
  automatic_failover_enabled = false
  multi_az_enabled           = false
  transit_encryption_enabled = false
  at_rest_encryption_enabled = false
  
  # No backups for development
  snapshot_retention_limit = 0
  
  tags = {
    Environment = "development"
    Purpose     = "testing"
    AutoShutdown = "enabled"
  }
}
```

### 4. Staging Environment with Custom Parameters

```hcl
# Staging Redis with custom parameter group
module "redis_staging" {
  source = "github.com/your-org/terraform-modules//aws/redis?ref=main"

  name        = "staging-redis"
  description = "Staging Redis with custom configuration"
  
  # Node configuration
  node_type      = "cache.r7g.large"
  engine_version = "7.1"
  
  # Non-cluster mode with replicas
  cluster_mode_enabled = false
  num_cache_clusters   = 2  # 1 primary + 1 replica
  
  # Custom parameter group
  parameter_group_family = "redis7"
  create_parameter_group = true
  parameter_group_name   = "staging-redis-params"
  
  # Custom parameters for performance tuning
  parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    },
    {
      name  = "tcp-keepalive"
      value = "300"
    },
    {
      name  = "maxclients"
      value = "1000"
    }
  ]
  
  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.staging_redis_sg.security_group_id]
  
  # High availability settings
  automatic_failover_enabled = true
  multi_az_enabled           = true
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  
  # Backup configuration
  snapshot_retention_limit = 3
  snapshot_window         = "03:00-05:00"
  
  tags = {
    Environment = "staging"
    Application = "web-app"
    Team        = "qa"
  }
}
```

### 5. Multi-Environment Redis with Conditional Configuration

```hcl
# Variables for environment-specific configuration
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Environment-specific configurations
locals {
  redis_configs = {
    dev = {
      node_type                   = "cache.t4g.micro"
      cluster_mode_enabled       = false
      num_cache_clusters         = 1
      num_node_groups           = 1
      replicas_per_node_group   = 0
      automatic_failover_enabled = false
      multi_az_enabled          = false
      encryption_enabled        = false
      snapshot_retention_limit  = 0
      parameter_group_name      = "default.redis7"
    }
    
    staging = {
      node_type                   = "cache.r7g.large"
      cluster_mode_enabled       = false
      num_cache_clusters         = 2
      num_node_groups           = 1
      replicas_per_node_group   = 1
      automatic_failover_enabled = true
      multi_az_enabled          = true
      encryption_enabled        = true
      snapshot_retention_limit  = 3
      parameter_group_name      = "default.redis7"
    }
    
    prod = {
      node_type                   = "cache.r7g.xlarge"
      cluster_mode_enabled       = true
      num_cache_clusters         = 1
      num_node_groups           = 3
      replicas_per_node_group   = 2
      automatic_failover_enabled = true
      multi_az_enabled          = true
      encryption_enabled        = true
      snapshot_retention_limit  = 14
      parameter_group_name      = "default.redis7.cluster.on"
    }
  }
  
  config = local.redis_configs[var.environment]
}

# Multi-environment Redis module
module "redis_multi_env" {
  source = "github.com/your-org/terraform-modules//aws/redis?ref=main"

  name        = "${var.environment}-redis"
  description = "Redis cluster for ${var.environment} environment"
  
  # Environment-specific configuration
  node_type                   = local.config.node_type
  cluster_mode_enabled       = local.config.cluster_mode_enabled
  num_cache_clusters         = local.config.num_cache_clusters
  num_node_groups           = local.config.num_node_groups
  replicas_per_node_group   = local.config.replicas_per_node_group
  
  # Parameter group
  parameter_group_family = "redis7"
  create_parameter_group = false
  parameter_group_name   = local.config.parameter_group_name
  
  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.redis_sg.security_group_id]
  
  # Environment-specific settings
  automatic_failover_enabled = local.config.automatic_failover_enabled
  multi_az_enabled           = local.config.multi_az_enabled
  transit_encryption_enabled = local.config.encryption_enabled
  at_rest_encryption_enabled = local.config.encryption_enabled
  snapshot_retention_limit   = local.config.snapshot_retention_limit
  
  # Authentication (only for staging and prod)
  auth_token = local.config.encryption_enabled ? var.redis_auth_token : null
  
  tags = {
    Environment = var.environment
    Application = "web-app"
    ManagedBy   = "terraform"
  }
}

# Conditional outputs based on cluster mode
output "redis_endpoints" {
  description = "Redis endpoints for application configuration"
  value = local.config.cluster_mode_enabled ? {
    # Cluster mode: use configuration endpoint
    type                = "cluster"
    configuration_endpoint = module.redis_multi_env.configuration_endpoint_address
    port                = module.redis_multi_env.port
  } : {
    # Non-cluster mode: use primary/reader endpoints
    type             = "replication-group"
    primary_endpoint = module.redis_multi_env.primary_endpoint_address
    reader_endpoint  = module.redis_multi_env.reader_endpoint_address
    port            = module.redis_multi_env.port
  }
}
```

## Input Variables

### Required Variables

| Name               | Description                           | Type           |
|--------------------|---------------------------------------|----------------|
| `name`             | Name of the Redis cluster            | `string`       |
| `node_type`        | Instance type for Redis nodes        | `string`       |
| `subnet_ids`       | List of subnet IDs for Redis cluster | `list(string)` |
| `security_group_ids` | List of security group IDs         | `list(string)` |

### Optional Variables

| Name                       | Description                                          | Type         | Default       |
| -------------------------- | ---------------------------------------------------- | ------------ | ------------- |
| `description`              | Description for the Redis cluster                   | `string`     | `null`        |
| `engine_version`           | Redis engine version                                 | `string`     | `"7.1"`       |
| `port`                     | Port number for Redis connections                   | `number`     | `6379`        |
| `cluster_mode_enabled`     | Whether to enable Redis cluster mode (sharding)     | `bool`       | `false`       |
| `num_node_groups`          | Number of shards (only for cluster mode)            | `number`     | `1`           |
| `replicas_per_node_group`  | Number of replicas per shard (only for cluster mode) | `number`    | `1`           |
| `num_cache_clusters`       | Number of nodes in non-cluster mode                 | `number`     | `1`           |
| `create_subnet_group`      | Whether to create a subnet group                    | `bool`       | `true`        |
| `subnet_group_name`        | Name of subnet group (if creating)                  | `string`     | `null`        |
| `create_parameter_group`   | Whether to create a parameter group                 | `bool`       | `false`       |
| `parameter_group_name`     | Name of parameter group to use                       | `string`     | `null`        |
| `parameter_group_family`   | Redis parameter group family                        | `string`     | `"redis7"`    |
| `parameters`               | Custom parameters for the parameter group           | `list(map)`  | `[]`          |
| `automatic_failover_enabled` | Enable automatic failover                         | `bool`       | `true`        |
| `multi_az_enabled`         | Enable Multi-AZ deployment                          | `bool`       | `true`        |
| `transit_encryption_enabled` | Enable transit encryption                         | `bool`       | `true`        |
| `at_rest_encryption_enabled` | Enable at rest encryption                         | `bool`       | `true`        |
| `auth_token`               | Auth token for Redis AUTH command                   | `string`     | `null`        |
| `snapshot_retention_limit` | Number of days to retain snapshots                  | `number`     | `7`           |
| `snapshot_window`          | Daily time range for snapshots                      | `string`     | `"03:00-05:00"` |
| `maintenance_window`       | Weekly time range for maintenance                   | `string`     | `"sun:05:00-sun:07:00"` |
| `notification_topic_arn`   | SNS topic ARN for notifications                     | `string`     | `null`        |
| `apply_immediately`        | Apply changes immediately                            | `bool`       | `false`       |
| `tags`                     | Tags to apply to resources                           | `map(string)` | `{}`         |

## Outputs

| Name                           | Description                                        |
| ------------------------------ | -------------------------------------------------- |
| `replication_group_id`         | ID of the ElastiCache replication group           |
| `replication_group_arn`        | ARN of the ElastiCache replication group          |
| `primary_endpoint_address`     | Address of the primary endpoint (non-cluster mode) |
| `reader_endpoint_address`      | Address of the reader endpoint (non-cluster mode) |
| `configuration_endpoint_address` | Configuration endpoint address (cluster mode)   |
| `member_clusters`              | List of node IDs in the cluster                   |
| `port`                         | Redis port                                         |
| `parameter_group_name`         | Name of the parameter group used                   |
| `subnet_group_name`            | Name of the subnet group used                      |

## Best Practices

### 1. Choose the Right Mode
```hcl
# Use Cluster Mode when:
# - You need horizontal scaling (>250GB memory)
# - You have write-heavy workloads
# - You want to distribute load across multiple shards
cluster_mode_enabled = true

# Use Non-Cluster Mode when:
# - You need read/write endpoint separation
# - Your dataset fits in a single node
# - You want simpler client configuration
cluster_mode_enabled = false
```

### 2. Security Configuration
```hcl
# Always enable encryption in production
transit_encryption_enabled = true
at_rest_encryption_enabled = true

# Use strong authentication
auth_token = var.redis_auth_token  # Use random 128-character string

# Restrict network access
security_group_ids = [aws_security_group.redis.id]
```

### 3. High Availability
```hcl
# For production workloads
automatic_failover_enabled = true
multi_az_enabled           = true
num_cache_clusters         = 3  # At least 2 for failover

# For cluster mode
replicas_per_node_group = 2  # At least 1 replica per shard
```

### 4. Monitoring and Alerting
```hcl
# CloudWatch alarms for Redis monitoring
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.name}-redis-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors Redis CPU utilization"
  
  dimensions = {
    CacheClusterId = module.redis.replication_group_id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.name}-redis-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors Redis memory usage"
  
  dimensions = {
    CacheClusterId = module.redis.replication_group_id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Common Problems and Solutions

### 1. Cannot Change from Cluster to Non-Cluster Mode
If you try to change an existing Redis instance from cluster mode to non-cluster mode (or vice versa), you'll receive this error:
```
Error: The parameter cluster-enabled has a different value in the requested parameter group 
than the current parameter group. This parameter value cannot be changed for a cache cluster.
```
**Solution**: Create a new Redis instance with the desired mode. You cannot change this parameter for an existing instance.

### 2. Reader Endpoint Not Available
If you've configured non-cluster mode but don't see a reader endpoint:
**Solution**: Ensure you have:
- Set `cluster_mode_enabled = false`
- Set `automatic_failover_enabled = true`
- Set `num_cache_clusters >= 2`
- Used the correct parameter group (`default.redis7` not `default.redis7.cluster.on`)

### 3. Authentication Issues
```bash
# Test Redis connection with AUTH
redis-cli -h your-redis-endpoint.cache.amazonaws.com -p 6379 --tls
> AUTH your-auth-token
> PING
```

### 4. Performance Issues
```hcl
# Monitor key metrics
# - CPUUtilization: Should be < 80%
# - DatabaseMemoryUsagePercentage: Should be < 80%
# - CacheMisses vs CacheHits ratio
# - NetworkBytesIn/NetworkBytesOut

# Consider upgrading node type or adding replicas
node_type = "cache.r7g.2xlarge"  # More memory/CPU
replicas_per_node_group = 3      # More read capacity
```

## Cost Optimization

### Node Type Selection
```hcl
# Development
node_type = "cache.t4g.micro"    # $13/month

# Staging  
node_type = "cache.r7g.large"    # $120/month

# Production
node_type = "cache.r7g.xlarge"   # $240/month
```

### Reserved Instances
- 1-year term: ~25% savings
- 3-year term: ~50% savings
- Consider for stable production workloads

## Requirements

| Name        | Version   |
|-------------|-----------|
| terraform   | ~> 1.3    |
| aws         | ~> 5.97.0 |

## License

This module is released under the MIT License.