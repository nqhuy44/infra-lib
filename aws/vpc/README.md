# AWS VPC Module

This Terraform module creates a comprehensive AWS VPC (Virtual Private Cloud) with public and private subnets distributed across multiple availability zones. It includes Internet Gateway, configurable NAT Gateway deployment, and proper route table management for enterprise-grade networking.

## Features

- ✅ **Multi-AZ VPC** with configurable CIDR blocks
- ✅ **Public Subnets** with automatic public IP assignment
- ✅ **Private Subnets** with NAT Gateway routing
- ✅ **Internet Gateway** for public internet access
- ✅ **NAT Gateway** with single or multi-AZ deployment options
- ✅ **Route Tables** with automatic associations
- ✅ **DNS Support** enabled by default
- ✅ **Flexible Naming** with customizable prefixes
- ✅ **Resource Tagging** support

## Usage

### Basic Multi-AZ VPC

```hcl
module "vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"

  vpc_name             = "production-vpc"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Public subnets (for load balancers, bastion hosts)
  public_subnet_cidrs  = [
    "10.0.1.0/24",   # us-east-1a
    "10.0.2.0/24",   # us-east-1b
    "10.0.3.0/24"    # us-east-1c
  ]
  
  # Private subnets (for application servers, databases)
  private_subnet_cidrs = [
    "10.0.10.0/24",  # us-east-1a
    "10.0.11.0/24",  # us-east-1b
    "10.0.12.0/24"   # us-east-1c
  ]

  # High availability: one NAT Gateway per AZ
  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Environment = "production"
    Project     = "web-app"
    Team        = "platform"
  }
}
```

### Cost-Optimized VPC with Single NAT Gateway

```hcl
module "staging_vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"

  vpc_name             = "staging-vpc"
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]

  # Cost optimization: single NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true

  # Custom naming
  public_subnet_name_prefix  = "staging-public"
  private_subnet_name_prefix = "staging-private"
  internet_gateway_name      = "staging-igw"

  tags = {
    Environment = "staging"
    CostCenter  = "development"
  }
}
```

### Development VPC without NAT Gateway

```hcl
module "dev_vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"

  vpc_name             = "development-vpc"
  vpc_cidr             = "10.2.0.0/16"
  availability_zones   = ["us-east-1a"]
  
  public_subnet_cidrs  = ["10.2.1.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24"]

  # No NAT Gateway for development to save costs
  enable_nat_gateway = false

  tags = {
    Environment = "development"
    AutoShutdown = "enabled"
  }
}
```

### Enterprise VPC with Database Subnets

```hcl
module "enterprise_vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"

  vpc_name             = "enterprise-vpc"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Public subnets for load balancers
  public_subnet_cidrs = [
    "10.0.1.0/24",   # Public 1A
    "10.0.2.0/24",   # Public 1B
    "10.0.3.0/24"    # Public 1C
  ]
  
  # Private subnets for application tier
  private_subnet_cidrs = [
    "10.0.10.0/24",  # App 1A
    "10.0.11.0/24",  # App 1B
    "10.0.12.0/24"   # App 1C
  ]

  # Production-grade: NAT Gateway per AZ
  enable_nat_gateway = true
  single_nat_gateway = false

  # Custom naming for enterprise standards
  public_subnet_name_prefix     = "enterprise-public"
  private_subnet_name_prefix    = "enterprise-app"
  public_route_table_name       = "enterprise-public-rt"
  private_route_table_name_prefix = "enterprise-app-rt"
  nat_gateway_name_prefix       = "enterprise-nat"
  elastic_ip_name_prefix        = "enterprise-eip"

  tags = {
    Environment   = "production"
    Compliance    = "required"
    Backup        = "daily"
    Monitoring    = "enhanced"
    Project       = "enterprise-app"
    Team          = "platform-engineering"
    CostCenter    = "infrastructure"
  }
}

# Additional database subnets for RDS
resource "aws_subnet" "database" {
  count             = length(var.availability_zones)
  vpc_id            = module.enterprise_vpc.vpc_id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = "10.0.${20 + count.index}.0/24"

  tags = merge(var.tags, {
    Name = "enterprise-database-${var.availability_zones[count.index]}"
    Tier = "database"
  })
}

# Database subnet group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "enterprise-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "enterprise-database-subnet-group"
  }
}
```

### Multi-Environment VPC Setup

```hcl
# Local values for environment-specific configurations
locals {
  environments = {
    prod = {
      vpc_cidr             = "10.0.0.0/16"
      public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
      availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
      enable_nat_gateway   = true
      single_nat_gateway   = false
    }
    staging = {
      vpc_cidr             = "10.1.0.0/16"
      public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
      private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
      availability_zones   = ["us-east-1a", "us-east-1b"]
      enable_nat_gateway   = true
      single_nat_gateway   = true
    }
    dev = {
      vpc_cidr             = "10.2.0.0/16"
      public_subnet_cidrs  = ["10.2.1.0/24"]
      private_subnet_cidrs = ["10.2.10.0/24"]
      availability_zones   = ["us-east-1a"]
      enable_nat_gateway   = false
      single_nat_gateway   = false
    }
  }
}

# Create VPC for each environment
module "vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"
  
  for_each = local.environments

  vpc_name             = "${each.key}-vpc"
  vpc_cidr             = each.value.vpc_cidr
  availability_zones   = each.value.availability_zones
  public_subnet_cidrs  = each.value.public_subnet_cidrs
  private_subnet_cidrs = each.value.private_subnet_cidrs
  enable_nat_gateway   = each.value.enable_nat_gateway
  single_nat_gateway   = each.value.single_nat_gateway

  # Environment-specific naming
  public_subnet_name_prefix  = "${each.key}-public"
  private_subnet_name_prefix = "${each.key}-private"
  internet_gateway_name      = "${each.key}-igw"

  tags = {
    Environment = each.key
    ManagedBy   = "terraform"
    Project     = "multi-env-infrastructure"
  }
}
```

## Input Variables

### Required Variables

| Name                 | Description                               | Type           | Example                                        |
|----------------------|-------------------------------------------|----------------|------------------------------------------------|
| `vpc_cidr`           | The CIDR block for the VPC                | `string`       | `"10.0.0.0/16"`                               |
| `availability_zones` | List of availability zones to use         | `list(string)` | `["us-east-1a", "us-east-1b", "us-east-1c"]` |
| `public_subnet_cidrs` | List of CIDR blocks for public subnets  | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]`             |
| `private_subnet_cidrs` | List of CIDR blocks for private subnets | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]`           |

### Optional Variables

| Name                            | Description                                    | Type          | Default                      |
|---------------------------------|------------------------------------------------|---------------|------------------------------|
| `vpc_name`                      | The name tag for the VPC                      | `string`      | `"main-vpc"`                 |
| `enable_nat_gateway`            | Set to true to create NAT Gateways            | `bool`        | `true`                       |
| `single_nat_gateway`            | Create single NAT Gateway vs one per AZ       | `bool`        | `false`                      |
| `public_subnet_name_prefix`     | Prefix for the Name tag of public subnets     | `string`      | `"public-subnet"`            |
| `private_subnet_name_prefix`    | Prefix for the Name tag of private subnets    | `string`      | `"private-subnet"`           |
| `public_route_table_name`       | The name tag for the public route table       | `string`      | `"public-route-table"`       |
| `private_route_table_name_prefix` | Prefix for private route table names        | `string`      | `"private-rt"`               |
| `internet_gateway_name`         | The name tag for the Internet Gateway         | `string`      | `"main-internet-gateway"`    |
| `nat_gateway_name_prefix`       | Prefix for the Name tag of NAT Gateways       | `string`      | `"nat-gw"`                   |
| `elastic_ip_name_prefix`        | Prefix for Elastic IP names for NAT Gateways  | `string`      | `"nat-eip"`                  |
| `tags`                          | A map of tags to assign to all resources      | `map(string)` | `{}`                         |

### Variable Details

#### CIDR Block Planning
```hcl
# Example CIDR planning for different environments
locals {
  cidr_blocks = {
    production  = "10.0.0.0/16"   # 65,536 IPs
    staging     = "10.1.0.0/16"   # 65,536 IPs  
    development = "10.2.0.0/16"   # 65,536 IPs
    shared      = "10.3.0.0/16"   # 65,536 IPs
  }
  
  # Subnet calculations
  public_subnets = {
    production = [
      "10.0.1.0/24",   # 256 IPs per AZ
      "10.0.2.0/24",
      "10.0.3.0/24"
    ]
  }
}
```

#### NAT Gateway Options
- **`single_nat_gateway = false`**: Creates one NAT Gateway per AZ (recommended for production)
- **`single_nat_gateway = true`**: Creates one NAT Gateway in the first AZ (cost optimization)
- **`enable_nat_gateway = false`**: No NAT Gateways created (development environments)

## Outputs

| Name                      | Description                                           | Type           |
|---------------------------|-------------------------------------------------------|----------------|
| `vpc_id`                  | The ID of the VPC                                     | `string`       |
| `vpc_cidr`                | The CIDR block of the VPC                             | `string`       |
| `public_subnet_ids`       | List of IDs of the public subnets                     | `list(string)` |
| `public_subnet_cidrs`     | List of CIDR blocks for the public subnets           | `list(string)` |
| `private_subnet_ids`      | List of IDs of the private subnets                    | `list(string)` |
| `private_subnet_cidrs`    | List of CIDR blocks for the private subnets          | `list(string)` |
| `public_route_table_id`   | The ID of the public route table                      | `string`       |
| `private_route_table_ids` | List of IDs of the private route tables               | `list(string)` |
| `internet_gateway_id`     | The ID of the Internet Gateway                        | `string`       |
| `nat_gateway_ids`         | List of IDs of the NAT Gateways                       | `list(string)` |
| `nat_gateway_public_ips`  | List of public Elastic IPs assigned to NAT Gateways   | `list(string)` |
| `nat_eip_ids`             | List of Allocation IDs of Elastic IPs for NAT Gateways | `list(string)` |

### Output Usage Examples

```hcl
# Use VPC outputs in other modules
module "security_groups" {
  source = "../security-groups"
  
  vpc_id = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
}

module "rds" {
  source = "../rds"
  
  subnet_ids = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.security_groups.database_sg_id]
}

module "alb" {
  source = "../alb"
  
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id     = module.vpc.vpc_id
}

# Output NAT Gateway IPs for whitelist purposes
output "nat_gateway_ips" {
  description = "NAT Gateway public IPs for external service whitelisting"
  value       = module.vpc.nat_gateway_public_ips
}

# Create data source for AZ mapping
data "aws_availability_zones" "available" {
  state = "available"
}

# Output subnet mapping for reference
output "subnet_mapping" {
  description = "Mapping of subnets to availability zones"
  value = {
    public_subnets = zipmap(
      data.aws_availability_zones.available.names,
      module.vpc.public_subnet_ids
    )
    private_subnets = zipmap(
      data.aws_availability_zones.available.names,
      module.vpc.private_subnet_ids
    )
  }
}
```

## Architecture Patterns

### 3-Tier Architecture

```hcl
module "three_tier_vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"

  vpc_name             = "three-tier-vpc"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Web tier (public subnets)
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24", 
    "10.0.3.0/24"
  ]
  
  # Application tier (private subnets)
  private_subnet_cidrs = [
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
  
  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Architecture = "three-tier"
    Environment  = "production"
  }
}

# Database tier (additional private subnets)
resource "aws_subnet" "database" {
  count             = length(var.availability_zones)
  vpc_id            = module.three_tier_vpc.vpc_id
  cidr_block        = "10.0.${20 + count.index}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "database-subnet-${var.availability_zones[count.index]}"
    Tier = "database"
  }
}
```

### Hub and Spoke Network

```hcl
# Hub VPC (shared services)
module "hub_vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"

  vpc_name             = "hub-vpc"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Role = "hub"
    Environment = "shared"
  }
}

# Spoke VPCs (workload-specific)
module "spoke_vpcs" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"
  
  for_each = {
    app1 = "10.1.0.0/16"
    app2 = "10.2.0.0/16"
    app3 = "10.3.0.0/16"
  }

  vpc_name             = "${each.key}-vpc"
  vpc_cidr             = each.value
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = [
    cidrsubnet(each.value, 8, 1),
    cidrsubnet(each.value, 8, 2)
  ]
  private_subnet_cidrs = [
    cidrsubnet(each.value, 8, 10),
    cidrsubnet(each.value, 8, 11)
  ]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for spokes

  tags = {
    Role = "spoke"
    Application = each.key
  }
}
```

## Best Practices

### 1. CIDR Planning
```hcl
# Reserve address space for future growth
locals {
  # Use /16 for VPC, /24 for subnets
  vpc_cidrs = {
    prod    = "10.0.0.0/16"    # 65,536 addresses
    staging = "10.1.0.0/16"    # 65,536 addresses
    dev     = "10.2.0.0/16"    # 65,536 addresses
  }
  
  # Plan subnet allocation
  # x.x.1-10.x    = Public subnets
  # x.x.11-50.x   = Private/App subnets  
  # x.x.51-100.x  = Database subnets
  # x.x.101-200.x = Reserved for future use
}
```

### 2. Multi-AZ Deployment
```hcl
# Use at least 2 AZs for high availability
# Use 3+ AZs for critical production workloads
availability_zones = [
  "us-east-1a",
  "us-east-1b", 
  "us-east-1c"  # Third AZ for enhanced availability
]
```

### 3. Cost Optimization
```hcl
# Development: No NAT Gateway
enable_nat_gateway = false

# Staging: Single NAT Gateway
enable_nat_gateway = true
single_nat_gateway = true

# Production: Multi-AZ NAT Gateways
enable_nat_gateway = true
single_nat_gateway = false
```

### 4. Resource Tagging
```hcl
tags = {
  Environment   = "production"
  Project       = "web-application"
  Team          = "platform-engineering"
  CostCenter    = "engineering"
  Compliance    = "required"
  Backup        = "daily"
  Monitoring    = "enhanced"
  CreatedBy     = "terraform"
  Repository    = "infrastructure-modules"
}
```

## Security Considerations

### Network ACLs
```hcl
# Default Network ACL allows all traffic
# Create custom NACLs for additional security
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Allow inbound from VPC
  ingress {
    rule_no    = 100
    protocol   = "-1"
    cidr_block = module.vpc.vpc_cidr
    from_port  = 0
    to_port    = 0
    action     = "allow"
  }

  # Allow outbound to internet
  egress {
    rule_no    = 100
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    action     = "allow"
  }

  tags = {
    Name = "private-nacl"
  }
}
```

### VPC Flow Logs
```hcl
# Enable VPC Flow Logs for monitoring
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id

  tags = {
    Name = "vpc-flow-logs"
  }
}
```

## Monitoring and Troubleshooting

### VPC Metrics
```hcl
# CloudWatch alarms for NAT Gateway
resource "aws_cloudwatch_metric_alarm" "nat_gateway_packets" {
  for_each = toset(module.vpc.nat_gateway_ids)
  
  alarm_name          = "nat-gateway-high-packet-drop-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PacketDropCount"
  namespace           = "AWS/NATGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "This metric monitors NAT gateway packet drops"
  
  dimensions = {
    NatGatewayId = each.key
  }
}
```

### Common Issues
1. **No internet access from private subnets**: Check NAT Gateway configuration
2. **DNS resolution issues**: Ensure `enable_dns_support` and `enable_dns_hostnames` are true
3. **Cross-AZ traffic costs**: Consider subnet placement for your applications

## Cost Optimization

### NAT Gateway Costs
- **Production**: Multi-AZ NAT Gateways (~$45/month per NAT Gateway + data transfer)
- **Staging**: Single NAT Gateway (~$45/month + data transfer) 
- **Development**: No NAT Gateway (use NAT instances or no outbound internet)

### Data Transfer Optimization
```hcl
# Use VPC endpoints to avoid NAT Gateway data transfer costs
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.us-east-1.s3"
  
  route_table_ids = module.vpc.private_route_table_ids
  
  tags = {
    Name = "s3-endpoint"
  }
}
```

## Requirements

| Name        | Version   |
|-------------|-----------|
| terraform   | ~> 1.3    |
| aws         | ~> 5.97.0 |

## License

This module is released under the MIT License.