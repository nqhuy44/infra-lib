# AWS Network Load Balancer (NLB) Module

This Terraform module creates and manages an AWS Network Load Balancer with support for multiple target groups, listeners, health checks, and both TCP/UDP protocols. It supports internal and internet-facing load balancers with advanced features like cross-zone load balancing, proxy protocol, and client IP preservation.

## Features

- ✅ **Network Load Balancer** with TCP/UDP/TLS support
- ✅ **Multiple Target Groups** with customizable health checks
- ✅ **Instance and IP Target Types** for EC2 and containerized workloads
- ✅ **Cross-Zone Load Balancing** for even traffic distribution
- ✅ **Client IP Preservation** for maintaining source IP addresses
- ✅ **Proxy Protocol v2** support for backend applications
- ✅ **TLS Termination** with SSL/TLS certificates
- ✅ **Access Logs** to S3 bucket
- ✅ **Security Group Integration** (for NLB with security groups)
- ✅ **Health Check Customization** per target group

## Usage

### Basic TCP Load Balancer

```hcl
module "web_nlb" {
  source = "github.com/your-org/terraform-modules//aws/nlb?ref=main"
  
  name       = "web-nlb"
  internal   = false  # internet-facing
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id     = module.vpc.vpc_id
  
  cross_zone_enabled = true
  
  # Target groups
  target_groups = {
    web = {
      name         = "web-servers-tg"
      port         = 80
      protocol     = "TCP"
      instance_ids = [
        module.web_server_1.instance_id,
        module.web_server_2.instance_id
      ]
      health_check = {
        protocol            = "TCP"
        port                = "traffic-port"
        interval            = 30
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }
  
  # Listeners
  listeners = {
    web = {
      port             = 80
      protocol         = "TCP"
      target_group_key = "web"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### HTTPS/TLS Termination

```hcl
module "secure_nlb" {
  source = "github.com/your-org/terraform-modules//aws/nlb?ref=main"
  
  name       = "secure-nlb"
  internal   = false
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id     = module.vpc.vpc_id
  
  deletion_protection = true  # Enable for production
  
  target_groups = {
    app = {
      name         = "app-servers-tg"
      port         = 8080
      protocol     = "TCP"
      instance_ids = [
        module.app_server_1.instance_id,
        module.app_server_2.instance_id
      ]
      # Preserve client IP for application logs
      preserve_client_ip = true
      
      health_check = {
        protocol            = "HTTP"
        port                = "8080"
        path                = "/health"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 2
        unhealthy_threshold = 3
        matcher             = "200"
      }
    }
  }
  
  listeners = {
    https = {
      port            = 443
      protocol        = "TLS"
      target_group_key = "app"
      certificate_arn = module.acm_certificate.certificate_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    }
  }
  
  # Enable access logs
  access_logs_bucket = module.logs_bucket.bucket_id
  access_logs_prefix = "nlb-logs/"
  
  tags = {
    Environment = "production"
    Security    = "high"
  }
}
```

### Internal NLB for Microservices

```hcl
module "internal_nlb" {
  source = "github.com/your-org/terraform-modules//aws/nlb?ref=main"
  
  name       = "internal-api-nlb"
  internal   = true
  subnet_ids = module.vpc.private_subnet_ids
  vpc_id     = module.vpc.vpc_id
  
  # Security groups for internal NLB (optional)
  security_groups = [module.internal_nlb_sg.security_group_id]
  
  target_groups = {
    api_v1 = {
      name                 = "api-v1-tg"
      port                 = 8080
      protocol             = "TCP"
      deregistration_delay = 60  # Faster for containerized apps
      proxy_protocol_v2    = true  # Enable if backend supports it
      
      instance_ids = [
        module.api_v1_server_1.instance_id,
        module.api_v1_server_2.instance_id
      ]
      
      health_check = {
        protocol            = "HTTP"
        port                = "8080"
        path                = "/v1/health"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-299"
      }
    }
    
    api_v2 = {
      name         = "api-v2-tg"
      port         = 8081
      protocol     = "TCP"
      instance_ids = [module.api_v2_server.instance_id]
      
      health_check = {
        protocol            = "TCP"
        port                = "traffic-port"
        interval            = 30
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }
  
  listeners = {
    api_v1 = {
      port             = 8080
      protocol         = "TCP"
      target_group_key = "api_v1"
    }
    
    api_v2 = {
      port             = 8081
      protocol         = "TCP"
      target_group_key = "api_v2"
    }
  }
  
  tags = {
    Environment = "production"
    Service     = "internal-api"
    Team        = "backend"
  }
}
```

### UDP Load Balancer for Gaming

```hcl
module "game_server_nlb" {
  source = "github.com/your-org/terraform-modules//aws/nlb?ref=main"
  
  name       = "game-server-nlb"
  internal   = false
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id     = module.vpc.vpc_id
  
  cross_zone_enabled = true
  
  target_groups = {
    game_udp = {
      name         = "game-udp-tg"
      port         = 7777
      protocol     = "UDP"
      instance_ids = [
        module.game_server_1.instance_id,
        module.game_server_2.instance_id,
        module.game_server_3.instance_id
      ]
      
      # Preserve client IP for game session management
      preserve_client_ip = true
      
      # UDP health checks use TCP
      health_check = {
        protocol            = "TCP"
        port                = "7778"  # Separate health check port
        interval            = 30
        timeout             = 10
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
    
    game_tcp = {
      name         = "game-tcp-tg"
      port         = 7779
      protocol     = "TCP"
      instance_ids = [
        module.game_server_1.instance_id,
        module.game_server_2.instance_id,
        module.game_server_3.instance_id
      ]
      
      health_check = {
        protocol            = "TCP"
        port                = "traffic-port"
        interval            = 30
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }
  
  listeners = {
    game_udp = {
      port             = 7777
      protocol         = "UDP"
      target_group_key = "game_udp"
    }
    
    game_tcp = {
      port             = 7779
      protocol         = "TCP"
      target_group_key = "game_tcp"
    }
  }
  
  tags = {
    Environment = "production"
    Service     = "game-server"
    Protocol    = "udp-tcp"
  }
}
```

### NLB for ECS Fargate with IP Targets

```hcl
module "ecs_nlb" {
  source = "github.com/your-org/terraform-modules//aws/nlb?ref=main"
  
  name       = "ecs-app-nlb"
  internal   = true
  subnet_ids = module.vpc.private_subnet_ids
  vpc_id     = module.vpc.vpc_id
  
  # Note: For IP targets, we don't specify instance_ids
  # ECS service will register IP targets automatically
  target_groups = {
    ecs_app = {
      name                 = "ecs-app-tg"
      port                 = 8080
      protocol             = "TCP"
      deregistration_delay = 30  # Fast for containers
      
      # Empty instance_ids for IP target type
      instance_ids = []
      
      health_check = {
        protocol            = "HTTP"
        port                = "8080"
        path                = "/health"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
      }
    }
  }
  
  listeners = {
    app = {
      port             = 80
      protocol         = "TCP"
      target_group_key = "ecs_app"
    }
  }
  
  tags = {
    Environment = "production"
    Service     = "ecs-fargate"
  }
}

# Use target group ARN in ECS service
resource "aws_ecs_service" "app" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  
  load_balancer {
    target_group_arn = module.ecs_nlb.target_groups["ecs_app"].arn
    container_name   = "app"
    container_port   = 8080
  }
  
  depends_on = [module.ecs_nlb]
}
```

### Multi-Protocol NLB with Advanced Configuration

```hcl
module "multi_protocol_nlb" {
  source = "github.com/your-org/terraform-modules//aws/nlb?ref=main"
  
  name       = "multi-protocol-nlb"
  internal   = false
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id     = module.vpc.vpc_id
  
  # Production settings
  cross_zone_enabled  = true
  deletion_protection = true
  
  # Security groups (for NLB with security groups)
  security_groups = [
    module.nlb_security_group.security_group_id
  ]
  
  target_groups = {
    # HTTP API servers
    http_api = {
      name                 = "http-api-tg"
      port                 = 80
      protocol             = "TCP"
      deregistration_delay = 120
      preserve_client_ip   = true
      
      instance_ids = [
        module.api_server_1.instance_id,
        module.api_server_2.instance_id
      ]
      
      health_check = {
        protocol            = "HTTP"
        port                = "80"
        path                = "/api/health"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 3
        unhealthy_threshold = 3
        matcher             = "200"
      }
    }
    
    # HTTPS API servers with TLS termination
    https_api = {
      name         = "https-api-tg"
      port         = 8080
      protocol     = "TCP"
      target_port  = 8080  # Backend port different from listener port
      
      instance_ids = [
        module.api_server_1.instance_id,
        module.api_server_2.instance_id
      ]
      
      health_check = {
        protocol            = "HTTP"
        port                = "8080"
        path                = "/api/health"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 2
        unhealthy_threshold = 3
        matcher             = "200-299"
      }
    }
    
    # Database connections
    database = {
      name                 = "database-tg"
      port                 = 5432
      protocol             = "TCP"
      deregistration_delay = 300  # Longer for database connections
      
      instance_ids = [
        module.database_1.instance_id,
        module.database_2.instance_id
      ]
      
      health_check = {
        protocol            = "TCP"
        port                = "traffic-port"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }
  
  listeners = {
    # HTTP listener
    http = {
      port             = 80
      protocol         = "TCP"
      target_group_key = "http_api"
    }
    
    # HTTPS with TLS termination
    https = {
      port             = 443
      protocol         = "TLS"
      target_group_key = "https_api"
      certificate_arn  = module.acm_certificate.certificate_arn
      ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      alpn_policy      = "HTTP2Preferred"
    }
    
    # Database listener
    database = {
      port             = 5432
      protocol         = "TCP"
      target_group_key = "database"
    }
  }
  
  # Enable comprehensive logging
  access_logs_bucket = module.nlb_logs_bucket.bucket_id
  access_logs_prefix = "multi-protocol-nlb/"
  
  tags = {
    Environment = "production"
    Service     = "multi-protocol"
    Criticality = "high"
  }
}
```

## Input Variables

### Required Variables

| Name        | Description                         | Type           |
|-------------|-------------------------------------|----------------|
| `name`      | Name of the NLB                    | `string`       |
| `subnet_ids`| List of subnet IDs for the NLB     | `list(string)` |
| `vpc_id`    | VPC ID where the NLB will be placed| `string`       |

### Optional Variables

| Name                 | Description                              | Type           | Default |
|----------------------|------------------------------------------|----------------|---------|
| `internal`           | Whether NLB is internal or internet-facing | `bool`      | `false` |
| `cross_zone_enabled` | Enable cross-zone load balancing        | `bool`         | `true`  |
| `deletion_protection`| Enable deletion protection               | `bool`         | `false` |
| `security_groups`    | List of security group IDs               | `list(string)` | `[]`    |
| `access_logs_bucket` | S3 bucket name for access logs          | `string`       | `null`  |
| `access_logs_prefix` | S3 prefix for access logs               | `string`       | `""`    |
| `target_groups`      | Map of target group configurations      | `map(object)`  | `{}`    |
| `listeners`          | Map of listener configurations          | `map(object)`  | `{}`    |
| `tags`               | Tags to apply to all resources          | `map(string)`  | `{}`    |

### Target Groups Configuration

```hcl
target_groups = {
  "group_name" = {
    name                 = "target-group-name"        # Optional: defaults to "${var.name}-${key}"
    port                 = 80                         # Required: target port
    protocol             = "TCP"                      # Required: TCP, UDP, TCP_UDP, TLS
    target_port          = 8080                       # Optional: different port for targets
    instance_ids         = ["i-1234567890abcdef0"]    # Required: list of instance IDs
    deregistration_delay = 300                        # Optional: 0-3600 seconds (default: 300)
    preserve_client_ip   = true                       # Optional: preserve source IP (default: depends on target type)
    proxy_protocol_v2    = false                      # Optional: enable proxy protocol v2 (default: false)
    
    # Health check configuration
    health_check = {
      interval            = 30                        # Optional: 5-300 seconds (default: 30)
      path                = "/health"                 # Optional: for HTTP/HTTPS protocols
      port                = "traffic-port"            # Optional: port for health checks (default: traffic-port)
      protocol            = "HTTP"                    # Optional: TCP, HTTP, HTTPS (default: target group protocol)
      timeout             = 10                        # Optional: 2-120 seconds (default: 10 for HTTP/HTTPS, 6 for TCP)
      healthy_threshold   = 3                         # Optional: 2-10 (default: 3)
      unhealthy_threshold = 3                         # Optional: 2-10 (default: 3)
      matcher             = "200-299"                 # Optional: for HTTP/HTTPS protocols (default: "200-299")
    }
  }
}
```

### Listeners Configuration

```hcl
listeners = {
  "listener_name" = {
    port             = 80                             # Required: listener port
    protocol         = "TCP"                          # Required: TCP, UDP, TLS
    target_group_key = "group_name"                   # Required: key from target_groups map
    certificate_arn  = "arn:aws:acm:..."              # Optional: required for TLS protocol
    ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06" # Optional: SSL policy for TLS
    alpn_policy      = "HTTP2Preferred"               # Optional: ALPN policy for TLS
  }
}
```

## Outputs

| Name            | Description                        |
|-----------------|------------------------------------|
| `arn`           | ARN of the NLB                    |
| `dns_name`      | DNS name of the NLB                |
| `zone_id`       | Route 53 zone ID of the NLB       |
| `id`            | ID of the NLB                      |
| `target_groups` | Map of target groups created      |
| `listeners`     | Map of listeners created           |

### Output Usage Examples

```hcl
# Create Route53 record pointing to NLB
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"

  alias {
    name                   = module.web_nlb.dns_name
    zone_id                = module.web_nlb.zone_id
    evaluate_target_health = true
  }
}

# Use target group ARN in Auto Scaling Group
resource "aws_autoscaling_attachment" "web" {
  autoscaling_group_name = aws_autoscaling_group.web.id
  lb_target_group_arn    = module.web_nlb.target_groups["web"].arn
}

# Output for other modules
output "nlb_target_group_arn" {
  description = "Target group ARN for ECS service"
  value       = module.ecs_nlb.target_groups["ecs_app"].arn
}
```

## Protocol Support

### TCP
- **Use Cases**: Web servers, API services, database connections
- **Health Checks**: TCP, HTTP, HTTPS
- **Features**: Connection-based load balancing, low latency

### UDP
- **Use Cases**: DNS services, game servers, IoT applications
- **Health Checks**: TCP only (UDP doesn't support health checks directly)
- **Features**: Packet-based load balancing, stateless

### TLS
- **Use Cases**: HTTPS termination, secure TCP connections
- **Health Checks**: TCP, HTTP, HTTPS
- **Features**: SSL/TLS termination, certificate management

## Security Considerations

### Security Groups for NLB

```hcl
resource "aws_security_group" "nlb" {
  name_prefix = "nlb-sg-"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic on listener ports
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic to targets
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    Name = "nlb-security-group"
  }
}
```

### Target Security Groups

```hcl
resource "aws_security_group" "targets" {
  name_prefix = "nlb-targets-sg-"
  vpc_id      = module.vpc.vpc_id

  # Allow traffic from NLB subnets
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      for subnet in data.aws_subnet.nlb_subnets : subnet.cidr_block
    ]
  }

  # Health check port
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [
      for subnet in data.aws_subnet.nlb_subnets : subnet.cidr_block
    ]
  }

  tags = {
    Name = "nlb-targets-security-group"
  }
}
```

## Access Logs Configuration

```hcl
# S3 bucket for NLB access logs
module "nlb_logs_bucket" {
  source = "github.com/your-org/terraform-modules//aws/s3?ref=main"
  
  bucket_name = "nlb-access-logs-${random_id.suffix.hex}"
  
  # NLB access logs bucket policy
  bucket_policy = data.aws_iam_policy_document.nlb_logs.json
  
  lifecycle_rules = [
    {
      id     = "delete_old_logs"
      status = "Enabled"
      
      expiration = {
        days = 30
      }
    }
  ]
  
  tags = {
    Purpose = "nlb-access-logs"
  }
}

# Bucket policy for NLB access logs
data "aws_iam_policy_document" "nlb_logs" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
    
    actions = ["s3:PutObject"]
    
    resources = ["${module.nlb_logs_bucket.bucket_arn}/nlb-logs/*"]
  }
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    
    actions = ["s3:PutObject"]
    
    resources = ["${module.nlb_logs_bucket.bucket_arn}/nlb-logs/*"]
    
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

data "aws_elb_service_account" "current" {}
```

## Best Practices

### Performance Optimization
1. **Enable Cross-Zone Load Balancing**: Distributes traffic evenly across all AZs
2. **Use Appropriate Health Check Intervals**: Balance between responsiveness and resource usage
3. **Configure Deregistration Delay**: Shorter for containers, longer for persistent connections

### Security
1. **Use Internal NLBs**: For backend services that don't need internet access
2. **Enable Security Groups**: When you need fine-grained traffic control
3. **Preserve Client IP**: When application needs to know the original source IP

### Monitoring
1. **Enable Access Logs**: For compliance and troubleshooting
2. **Set Up CloudWatch Alarms**: Monitor target health and connection counts
3. **Use Proper Health Checks**: Choose the right protocol and endpoint

### Cost Optimization
1. **Right-Size Target Groups**: Don't over-provision instances
2. **Use Cross-Zone Load Balancing Carefully**: Consider data transfer costs
3. **Monitor Unused Resources**: Clean up unused target groups and listeners

## Troubleshooting

### Common Issues

1. **Targets Failing Health Checks**
   ```bash
   # Check target health
   aws elbv2 describe-target-health --target-group-arn <target-group-arn>
   
   # Verify security groups allow health check traffic
   # Check if health check port/path is accessible
   ```

2. **Connection Timeouts**
   ```bash
   # Check NLB security groups
   # Verify target security groups allow traffic from NLB subnets
   # Test connectivity from NLB subnets to targets
   ```

3. **SSL/TLS Issues**
   ```bash
   # Verify certificate is valid and not expired
   aws acm describe-certificate --certificate-arn <cert-arn>
   
   # Check SSL policy compatibility
   # Test TLS handshake
   ```

## Requirements

| Name        | Version   |
|-------------|-----------|
| terraform   | ~> 1.3    |
| aws         | ~> 5.97.0 |

## License

This module is released under the MIT License.