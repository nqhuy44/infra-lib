# AWS WAF v2 Terraform Module

This module creates and manages AWS WAF v2 Web ACLs with advanced logging capabilities, managed rules, custom rules, IP sets, and comprehensive security configurations.

## Features

- ✅ **WAF v2 Web ACL** with flexible rule configuration
- ✅ **Managed Rule Groups** from AWS and third-party providers  
- ✅ **Custom Rules** with advanced statement types and conditions
- ✅ **IP Sets** for allowlist/blocklist management
- ✅ **Regex Pattern Sets** for advanced pattern matching
- ✅ **CloudWatch Logging** with configurable filters and redaction
- ✅ **Resource Association** (ALB, CloudFront, API Gateway)
- ✅ **CAPTCHA & Challenge** actions with immunity time
- ✅ **Rate Limiting** with scope-down statements
- ✅ **Field Redaction** for sensitive data protection
- ✅ **Custom Response Bodies** for blocked requests
- ✅ **SQL Injection & XSS Protection** statements
- ✅ **Size Constraint** and advanced logic statements (AND, OR, NOT)

## Usage

### Basic WAF with Managed Rules

```terraform
module "basic_waf" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/waf?ref=v1.0.0"

  name        = "production-waf"
  description = "Production Web Application Firewall"
  scope       = "REGIONAL"  # or "CLOUDFRONT"

  default_action = "allow"

  managed_rule_groups = [
    {
      name                         = "AWSManagedRulesCommonRuleSet"
      priority                     = 1
      rule_group_name             = "AWSManagedRulesCommonRuleSet"
      vendor_name                 = "AWS"
      override_action             = "none"
      cloudwatch_metrics_enabled = true
      metric_name                 = "CommonRuleSet"
      sampled_requests_enabled    = true
      
      # Rule action overrides for specific rules
      rule_action_overrides = {
        "SizeRestrictions_BODY" = "count"
        "GenericRFI_BODY"       = "allow"
      }
    },
    {
      name                         = "AWSManagedRulesKnownBadInputsRuleSet"
      priority                     = 2
      rule_group_name             = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name                 = "AWS"
      override_action             = "none"
      cloudwatch_metrics_enabled = true
      metric_name                 = "KnownBadInputs"
      sampled_requests_enabled    = true
    }
  ]

  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
```

### Advanced WAF with Custom Rules and Multiple Statement Types

```terraform
module "advanced_waf" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/waf?ref=v1.0.0"

  name  = "advanced-security-waf"
  scope = "REGIONAL"

  # IP Sets for allowlist/blocklist
  ip_sets = {
    office_allowlist = {
      name               = "office-ips"
      description        = "Office IP addresses"
      ip_address_version = "IPV4"
      addresses          = ["203.0.113.0/24", "198.51.100.0/24"]
    }
    
    threat_blocklist = {
      name               = "threat-ips"
      description        = "Known threat IP addresses"
      ip_address_version = "IPV4"
      addresses          = ["192.0.2.44/32", "192.0.2.45/32"]
    }
  }

  # Regex pattern sets for advanced matching
  regex_pattern_sets = {
    malicious_patterns = {
      description  = "Malicious request patterns"
      regex_string = "(?i)(union|select|insert|drop|delete|update).*"
    }
  }

  # Comprehensive custom rules
  custom_rules = [
    {
      name     = "AllowOfficeIPs"
      priority = 1
      action   = "allow"
      
      statement = {
        ip_set_reference_statement = {
          arn = "office_allowlist"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AllowOfficeIPs"
        sampled_requests_enabled   = true
      }
    },
    
    {
      name     = "BlockSQLInjection"
      priority = 5
      action   = "block"
      
      statement = {
        sqli_match_statement = {
          field_to_match = "body"
          text_transformation = {
            priority = 1
            type     = "URL_DECODE"
          }
        }
      }
      
      # Custom response for blocked SQL injection attempts
      block_custom_response = {
        response_code = 403
        response_body = "Access denied: Potential SQL injection detected"
        content_type  = "TEXT_PLAIN"
        response_headers = [
          {
            name  = "X-Security-Alert"
            value = "SQL-Injection-Detected"
          }
        ]
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "SQLInjectionBlocked"
        sampled_requests_enabled   = true
      }
    },
    
    {
      name     = "RateLimitAPI"
      priority = 10
      action   = "block"
      
      statement = {
        rate_based_statement = {
          limit                 = 2000
          aggregate_key_type    = "IP"
          evaluation_window_sec = 300
          
          # Scope down to only API endpoints
          scope_down_statement = {
            byte_match_statement = {
              field_to_match        = "uri_path"
              positional_constraint = "STARTS_WITH"
              search_string         = "/api/"
              text_transformation = {
                priority = 1
                type     = "LOWERCASE"
              }
            }
          }
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "APIRateLimit"
        sampled_requests_enabled   = true
      }
    },
    
    {
      name     = "ChallengeBotsOnAdmin"
      priority = 15
      action   = "challenge"
      immunity_time = 300  # 5 minutes immunity after successful challenge
      
      statement = {
        byte_match_statement = {
          field_to_match        = "uri_path"
          positional_constraint = "STARTS_WITH"
          search_string         = "/admin"
          text_transformation = {
            priority = 1
            type     = "LOWERCASE"
          }
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AdminChallenge"
        sampled_requests_enabled   = true
      }
    },
    
    {
      name     = "SizeConstraintBody"
      priority = 20
      action   = "block"
      
      statement = {
        size_constraint_statement = {
          field_to_match        = "body"
          comparison_operator   = "GT"
          size                  = 8192  # 8KB limit
          text_transformation = {
            priority = 1
            type     = "NONE"
          }
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "OversizedRequests"
        sampled_requests_enabled   = true
      }
    }
  ]

  # Associate with multiple ALBs
  resource_arns = {
    main_alb = aws_lb.main.arn
    api_alb  = aws_lb.api.arn
  }

  # CAPTCHA/Challenge token domains
  token_domains = ["example.com", "api.example.com"]
  
  tags = {
    Environment = "production"
    Security    = "high"
    Team        = "security"
  }
}
```

### WAF with Comprehensive Logging Configuration

```terraform
module "waf_with_advanced_logging" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/waf?ref=v1.0.0"

  name  = "logging-waf"
  scope = "REGIONAL"

  # Enable comprehensive logging
  logging_enabled     = true
  log_destination_arn = aws_cloudwatch_log_group.waf_logs.arn

  # Advanced logging configuration
  logging_config = {
    log_blocked_only   = true
    log_captcha_only   = true
    log_challenge_only = true
    
    # Custom filters for specific threat types
    custom_filters = [
      {
        behavior    = "KEEP"
        requirement = "MEETS_ALL"
        actions     = ["BLOCK"]
        label_conditions = [
          {
            label_name = "awswaf:managed:aws:bot-control:bot:category:malicious"
          }
        ]
      },
      {
        behavior    = "KEEP"
        requirement = "MEETS_ANY"
        actions     = ["CAPTCHA", "CHALLENGE"]
      }
    ]
  }

  # Comprehensive field redaction for privacy
  redacted_fields = [
    { type = "single_header", name = "authorization" },
    { type = "single_header", name = "cookie" },
    { type = "single_header", name = "x-api-key" },
    { type = "single_header", name = "x-auth-token" },
    { type = "query_string" }
  ]

  managed_rule_groups = [
    {
      name                         = "AWSManagedRulesBotControlRuleSet"
      priority                     = 1
      rule_group_name             = "AWSManagedRulesBotControlRuleSet"
      vendor_name                 = "AWS"
      override_action             = "none"
      cloudwatch_metrics_enabled = true
      metric_name                 = "BotControl"
      sampled_requests_enabled    = true
    }
  ]
}
```

### Development Environment with Count Mode

```terraform
module "dev_waf" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/waf?ref=v1.0.0"

  name  = "dev-waf"
  scope = "REGIONAL"

  # Allow all by default for development
  default_action = "allow"

  # Log everything for debugging
  logging_enabled     = true
  log_destination_arn = aws_cloudwatch_log_group.dev_logs.arn

  logging_config = {
    log_all_requests = true  # Log everything in dev
  }

  # No redaction in development
  redacted_fields = []

  # Use managed rules in count mode for testing
  managed_rule_groups = [
    {
      name                         = "AWSManagedRulesCommonRuleSet"
      priority                     = 1
      rule_group_name             = "AWSManagedRulesCommonRuleSet"
      vendor_name                 = "AWS"
      override_action             = "count"  # Count instead of block
      cloudwatch_metrics_enabled = true
      metric_name                 = "CommonRuleSetDev"
      sampled_requests_enabled    = true
    }
  ]

  tags = {
    Environment = "development"
    Purpose     = "testing"
  }
}
```

## Input Variables

### Required Variables

| Name    | Description                               | Type     | Example            |
| ------- | ----------------------------------------- | -------- | ------------------ |
| `name`  | Name of the WAF Web ACL                   | `string` | `"production-waf"` |
| `scope` | Scope of the WAF (REGIONAL or CLOUDFRONT) | `string` | `"REGIONAL"`       |

### Optional Variables

| Name                     | Description                                  | Type           | Default      |
| ------------------------ | -------------------------------------------- | -------------- | ------------ |
| `description`            | Description of the WAF Web ACL               | `string`       | `"WAF WebACL"` |
| `default_action`         | Default action for requests (allow/block)    | `string`       | `"allow"`    |
| `cloudwatch_metrics_enabled` | Enable CloudWatch metrics               | `bool`         | `true`       |
| `metric_name`            | CloudWatch metric name                       | `string`       | `null`       |
| `sampled_requests_enabled`   | Enable sampled requests                  | `bool`         | `true`       |
| `managed_rule_groups`    | List of managed rule groups                  | `list(object)` | `[]`         |
| `custom_rules`           | List of custom rules                         | `list(object)` | `[]`         |
| `ip_sets`                | Map of IP sets to create                     | `map(object)`  | `{}`         |
| `regex_pattern_sets`     | Map of regex pattern sets                    | `map(object)`  | `{}`         |
| `resource_arns`          | Map of resource ARNs to associate            | `map(string)`  | `{}`         |
| `depends_on_resources`   | Resources to depend on before associations   | `list(any)`    | `[]`         |
| `token_domains`          | List of domains for CAPTCHA/Challenge        | `list(string)` | `[]`         |
| `tags`                   | Tags to apply to resources                   | `map(string)`  | `{}`         |

### Managed Rule Group Configuration

```terraform
managed_rule_groups = [
  {
    name                         = "AWSManagedRulesCommonRuleSet"
    priority                     = 1
    rule_group_name             = "AWSManagedRulesCommonRuleSet"
    vendor_name                 = "AWS"
    override_action             = "none"  # or "count"
    cloudwatch_metrics_enabled = true    # optional
    metric_name                 = "CommonRuleSet"  # optional
    sampled_requests_enabled    = true    # optional
    
    # Optional: Override specific rules within the rule group
    rule_action_overrides = {
      "SizeRestrictions_BODY" = "count"
      "GenericRFI_BODY"       = "allow"
    }
  }
]
```

### Custom Rules Configuration

Custom rules support multiple statement types:

#### IP Set Reference Statement
```terraform
custom_rules = [
  {
    name     = "AllowOfficeIPs"
    priority = 1
    action   = "allow"
    
    statement = {
      ip_set_reference_statement = {
        arn = "office_allowlist"  # References ip_sets key
      }
    }
    
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowOfficeIPs"
      sampled_requests_enabled   = true
    }
  }
]
```

#### Rate-Based Statement with Scope Down
```terraform
custom_rules = [
  {
    name     = "RateLimitAPI"
    priority = 10
    action   = "block"
    
    statement = {
      rate_based_statement = {
        limit                 = 2000
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
        
        scope_down_statement = {
          byte_match_statement = {
            field_to_match        = "uri_path"
            positional_constraint = "STARTS_WITH"
            search_string         = "/api/"
            text_transformation = {
              priority = 1
              type     = "LOWERCASE"
            }
          }
        }
      }
    }
    
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIRateLimit"
      sampled_requests_enabled   = true
    }
  }
]
```

#### SQL Injection Protection
```terraform
custom_rules = [
  {
    name     = "BlockSQLInjection"
    priority = 5
    action   = "block"
    
    statement = {
      sqli_match_statement = {
        field_to_match = "body"  # or "uri_path", "query_string", "header"
        header_name    = "Content-Type"  # required if field_to_match = "header"
        text_transformation = {
          priority = 1
          type     = "URL_DECODE"
        }
      }
    }
    
    # Optional: Custom response for blocked requests
    block_custom_response = {
      response_code = 403
      response_body = "Access denied: Potential SQL injection detected"
      content_type  = "TEXT_PLAIN"
      response_headers = [
        {
          name  = "X-Security-Alert"
          value = "SQL-Injection-Detected"
        }
      ]
    }
    
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionBlocked"
      sampled_requests_enabled   = true
    }
  }
]
```

#### Challenge/CAPTCHA Actions
```terraform
custom_rules = [
  {
    name         = "ChallengeBotsOnAdmin"
    priority     = 15
    action       = "challenge"  # or "captcha"
    immunity_time = 300  # 5 minutes immunity after successful challenge
    
    statement = {
      byte_match_statement = {
        field_to_match        = "uri_path"
        positional_constraint = "STARTS_WITH"
        search_string         = "/admin"
        text_transformation = {
          priority = 1
          type     = "LOWERCASE"
        }
      }
    }
    
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name                = "AdminChallenge"
      sampled_requests_enabled   = true
    }
  }
]
```

### Logging Configuration

| Name                  | Description                   | Type           | Default   |
| --------------------- | ----------------------------- | -------------- | --------- |
| `logging_enabled`     | Whether to enable WAF logging | `bool`         | `false`   |
| `log_destination_arn` | ARN of CloudWatch Log Group   | `string`       | `null`    |
| `logging_config`      | Logging configuration object  | `object`       | See below |
| `redacted_fields`     | List of fields to redact      | `list(object)` | `[]`      |

#### Logging Configuration Options

```terraform
logging_config = {
  log_all_requests    = false  # Log all requests (overrides filters)
  log_blocked_only    = true   # Log blocked requests
  log_allowed_only    = false  # Log allowed requests
  log_counted_only    = false  # Log counted requests
  log_captcha_only    = false  # Log CAPTCHA requests
  log_challenge_only  = false  # Log Challenge requests
  
  custom_filters = [
    {
      behavior    = "KEEP"     # KEEP or DROP
      requirement = "MEETS_ALL" # MEETS_ALL or MEETS_ANY
      actions     = ["BLOCK", "CAPTCHA"]
      label_conditions = [
        {
          label_name = "awswaf:managed:aws:bot-control:bot:verified"
          label_scope = "LABEL"  # LABEL or NAMESPACE
        }
      ]
    }
  ]
}
```

#### Redacted Fields Options

```terraform
redacted_fields = [
  { type = "method" },
  { type = "query_string" },
  { type = "uri_path" },
  { 
    type = "single_header"
    name = "authorization"  # Required for single_header
  }
]
```

## Outputs

| Name             | Description                        |
| ---------------- | ---------------------------------- |
| `web_acl_id`     | ID of the WAF Web ACL              |
| `web_acl_arn`    | ARN of the WAF Web ACL             |
| `web_acl_name`   | Name of the WAF Web ACL            |
| `web_acl_capacity` | Capacity units used by the Web ACL |
| `ip_sets`        | Map of created IP sets             |
| `arn`            | ARN of the WAF Web ACL (alias)     |
| `id`             | ID of the WAF Web ACL (alias)      |

## Statement Types Supported

This module supports all major WAF v2 statement types:

### Basic Statements
- **IP Set Reference** - Match against IP sets
- **Geo Match**