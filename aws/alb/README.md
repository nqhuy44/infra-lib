# AWS Application Load Balancer (ALB) Module

This Terraform module creates and manages an AWS Application Load Balancer with support for multiple listeners, target groups, routing rules, access logs, and security configurations.

## Features

- ✅ **Application Load Balancer** with customizable configuration
- ✅ **Multiple Target Groups** with health checks and stickiness
- ✅ **HTTP and HTTPS Listeners** with SSL/TLS support
- ✅ **Advanced Routing Rules** (path-based, host-based, header-based)
- ✅ **Target Group Attachments** for EC2 instances and IP targets
- ✅ **Access Logs** to S3 bucket
- ✅ **Security Group Integration**
- ✅ **IPv4 and Dual Stack** support

## Usage

### Basic ALB with Target Groups

```hcl
module "web_alb" {
  source = "github.com/your-org/terraform-modules//aws/alb?ref=main"

  name            = "web-alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  security_groups = [module.alb_sg.security_group_id]
  
  # Target groups configuration
  target_groups = {
    web = {
      name     = "web-tg"
      port     = 80
      protocol = "HTTP"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
      instance_ids = [
        module.web_server1.instance_id,
        module.web_server2.instance_id
      ]
    }
  }
  
  # Listeners configuration
  listeners = {
    http = {
      port                = 80
      protocol            = "HTTP"
      target_group_key    = "web"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### HTTPS ALB with SSL Certificate

```hcl
module "secure_alb" {
  source = "github.com/your-org/terraform-modules//aws/alb?ref=main"

  name            = "secure-alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  security_groups = [module.alb_sg.security_group_id]
  
  # Target groups
  target_groups = {
    app = {
      name     = "app-tg"
      port     = 8080
      protocol = "HTTP"
      health_check = {
        enabled = true
        path    = "/api/health"
        matcher = "200"
      }
      instance_ids = [module.app_server.instance_id]
    }
  }
  
  # Listeners
  listeners = {
    # HTTP to HTTPS redirect
    http = {
      port             = 80
      protocol         = "HTTP"
      redirect_to_https = true
      redirect_port     = "443"
    }
    
    # HTTPS listener
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.certificate_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      target_group_key = "app"
    }
  }
  
  # Enable access logs
  access_logs_enabled = true
  access_logs_bucket  = module.log_bucket.bucket_id
  access_logs_prefix  = "alb-logs/"
  
  tags = {
    Environment = "production"
    Security    = "high"
  }
}
```

### Path-Based Routing

```hcl
module "routing_alb" {
  source = "github.com/your-org/terraform-modules//aws/alb?ref=main"

  name            = "routing-alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  security_groups = [module.alb_sg.security_group_id]
  
  # Multiple target groups
  target_groups = {
    api = {
      name     = "api-tg"
      port     = 8080
      protocol = "HTTP"
      health_check = {
        path = "/api/health"
      }
      instance_ids = [module.api_server.instance_id]
    }
    
    admin = {
      name     = "admin-tg"
      port     = 8081
      protocol = "HTTP"
      health_check = {
        path = "/admin/health"
      }
      instance_ids = [module.admin_server.instance_id]
    }
    
    web = {
      name     = "web-tg"
      port     = 80
      protocol = "HTTP"
      instance_ids = [module.web_server.instance_id]
    }
  }
  
  # HTTPS listener with routing rules
  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.certificate_arn
      
      # Default action (fallback)
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
      
      # Routing rules
      rules = [
        {
          priority         = 100
          target_group_key = "api"
          path_pattern     = ["/api/*"]
        },
        {
          priority         = 200
          target_group_key = "admin"
          path_pattern     = ["/admin/*"]
        },
        {
          priority         = 300
          target_group_key = "web"
          path_pattern     = ["/*"]
        }
      ]
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Host-Based Routing

```hcl
module "multi_domain_alb" {
  source = "github.com/your-org/terraform-modules//aws/alb?ref=main"

  name            = "multi-domain-alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  security_groups = [module.alb_sg.security_group_id]
  
  target_groups = {
    api = {
      name     = "api-tg"
      port     = 8080
      protocol = "HTTP"
      target_type = "ip"
      # IP targets for ECS/Fargate
    }
    
    web = {
      name     = "web-tg"
      port     = 80
      protocol = "HTTP"
      instance_ids = [module.web_server.instance_id]
    }
  }
  
  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.wildcard_cert.certificate_arn
      
      # Default 404 response
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Domain not configured"
        status_code  = "404"
      }
      
      # Host-based routing rules
      rules = [
        {
          priority         = 100
          target_group_key = "api"
          host_header      = ["api.example.com"]
        },
        {
          priority         = 200
          target_group_key = "web"
          host_header      = ["www.example.com", "example.com"]
        }
      ]
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### ALB for ECS Fargate

```hcl
module "ecs_alb" {
  source = "github.com/your-org/terraform-modules//aws/alb?ref=main"

  name            = "ecs-alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  security_groups = [module.alb_sg.security_group_id]
  
  # Target group for ECS Fargate (IP targets)
  target_groups = {
    ecs_app = {
      name                 = "ecs-app-tg"
      port                 = 8080
      protocol             = "HTTP"
      target_type          = "ip"  # Required for Fargate
      deregistration_delay = 60    # Faster for containers
      
      health_check = {
        enabled             = true
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
      
      # No instance_ids - ECS service will register targets automatically
    }
  }
  
  listeners = {
    http = {
      port             = 80
      protocol         = "HTTP"
      target_group_key = "ecs_app"
    }
  }
  
  tags = {
    Environment = "production"
    Service     = "ecs-fargate"
  }
}

# Output target group ARN for ECS service
output "ecs_target_group_arn" {
  value = module.ecs_alb.target_groups["ecs_app"].arn
}
```

### Advanced Configuration with Multiple Features

```hcl
module "advanced_alb" {
  source = "github.com/your-org/terraform-modules//aws/alb?ref=main"

  name                       = "advanced-alb"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  security_groups            = [module.alb_sg.security_group_id]
  
  # ALB configuration
  internal                   = false
  enable_deletion_protection = true
  drop_invalid_header_fields = true
  enable_http2              = true
  idle_timeout              = 120
  ip_address_type           = "dualstack"  # IPv4 and IPv6
  
  # Target groups with different configurations
  target_groups = {
    api_v1 = {
      name                 = "api-v1-tg"
      port                 = 8080
      protocol             = "HTTP"
      target_type          = "instance"
      deregistration_delay = 300
      
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/v1/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200,202"
      }
      
      # Session stickiness
      stickiness = {
        enabled         = true
        type            = "lb_cookie"
        cookie_duration = 86400
      }
      
      instance_ids = [module.api_v1_server.instance_id]
    }
    
    api_v2 = {
      name     = "api-v2-tg"
      port     = 8080
      protocol = "HTTP"
      health_check = {
        path = "/v2/health"
      }
      instance_ids = [module.api_v2_server.instance_id]
    }
  }
  
  # Complex listener configuration
  listeners = {
    http = {
      port             = 80
      protocol         = "HTTP"
      redirect_to_https = true
    }
    
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.certificate_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      
      # Default action
      action_type = "fixed-response"
      fixed_response = {
        content_type = "application/json"
        message_body = jsonencode({
          error = "API version not specified"
          message = "Please specify API version in path"
        })
        status_code = "400"
      }
      
      # Advanced routing rules
      rules = [
        {
          priority         = 100
          target_group_key = "api_v1"
          path_pattern     = ["/v1/*", "/api/v1/*"]
          http_header = {
            name   = "X-API-Version"
            values = ["v1", "1.0"]
          }
        },
        {
          priority         = 200
          target_group_key = "api_v2"
          path_pattern     = ["/v2/*", "/api/v2/*"]
          http_header = {
            name   = "X-API-Version"
            values = ["v2", "2.0"]
          }
        },
        {
          priority    = 300
          action_type = "redirect"
          path_pattern = ["/docs", "/documentation"]
          redirect = {
            protocol    = "HTTPS"
            port        = "443"
            host        = "docs.example.com"
            path        = "/"
            status_code = "HTTP_301"
          }
        }
      ]
    }
  }
  
  # Access logs configuration
  access_logs_enabled = true
  access_logs_bucket  = module.log_bucket.bucket_id
  access_logs_prefix  = "alb-logs/advanced-alb/"
  
  tags = {
    Environment = "production"
    Project     = "advanced-api"
    Team        = "platform"
  }
}
```

## Input Variables

### Required Variables

| Name            | Description                                      | Type           |
|-----------------|--------------------------------------------------|----------------|
| `name`          | Name of the ALB                                 | `string`       |
| `vpc_id`        | VPC ID where the ALB will be deployed           | `string`       |
| `subnet_ids`    | List of subnet IDs to attach to the ALB         | `list(string)` |
| `security_groups` | List of security group IDs for the ALB        | `list(string)` |

### Optional Variables

| Name                       | Description                                    | Type           | Default    |
|----------------------------|------------------------------------------------|----------------|------------|
| `internal`                 | Whether the ALB is internal                   | `bool`         | `false`    |
| `enable_deletion_protection` | Enable deletion protection                   | `bool`         | `false`    |
| `drop_invalid_header_fields` | Drop invalid header fields                  | `bool`         | `true`     |
| `enable_http2`             | Enable HTTP/2                                  | `bool`         | `true`     |
| `idle_timeout`             | Idle timeout in seconds                        | `number`       | `60`       |
| `ip_address_type`          | IP address type (`ipv4` or `dualstack`)        | `string`       | `"ipv4"`   |
| `subnet_mapping`           | Subnet mapping configuration                   | `any`          | `{}`       |

### Access Logs

| Name                  | Description                      | Type     | Default |
|-----------------------|----------------------------------|----------|---------|
| `access_logs_enabled` | Enable access logs               | `bool`   | `false` |
| `access_logs_bucket`  | S3 bucket for access logs        | `string` | `null`  |
| `access_logs_prefix`  | S3 prefix for access logs        | `string` | `""`    |

### Target Groups

| Name            | Description                         | Type  | Default |
|-----------------|-------------------------------------|-------|---------|
| `target_groups` | Map of target group configurations  | `any` | `{}`    |

#### Target Group Configuration

```hcl
target_groups = {
  "group_name" = {
    name                 = "target-group-name"          # Required
    port                 = 80                           # Required
    protocol             = "HTTP"                       # Required
    target_type          = "instance"                   # Optional: instance, ip, lambda
    deregistration_delay = 300                          # Optional: 0-3600 seconds
    
    # Health check configuration
    health_check = {
      enabled             = true                        # Optional
      interval            = 30                          # Optional: 5-300 seconds
      path                = "/"                         # Optional
      port                = "traffic-port"              # Optional
      healthy_threshold   = 3                           # Optional: 2-10
      unhealthy_threshold = 3                           # Optional: 2-10
      timeout             = 5                           # Optional: 2-120 seconds
      protocol            = "HTTP"                      # Optional
      matcher             = "200"                       # Optional
    }
    
    # Session stickiness
    stickiness = {
      enabled         = false                           # Optional
      type            = "lb_cookie"                     # Optional: lb_cookie, app_cookie
      cookie_duration = 86400                           # Optional: 1-604800 seconds
      cookie_name     = null                            # Optional: for app_cookie type
    }
    
    # Target attachments (for EC2 instances)
    instance_ids = ["i-1234567890abcdef0"]              # Optional
    
    # For IP targets, use target_port if different from port
    target_port = 8080                                  # Optional
  }
}
```

### Listeners

| Name        | Description                    | Type  | Default |
|-------------|--------------------------------|-------|---------|
| `listeners` | Map of listener configurations | `any` | `{}`    |

#### Listener Configuration

```hcl
listeners = {
  "listener_name" = {
    port                = 80                            # Required
    protocol            = "HTTP"                        # Required: HTTP, HTTPS
    certificate_arn     = "arn:aws:acm:..."             # Required for HTTPS
    ssl_policy          = "ELBSecurityPolicy-TLS13-1-2-2021-06" # Optional
    
    # Default action
    action_type         = "forward"                     # Optional: forward, fixed-response, redirect
    target_group_key    = "group_name"                  # Required for forward action
    
    # For redirect action (HTTP to HTTPS)
    redirect_to_https   = true                          # Optional
    redirect_port       = "443"                         # Optional
    
    # For fixed-response action
    fixed_response = {
      content_type = "text/plain"                       # Required
      message_body = "Not Found"                        # Optional
      status_code  = "404"                              # Optional
    }
    
    # Listener rules
    rules = [
      {
        priority         = 100                          # Optional
        target_group_key = "target_group_name"          # Required for forward
        action_type      = "forward"                    # Optional
        
        # Conditions (at least one required)
        host_header      = ["api.example.com"]          # Optional
        path_pattern     = ["/api/*"]                   # Optional
        
        http_header = {                                 # Optional
          name   = "X-Custom-Header"
          values = ["value1", "value2"]
        }
        
        http_request_method = ["GET", "POST"]           # Optional
        
        query_string = {                                # Optional
          key   = "version"
          value = "v1"
        }
        
        source_ip = ["10.0.0.0/8"]                      # Optional
        
        # For redirect rules
        redirect = {
          protocol    = "HTTPS"                         # Optional
          port        = "443"                           # Optional
          host        = "#{host}"                       # Optional
          path        = "/new-path"                     # Optional
          query       = "#{query}"                      # Optional
          status_code = "HTTP_301"                      # Optional
        }
        
        # For fixed-response rules
        fixed_response = {
          content_type = "application/json"             # Required
          message_body = "{\"error\": \"Not found\"}"  # Optional
          status_code  = "404"                          # Optional
        }
      }
    ]
  }
}
```

### Tags

| Name   | Description                         | Type            | Default |
|--------|-------------------------------------|-----------------|---------|
| `tags` | Map of tags to add to all resources | `map(string)`   | `{}`    |

## Outputs

| Name               | Description                                  |
|--------------------|----------------------------------------------|
| `arn`              | ARN of the ALB                              |
| `dns_name`         | DNS name of the ALB                          |
| `zone_id`          | Canonical hosted zone ID of the ALB         |
| `id`               | ID of the ALB                                |
| `target_groups`    | Map of target groups and their attributes   |
| `http_listeners`   | Map of HTTP listeners and their attributes  |
| `https_listeners`  | Map of HTTPS listeners and their attributes |
| `listener_rules`   | Map of listener rules and their attributes  |

## Examples Output Usage

```hcl
# Get ALB DNS name for Route53 record
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"

  alias {
    name                   = module.web_alb.dns_name
    zone_id                = module.web_alb.zone_id
    evaluate_target_health = true
  }
}

# Use target group ARN in ECS service
resource "aws_ecs_service" "app" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  load_balancer {
    target_group_arn = module.ecs_alb.target_groups["ecs_app"].arn
    container_name   = "app"
    container_port   = 8080
  }
}
```

## Security Considerations

### Security Group Configuration

```hcl
resource "aws_security_group" "alb" {
  name_prefix = "alb-sg-"
  vpc_id      = module.vpc.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to targets
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    Name = "alb-security-group"
  }
}
```

### SSL/TLS Best Practices

- Use modern SSL policies: `ELBSecurityPolicy-TLS13-1-2-2021-06`
- Always redirect HTTP to HTTPS in production
- Use ACM certificates with automatic renewal
- Enable `drop_invalid_header_fields` for security

### Access Logs

Enable access logs for compliance and monitoring:

```hcl
# S3 bucket for ALB access logs
module "alb_logs_bucket" {
  source = "github.com/your-org/terraform-modules//aws/s3?ref=main"
  
  bucket_name = "alb-access-logs-${random_id.suffix.hex}"
  
  # ALB access logs bucket policy
  bucket_policy = data.aws_iam_policy_document.alb_logs.json
  
  lifecycle_rules = [
    {
      id     = "delete_old_logs"
      status = "Enabled"
      
      expiration = {
        days = 90
      }
      
      noncurrent_version_expiration = {
        days = 30
      }
    }
  ]
}

# Bucket policy for ALB access logs
data "aws_iam_policy_document" "alb_logs" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
    
    actions = ["s3:PutObject"]
    
    resources = ["${module.alb_logs_bucket.bucket_arn}/alb-logs/*"]
  }
}

data "aws_elb_service_account" "current" {}
```

## Requirements

| Name        | Version   |
|-------------|-----------|
| terraform   | ~> 1.3    |
| aws         | ~> 5.97.0 |

## License

This module is released under the MIT License.