# AWS CloudWatch Logs Terraform Module

This module creates and manages AWS CloudWatch Log Groups, Log Streams, Metric Filters, and Subscription Filters with support for both single and multiple log group configurations.

## Features

- ✅ **Single Log Group** creation with streams and filters
- ✅ **Multiple Log Groups** with individual configurations
- ✅ **Log Streams** management for organized logging
- ✅ **Metric Filters** for CloudWatch metrics extraction
- ✅ **Subscription Filters** for real-time log processing
- ✅ **KMS Encryption** support for log data
- ✅ **Flexible Retention** policies per log group
- ✅ **Resource Tagging** with inheritance
- ✅ **Skip Destroy** protection for critical logs

## Usage

### Single Log Group with Basic Configuration

```terraform
module "single_log_group" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/cloudwatch?ref=v1.0.0"

  create_single_log_group = true
  log_group_name         = "/aws/lambda/my-function"
  retention_in_days      = 30
  kms_key_id            = aws_kms_key.logs.arn

  # Log streams
  log_streams = [
    "stream-1",
    "stream-2"
  ]

  # Metric filters
  metric_filters = [
    {
      name    = "error-count"
      pattern = "[timestamp, request_id, level=\"ERROR\"]"
      metric_transformation = {
        name      = "ErrorCount"
        namespace = "MyApp/Lambda"
        value     = "1"
        unit      = "Count"
      }
    }
  ]

  # Subscription filters
  subscription_filters = [
    {
      name            = "elasticsearch-filter"
      destination_arn = aws_elasticsearch_domain.logs.arn
      filter_pattern  = "[timestamp, request_id, level=\"ERROR\"]"
      role_arn        = aws_iam_role.logs_role.arn
    }
  ]

  tags = {
    Environment = "production"
    Application = "my-app"
  }
}
```

### Multiple Log Groups with Different Configurations

```terraform
module "multiple_log_groups" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/cloudwatch?ref=v1.0.0"

  create_single_log_group = false
  
  # Default settings for all log groups
  default_retention_in_days = 30
  default_kms_key_id       = aws_kms_key.logs.arn
  default_skip_destroy     = false

  log_groups = {
    "/aws/lambda/api-function" = {
      retention_in_days = 90
      skip_destroy     = true
      
      log_streams = ["api-stream-1", "api-stream-2"]
      
      metric_filters = [
        {
          name    = "api-errors"
          pattern = "[timestamp, request_id, level=\"ERROR\"]"
          metric_transformation = {
            name      = "APIErrors"
            namespace = "MyApp/API"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "api-duration"
          pattern = "[timestamp, request_id, level, duration]"
          metric_transformation = {
            name      = "APIDuration"
            namespace = "MyApp/API"
            value     = "$duration"
            unit      = "Milliseconds"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "api-to-elasticsearch"
          destination_arn = aws_elasticsearch_domain.logs.arn
          filter_pattern  = ""
          role_arn        = aws_iam_role.logs_role.arn
        }
      ]
      
      tags = {
        Service = "api"
        Critical = "true"
      }
    }

    "/aws/lambda/worker-function" = {
      retention_in_days = 14
      
      log_streams = ["worker-stream"]
      
      metric_filters = [
        {
          name    = "worker-errors"
          pattern = "ERROR"
          metric_transformation = {
            name      = "WorkerErrors"
            namespace = "MyApp/Worker"
            value     = "1"
          }
        }
      ]
      
      tags = {
        Service = "worker"
      }
    }

    "/aws/apigateway/my-api" = {
      retention_in_days = 60
      kms_key_id       = aws_kms_key.api_logs.arn
      
      metric_filters = [
        {
          name    = "4xx-errors"
          pattern = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status=4*, size]"
          metric_transformation = {
            name      = "4xxErrors"
            namespace = "MyApp/API"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "5xx-errors"
          pattern = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status=5*, size]"
          metric_transformation = {
            name      = "5xxErrors"
            namespace = "MyApp/API"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "api-gateway-to-kinesis"
          destination_arn = aws_kinesis_stream.logs.arn
          filter_pattern  = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status>=400, size]"
          role_arn        = aws_iam_role.kinesis_logs_role.arn
          distribution    = "ByLogStream"
        }
      ]
    }

    "/aws/ecs/my-service" = {
      retention_in_days = 30
      
      log_streams = ["task-1", "task-2", "task-3"]
      
      metric_filters = [
        {
          name    = "oom-errors"
          pattern = "OutOfMemoryError"
          metric_transformation = {
            name      = "OOMErrors"
            namespace = "MyApp/ECS"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

### WAF Logs Configuration

```terraform
module "waf_logs" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/cloudwatch?ref=v1.0.0"

  create_single_log_group = false

  log_groups = {
    "/aws/waf/production" = {
      retention_in_days = 90
      skip_destroy     = true
      
      metric_filters = [
        {
          name    = "blocked-requests"
          pattern = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\"]"
          metric_transformation = {
            name      = "BlockedRequests"
            namespace = "WAF/Security"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "rate-limited-requests"
          pattern = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\", ruleId=\"rate-limit*\"]"
          metric_transformation = {
            name      = "RateLimitedRequests"
            namespace = "WAF/Security"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "bot-requests"
          pattern = "[timestamp, requestId, clientIp, country, uri, action, terminatingRuleId, terminatingRuleType, action, labels=\"*bot*\"]"
          metric_transformation = {
            name      = "BotRequests"
            namespace = "WAF/Security"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "waf-security-analysis"
          destination_arn = aws_kinesis_firehose_delivery_stream.security_logs.arn
          filter_pattern  = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\"]"
          role_arn        = aws_iam_role.waf_logs_role.arn
        }
      ]
      
      tags = {
        Security    = "high"
        Compliance  = "required"
        AlertLevel  = "critical"
      }
    }

    "/aws/waf/staging" = {
      retention_in_days = 30
      
      metric_filters = [
        {
          name    = "staging-blocked-requests"
          pattern = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\"]"
          metric_transformation = {
            name      = "StagingBlockedRequests"
            namespace = "WAF/Staging"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
    }
  }

  tags = {
    Environment = "multi"
    Service     = "waf"
    Purpose     = "security-monitoring"
  }
}
```

### Application Logs with Structured Logging

```terraform
module "app_logs" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/cloudwatch?ref=v1.0.0"

  create_single_log_group = false
  default_retention_in_days = 30

  log_groups = {
    "/myapp/production/api" = {
      retention_in_days = 90
      
      metric_filters = [
        {
          name    = "error-rate"
          pattern = "[timestamp, level=\"ERROR\", message]"
          metric_transformation = {
            name      = "ErrorRate"
            namespace = "MyApp/Production"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "response-time"
          pattern = "[timestamp, level, message, duration]"
          metric_transformation = {
            name      = "ResponseTime"
            namespace = "MyApp/Production"
            value     = "$duration"
            unit      = "Milliseconds"
          }
        },
        {
          name    = "memory-usage"
          pattern = "[timestamp, level, message, memory_mb]"
          metric_transformation = {
            name      = "MemoryUsage"
            namespace = "MyApp/Production"
            value     = "$memory_mb"
            unit      = "Megabytes"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "app-logs-to-elasticsearch"
          destination_arn = aws_elasticsearch_domain.app_logs.arn
          filter_pattern  = ""
          role_arn        = aws_iam_role.elasticsearch_logs_role.arn
        },
        {
          name            = "error-alerts"
          destination_arn = aws_lambda_function.error_processor.arn
          filter_pattern  = "[timestamp, level=\"ERROR\", message]"
        }
      ]
      
      tags = {
        Application = "myapp"
        Component   = "api"
        Environment = "production"
      }
    }

    "/myapp/production/database" = {
      retention_in_days = 60
      kms_key_id       = aws_kms_key.database_logs.arn
      
      metric_filters = [
        {
          name    = "slow-queries"
          pattern = "[timestamp, level, message, query_time > 1000]"
          metric_transformation = {
            name      = "SlowQueries"
            namespace = "MyApp/Database"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "connection-errors"
          pattern = "[timestamp, level=\"ERROR\", message=\"*connection*\"]"
          metric_transformation = {
            name      = "ConnectionErrors"
            namespace = "MyApp/Database"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
    }

    "/myapp/production/auth" = {
      retention_in_days = 180  # Keep auth logs longer for security
      skip_destroy     = true
      
      metric_filters = [
        {
          name    = "failed-logins"
          pattern = "[timestamp, level, event=\"login_failed\", user_id, ip]"
          metric_transformation = {
            name      = "FailedLogins"
            namespace = "MyApp/Security"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "suspicious-activity"
          pattern = "[timestamp, level=\"WARN\", event=\"*suspicious*\", user_id, ip]"
          metric_transformation = {
            name      = "SuspiciousActivity"
            namespace = "MyApp/Security"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "security-alerts"
          destination_arn = aws_sns_topic.security_alerts.arn
          filter_pattern  = "[timestamp, level=\"ERROR\", event=\"*failed*\" || event=\"*suspicious*\", user_id, ip]"
          role_arn        = aws_iam_role.sns_logs_role.arn
        }
      ]
      
      tags = {
        Security   = "critical"
        Compliance = "pci-dss"
        Retention  = "extended"
      }
    }
  }

  tags = {
    Environment = "production"
    Application = "myapp"
    Team        = "platform"
  }
}
```

## Input Variables

### Single Log Group Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_single_log_group` | Whether to create a single log group | `bool` | `false` |
| `log_group_name` | Name of the single log group | `string` | `""` |
| `retention_in_days` | Retention period for single log group | `number` | `30` |
| `kms_key_id` | KMS key ID for single log group encryption | `string` | `null` |
| `skip_destroy` | Skip destroy for single log group | `bool` | `false` |
| `log_streams` | List of log stream names for single log group | `list(string)` | `[]` |
| `metric_filters` | List of metric filters for single log group | `list(object)` | `[]` |
| `subscription_filters` | List of subscription filters for single log group | `list(object)` | `[]` |

### Multiple Log Groups Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `log_groups` | Map of log groups with their configurations | `map(object)` | `{}` |
| `default_retention_in_days` | Default retention period for log groups | `number` | `30` |
| `default_kms_key_id` | Default KMS key ID for log groups | `string` | `null` |
| `default_skip_destroy` | Default skip destroy setting | `bool` | `false` |

### Common Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tags` | Tags to apply to all resources | `map(string)` | `{}` |

## Log Groups Configuration Structure

```terraform
log_groups = {
  "log-group-name" = {
    retention_in_days = 30           # Optional, uses default if not specified
    kms_key_id       = "kms-key-arn" # Optional, uses default if not specified
    skip_destroy     = false         # Optional, uses default if not specified
    
    log_streams = ["stream1", "stream2"]  # Optional
    
    metric_filters = [
      {
        name    = "filter-name"
        pattern = "log-pattern"
        metric_transformation = {
          name          = "MetricName"
          namespace     = "Custom/Namespace"
          value         = "1"                    # Optional, defaults to "1"
          default_value = "0"                    # Optional
          unit          = "Count"                # Optional, defaults to "None"
        }
      }
    ]
    
    subscription_filters = [
      {
        name            = "subscription-name"
        destination_arn = "destination-arn"
        filter_pattern  = "filter-pattern"      # Optional, defaults to ""
        role_arn        = "role-arn"           # Optional for some destinations
        distribution    = "ByLogStream"        # Optional: ByLogStream, Random
      }
    ]
    
    tags = {
      "CustomTag" = "value"  # Merged with global tags
    }
  }
}
```

## Metric Filter Patterns Examples

### Application Logs
```terraform
# Error counting
pattern = "[timestamp, level=\"ERROR\", message]"

# Response time extraction
pattern = "[timestamp, level, message, duration]"
value   = "$duration"

# Memory usage monitoring
pattern = "[timestamp, level, memory_usage=*MB]"
value   = "$memory_usage"
```

### API Gateway Logs
```terraform
# 4xx errors
pattern = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status=4*, size]"

# 5xx errors
pattern = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status=5*, size]"

# Response time
pattern = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status, size, response_time]"
value   = "$response_time"
```

### WAF Logs
```terraform
# Blocked requests
pattern = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\"]"

# Rate limited requests
pattern = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\", ruleId=\"rate-limit*\"]"

# Bot detection
pattern = "[timestamp, requestId, clientIp, country, uri, action, terminatingRuleId, terminatingRuleType, action, labels=\"*bot*\"]"
```

### Lambda Logs
```terraform
# Cold start detection
pattern = "[timestamp, request_id, level, message=\"*INIT_START*\"]"

# Memory usage
pattern = "[timestamp=\"REPORT\", request_id, duration, billed_duration, memory_size, max_memory_used]"
value   = "$max_memory_used"

# Errors with stack traces
pattern = "[timestamp, request_id, level=\"ERROR\", message, stack_trace]"
```

## Outputs

| Name | Description |
|------|-------------|
| `single_log_group` | Single log group details |
| `multiple_log_groups` | Map of multiple log groups |
| `log_streams` | Map of all log streams |
| `metric_filters` | Map of all metric filters |
| `subscription_filters` | Map of all subscription filters |

## Complete Production Setup Example

```terraform
# KMS key for log encryption
resource "aws_kms_key" "logs" {
  description             = "KMS key for CloudWatch logs encryption"
  deletion_window_in_days = 7
  
  tags = {
    Name        = "cloudwatch-logs-key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "logs" {
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# Elasticsearch domain for log analysis
resource "aws_elasticsearch_domain" "logs" {
  domain_name           = "app-logs"
  elasticsearch_version = "7.10"
  
  cluster_config {
    instance_type = "t3.small.elasticsearch"
  }
  
  ebs_options {
    ebs_enabled = true
    volume_size = 20
  }
}

# IAM role for log subscription to Elasticsearch
resource "aws_iam_role" "logs_role" {
  name = "cloudwatch-logs-elasticsearch-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "logs_policy" {
  name = "cloudwatch-logs-elasticsearch-policy"
  role = aws_iam_role.logs_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut"
        ]
        Resource = "${aws_elasticsearch_domain.logs.arn}/*"
      }
    ]
  })
}

# Comprehensive logging setup
module "production_logs" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/cloudwatch?ref=v1.0.0"

  create_single_log_group   = false
  default_retention_in_days = 30
  default_kms_key_id       = aws_kms_key.logs.arn
  default_skip_destroy     = false

  log_groups = {
    # API Gateway logs
    "/aws/apigateway/production-api" = {
      retention_in_days = 90
      skip_destroy     = true
      
      metric_filters = [
        {
          name    = "4xx-errors"
          pattern = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status=4*, size]"
          metric_transformation = {
            name      = "API4xxErrors"
            namespace = "MyApp/API"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "5xx-errors"
          pattern = "[timestamp, request_id, ip, user, timestamp, method, uri, protocol, status=5*, size]"
          metric_transformation = {
            name      = "API5xxErrors"
            namespace = "MyApp/API"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "api-to-elasticsearch"
          destination_arn = aws_elasticsearch_domain.logs.arn
          filter_pattern  = ""
          role_arn        = aws_iam_role.logs_role.arn
        }
      ]
    }

    # Lambda function logs
    "/aws/lambda/api-handler" = {
      retention_in_days = 60
      
      log_streams = ["main", "errors", "debug"]
      
      metric_filters = [
        {
          name    = "lambda-errors"
          pattern = "[timestamp, request_id, level=\"ERROR\", message]"
          metric_transformation = {
            name      = "LambdaErrors"
            namespace = "MyApp/Lambda"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "lambda-duration"
          pattern = "[timestamp=\"REPORT\", request_id, duration, billed_duration, memory_size, max_memory_used]"
          metric_transformation = {
            name      = "LambdaDuration"
            namespace = "MyApp/Lambda"
            value     = "$duration"
            unit      = "Milliseconds"
          }
        }
      ]
    }

    # WAF logs
    "/aws/waf/production" = {
      retention_in_days = 180
      skip_destroy     = true
      
      metric_filters = [
        {
          name    = "blocked-requests"
          pattern = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\"]"
          metric_transformation = {
            name      = "WAFBlockedRequests"
            namespace = "Security/WAF"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "waf-security-monitoring"
          destination_arn = aws_kinesis_stream.security_logs.arn
          filter_pattern  = "[timestamp, requestId, clientIp, country, uri, action=\"BLOCK\"]"
          role_arn        = aws_iam_role.kinesis_logs_role.arn
        }
      ]
      
      tags = {
        Security = "high"
        Compliance = "required"
      }
    }

    # Application logs
    "/myapp/production/backend" = {
      retention_in_days = 90
      
      metric_filters = [
        {
          name    = "error-rate"
          pattern = "[timestamp, level=\"ERROR\", component, message]"
          metric_transformation = {
            name      = "ApplicationErrors"
            namespace = "MyApp/Backend"
            value     = "1"
            unit      = "Count"
          }
        },
        {
          name    = "database-slow-queries"
          pattern = "[timestamp, level, component=\"database\", query_time > 1000, message]"
          metric_transformation = {
            name      = "SlowQueries"
            namespace = "MyApp/Database"
            value     = "1"
            unit      = "Count"
          }
        }
      ]
      
      subscription_filters = [
        {
          name            = "app-to-elasticsearch"
          destination_arn = aws_elasticsearch_domain.logs.arn
          filter_pattern  = ""
          role_arn        = aws_iam_role.logs_role.arn
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "myapp"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# CloudWatch alarms based on log metrics
resource "aws_cloudwatch_metric_alarm" "api_error_rate" {
  alarm_name          = "api-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "API5xxErrors"
  namespace           = "MyApp/API"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API 5xx error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "waf-blocked-requests-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WAFBlockedRequests"
  namespace           = "Security/WAF"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "High number of blocked requests detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}
```

## Best Practices

### 1. Retention Policies
- **Development**: 7-14 days
- **Staging**: 30 days
- **Production**: 90+ days
- **Security/Audit**: 180+ days
- **Compliance**: As required (often 7+ years)

### 2. Log Organization
```
/aws/service/environment-resource
/myapp/environment/component
/security/service/environment
```

### 3. Metric Filter Optimization
- Use specific patterns to reduce CloudWatch costs
- Extract numeric values for trending
- Create separate filters for different metric types
- Use default values for missing data points

### 4. Subscription Filter Strategy
- Route error logs to immediate alerting systems
- Send all logs to long-term storage (S3 via Kinesis)
- Use multiple filters for different processing pipelines
- Consider data transformation before sending to destinations

### 5. Security Considerations
- Enable KMS encryption for sensitive logs
- Use appropriate IAM roles for cross-service access
- Set `skip_destroy = true` for critical log groups
- Implement proper log retention for compliance

### 6. Cost Optimization
- Use appropriate retention periods
- Filter logs before sending to expensive destinations
- Consider log sampling for high-volume applications
- Monitor CloudWatch costs and adjust accordingly

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_cloudwatch_log_group | resource |
| aws_cloudwatch_log_stream | resource |
| aws_cloudwatch_log_metric_filter | resource |
| aws_cloudwatch_log_subscription_filter | resource |

## License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for full details.