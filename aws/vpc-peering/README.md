# AWS VPC Peering Module

This Terraform module creates and manages AWS VPC Peering connections between two VPCs, automatically configuring route table entries to enable bidirectional communication. It supports same-region and cross-region peering with DNS resolution capabilities.

## Features

- ✅ **Same-Region VPC Peering** - Connect VPCs within the same AWS region
- ✅ **Cross-Region VPC Peering** - Connect VPCs across different AWS regions
- ✅ **Automatic Route Management** - Creates routes in specified route tables
- ✅ **DNS Resolution** - Optional DNS hostname resolution between VPCs
- ✅ **Auto-Accept** - Automatically accept peering connection requests
- ✅ **Flexible Routing** - Support for multiple route tables per VPC
- ✅ **Resource Tagging** - Comprehensive tagging support

## Usage

### Basic Same-Region VPC Peering

```hcl
module "vpc_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"

  name = "production-to-staging-peering"
  
  # VPC Configuration
  requester_vpc_id   = module.production_vpc.vpc_id
  accepter_vpc_id    = module.staging_vpc.vpc_id
  requester_vpc_cidr = module.production_vpc.vpc_cidr_block
  accepter_vpc_cidr  = module.staging_vpc.vpc_cidr_block
  
  # Route Table Configuration
  requester_route_table_ids = concat(
    module.production_vpc.private_route_table_ids,
    [module.production_vpc.public_route_table_id]
  )
  
  accepter_route_table_ids = concat(
    module.staging_vpc.private_route_table_ids,
    [module.staging_vpc.public_route_table_id]
  )
  
  # Enable DNS resolution between VPCs
  enable_dns_resolution = true
  
  # Automatically accept the peering connection
  auto_accept = true
  
  tags = {
    Environment = "multi-env"
    Purpose     = "inter-vpc-communication"
    Team        = "platform"
  }
}
```

### Cross-Region VPC Peering

```hcl
module "cross_region_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"

  name = "us-east-to-us-west-peering"
  
  # Cross-region configuration
  requester_vpc_id   = module.us_east_vpc.vpc_id
  accepter_vpc_id    = module.us_west_vpc.vpc_id
  requester_vpc_cidr = "10.0.0.0/16"
  accepter_vpc_cidr  = "10.1.0.0/16"
  peer_region        = "us-west-2"  # Region of accepter VPC
  
  # Route tables in both regions
  requester_route_table_ids = concat(
    module.us_east_vpc.private_route_table_ids,
    [module.us_east_vpc.public_route_table_id]
  )
  
  accepter_route_table_ids = concat(
    module.us_west_vpc.private_route_table_ids,
    [module.us_west_vpc.public_route_table_id]
  )
  
  # Enable DNS resolution for cross-region
  enable_dns_resolution = true
  auto_accept = true
  
  tags = {
    Environment = "production"
    Purpose     = "disaster-recovery"
    Region      = "multi-region"
  }
}
```

### Hub-and-Spoke VPC Peering Architecture

```hcl
# Central hub VPC
module "hub_vpc" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"
  
  name = "hub-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = true
  
  tags = {
    Environment = "shared"
    Type        = "hub"
  }
}

# Spoke VPCs
locals {
  spoke_vpcs = {
    production = {
      cidr = "10.1.0.0/16"
      name = "production-vpc"
    }
    staging = {
      cidr = "10.2.0.0/16"
      name = "staging-vpc"
    }
    development = {
      cidr = "10.3.0.0/16"
      name = "development-vpc"
    }
  }
}

# Create spoke VPCs
module "spoke_vpcs" {
  source = "github.com/your-org/terraform-modules//aws/vpc?ref=main"
  
  for_each = local.spoke_vpcs
  
  name = each.value.name
  cidr = each.value.cidr
  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = [
    cidrsubnet(each.value.cidr, 8, 1),
    cidrsubnet(each.value.cidr, 8, 2)
  ]
  public_subnets = [
    cidrsubnet(each.value.cidr, 8, 101),
    cidrsubnet(each.value.cidr, 8, 102)
  ]
  
  enable_nat_gateway = true
  
  tags = {
    Environment = each.key
    Type        = "spoke"
  }
}

# Hub-to-spoke peering connections
module "hub_to_spoke_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"
  
  for_each = local.spoke_vpcs
  
  name = "hub-to-${each.key}-peering"
  
  # Hub as requester, spoke as accepter
  requester_vpc_id   = module.hub_vpc.vpc_id
  accepter_vpc_id    = module.spoke_vpcs[each.key].vpc_id
  requester_vpc_cidr = module.hub_vpc.vpc_cidr_block
  accepter_vpc_cidr  = each.value.cidr
  
  # Add routes in hub VPC to all spoke VPCs
  requester_route_table_ids = concat(
    module.hub_vpc.private_route_table_ids,
    [module.hub_vpc.public_route_table_id]
  )
  
  # Add routes in spoke VPC only to hub
  accepter_route_table_ids = concat(
    module.spoke_vpcs[each.key].private_route_table_ids,
    [module.spoke_vpcs[each.key].public_route_table_id]
  )
  
  enable_dns_resolution = true
  auto_accept = true
  
  tags = {
    Environment = each.key
    Architecture = "hub-and-spoke"
    Hub         = "shared"
    Spoke       = each.key
  }
}
```

### Conditional VPC Peering for Multi-Environment

```hcl
# Variables for environment configuration
variable "enable_peering" {
  description = "Map of peering connections to enable"
  type = map(bool)
  default = {
    prod_to_staging = true
    prod_to_dev     = false
    staging_to_dev  = true
  }
}

# Conditional peering: Production to Staging
module "prod_to_staging_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"
  
  count = var.enable_peering.prod_to_staging ? 1 : 0
  
  name = "production-to-staging-peering"
  
  requester_vpc_id   = module.production_vpc.vpc_id
  accepter_vpc_id    = module.staging_vpc.vpc_id
  requester_vpc_cidr = module.production_vpc.vpc_cidr_block
  accepter_vpc_cidr  = module.staging_vpc.vpc_cidr_block
  
  # Only peer private subnets for security
  requester_route_table_ids = module.production_vpc.private_route_table_ids
  accepter_route_table_ids  = module.staging_vpc.private_route_table_ids
  
  enable_dns_resolution = true
  auto_accept = true
  
  tags = {
    Environment = "prod-staging"
    Purpose     = "data-sync"
  }
}

# Conditional peering: Staging to Development
module "staging_to_dev_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"
  
  count = var.enable_peering.staging_to_dev ? 1 : 0
  
  name = "staging-to-development-peering"
  
  requester_vpc_id   = module.staging_vpc.vpc_id
  accepter_vpc_id    = module.development_vpc.vpc_id
  requester_vpc_cidr = module.staging_vpc.vpc_cidr_block
  accepter_vpc_cidr  = module.development_vpc.vpc_cidr_block
  
  requester_route_table_ids = module.staging_vpc.private_route_table_ids
  accepter_route_table_ids  = module.development_vpc.private_route_table_ids
  
  enable_dns_resolution = true
  auto_accept = true
  
  tags = {
    Environment = "staging-dev"
    Purpose     = "testing"
  }
}
```

### Manual Acceptance Cross-Account Peering

```hcl
# For cross-account peering where auto-accept is not possible
module "cross_account_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"

  name = "account-a-to-account-b-peering"
  
  requester_vpc_id   = module.account_a_vpc.vpc_id
  accepter_vpc_id    = "vpc-xxxxxxxxx"  # VPC ID in different account
  requester_vpc_cidr = "10.0.0.0/16"
  accepter_vpc_cidr  = "10.10.0.0/16"
  
  # Manual acceptance required for cross-account
  auto_accept = false
  
  # Only configure routes on requester side initially
  requester_route_table_ids = module.account_a_vpc.private_route_table_ids
  accepter_route_table_ids  = []  # Configure on accepter side separately
  
  enable_dns_resolution = false  # May need manual configuration
  
  tags = {
    Environment = "production"
    Type        = "cross-account"
    RequiresManualAcceptance = "true"
  }
}

# Output connection ID for manual acceptance
output "cross_account_peering_id" {
  description = "VPC Peering Connection ID for manual acceptance"
  value       = module.cross_account_peering.vpc_peering_connection_id
}
```

### VPC Peering with Security Groups

```hcl
# Create VPC Peering
module "secure_vpc_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"

  name = "secure-app-peering"
  
  requester_vpc_id   = module.app_vpc.vpc_id
  accepter_vpc_id    = module.db_vpc.vpc_id
  requester_vpc_cidr = module.app_vpc.vpc_cidr_block
  accepter_vpc_cidr  = module.db_vpc.vpc_cidr_block
  
  requester_route_table_ids = module.app_vpc.private_route_table_ids
  accepter_route_table_ids  = module.db_vpc.private_route_table_ids
  
  enable_dns_resolution = true
  auto_accept = true
  
  tags = {
    Environment = "production"
    Purpose     = "app-to-database"
    Security    = "restricted"
  }
}

# Security group allowing traffic from app VPC to database VPC
resource "aws_security_group" "database_access_from_app" {
  name_prefix = "db-access-from-app-"
  vpc_id      = module.db_vpc.vpc_id
  description = "Allow database access from application VPC"

  # MySQL/Aurora access from app VPC
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.app_vpc.vpc_cidr_block]
    description = "MySQL access from app VPC"
  }
  
  # PostgreSQL access from app VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.app_vpc.vpc_cidr_block]
    description = "PostgreSQL access from app VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "database-access-from-app"
    Environment = "production"
    Purpose     = "vpc-peering-security"
  }
  
  depends_on = [module.secure_vpc_peering]
}
```

## Input Variables

### Required Variables

| Name                    | Description                          | Type     |
|-------------------------|--------------------------------------|----------|
| `name`                  | Name of the VPC peering connection   | `string` |
| `requester_vpc_id`      | ID of the requester VPC              | `string` |
| `accepter_vpc_id`       | ID of the accepter VPC               | `string` |
| `requester_vpc_cidr`    | CIDR block of the requester VPC     | `string` |
| `accepter_vpc_cidr`     | CIDR block of the accepter VPC      | `string` |

### Optional Variables

| Name                        | Description                                            | Type           | Default |
|-----------------------------|--------------------------------------------------------|----------------|---------|
| `peer_region`               | Region of the accepter VPC (for cross-region peering) | `string`       | `null`  |
| `auto_accept`               | Automatically accept the peering connection request   | `bool`         | `true`  |
| `requester_route_table_ids` | Route table IDs in requester VPC for route creation   | `list(string)` | `[]`    |
| `accepter_route_table_ids`  | Route table IDs in accepter VPC for route creation    | `list(string)` | `[]`    |
| `enable_dns_resolution`     | Enable DNS resolution between VPCs                    | `bool`         | `false` |
| `tags`                      | Tags to apply to the peering connection               | `map(string)`  | `{}`    |

### Variable Details

#### `peer_region`
- **Required for cross-region peering**
- Must be a valid AWS region code (e.g., `us-west-2`, `eu-west-1`)
- Leave as `null` for same-region peering

#### `auto_accept`
- **Cannot be `true` for cross-account peering**
- Set to `false` when the accepter VPC is in a different AWS account
- Manual acceptance required in the accepter account

#### Route Table IDs
```hcl
# Example of getting route table IDs from VPC module
requester_route_table_ids = concat(
  module.vpc.private_route_table_ids,    # All private route tables
  [module.vpc.public_route_table_id],    # Public route table
  module.vpc.database_route_table_ids    # Database route tables (if any)
)
```

#### `enable_dns_resolution`
- Enables DNS hostname resolution between VPCs
- Allows resolving private DNS names across the peering connection
- Useful for applications that rely on DNS names rather than IP addresses

## Outputs

| Name                          | Description                                      | Type   |
|-------------------------------|--------------------------------------------------|--------|
| `vpc_peering_connection_id`   | The ID of the VPC Peering Connection             | `string` |
| `vpc_peering_connection_status` | The status of the VPC Peering Connection       | `string` |
| `requester_routes`            | Route objects created in the requester VPC      | `map`    |
| `accepter_routes`             | Route objects created in the accepter VPC       | `map`    |

### Output Usage Examples

```hcl
# Use peering connection ID for dependencies
resource "aws_security_group_rule" "allow_peered_vpc" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = [var.accepter_vpc_cidr]
  security_group_id        = aws_security_group.app.id
  
  # Ensure peering is established before creating rule
  depends_on = [module.vpc_peering.vpc_peering_connection_id]
}

# Output connection status for monitoring
output "peering_status" {
  description = "Status of all VPC peering connections"
  value = {
    prod_staging = module.prod_to_staging_peering.vpc_peering_connection_status
    staging_dev  = module.staging_to_dev_peering.vpc_peering_connection_status
  }
}
```

## Best Practices

### 1. CIDR Block Planning
```hcl
# Avoid overlapping CIDR blocks
locals {
  vpc_cidrs = {
    production  = "10.0.0.0/16"   # 10.0.0.0 - 10.0.255.255
    staging     = "10.1.0.0/16"   # 10.1.0.0 - 10.1.255.255
    development = "10.2.0.0/16"   # 10.2.0.0 - 10.2.255.255
    shared      = "10.3.0.0/16"   # 10.3.0.0 - 10.3.255.255
  }
}
```

### 2. Security Group Configuration
```hcl
# Create specific security groups for peered VPC access
resource "aws_security_group" "cross_vpc_access" {
  name_prefix = "cross-vpc-access-"
  vpc_id      = var.vpc_id
  description = "Allow access from peered VPC"

  # Only allow specific ports and protocols
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.peered_vpc_cidr]
    description = "HTTPS from peered VPC"
  }
  
  # Avoid allowing all traffic (0.0.0.0/0)
  # Be specific about what traffic is allowed
}
```

### 3. Route Table Management
```hcl
# Be selective about which route tables get peering routes
module "selective_peering" {
  source = "github.com/your-org/terraform-modules//aws/vpc-peering?ref=main"
  
  # ... other configuration
  
  # Only add routes to private subnets for security
  requester_route_table_ids = module.production_vpc.private_route_table_ids
  accepter_route_table_ids  = module.staging_vpc.private_route_table_ids
  
  # Exclude public route tables to prevent unintended internet routing
}
```

### 4. Monitoring and Alerting
```hcl
# CloudWatch alarm for peering connection status
resource "aws_cloudwatch_metric_alarm" "peering_status" {
  alarm_name          = "vpc-peering-connection-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PeeringConnectionActive"
  namespace           = "AWS/VPC"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "This metric monitors VPC peering connection status"
  
  dimensions = {
    PeeringConnectionId = module.vpc_peering.vpc_peering_connection_id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Peering Connection Stuck in "pending-acceptance"
```bash
# Check if auto_accept is set correctly
# For cross-account peering, manual acceptance is required
aws ec2 accept-vpc-peering-connection \
    --vpc-peering-connection-id pcx-xxxxxxxxx
```

#### 2. DNS Resolution Not Working
```hcl
# Ensure enable_dns_resolution is set to true
# Check VPC DNS settings
module "vpc_peering" {
  # ... other configuration
  enable_dns_resolution = true
}

# Verify VPC DNS support is enabled
resource "aws_vpc_dhcp_options" "main" {
  domain_name_servers = ["AmazonProvidedDNS"]
  domain_name         = "ec2.internal"
}
```

#### 3. Route Propagation Issues
```bash
# Check route tables for proper peering routes
aws ec2 describe-route-tables --route-table-ids rtb-xxxxxxxxx

# Verify routes are pointing to peering connection
aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids pcx-xxxxxxxxx
```

#### 4. Cross-Region Peering Limitations
```hcl
# Cross-region peering has limitations:
# - No IPv6 support
# - No support for jumbo frames
# - DNS resolution might need manual configuration

module "cross_region_peering" {
  # ... configuration
  
  # May need to disable DNS resolution for cross-region
  enable_dns_resolution = false  
}
```

## Cost Considerations

### Data Transfer Costs
- **Same-Region**: No data transfer charges between peered VPCs
- **Cross-Region**: Standard cross-region data transfer rates apply
- **Cross-AZ**: Standard cross-AZ data transfer charges apply

### Cost Optimization Tips
```hcl
# Use cross-region peering strategically
# Consider VPC endpoints for AWS services instead of peering

# Monitor data transfer usage
resource "aws_cloudwatch_metric_alarm" "data_transfer" {
  alarm_name          = "high-cross-region-data-transfer"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkPacketsOut"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000000"  # 1M packets
  alarm_description   = "High cross-region data transfer detected"
}
```

## Security Considerations

### 1. Least Privilege Access
```hcl
# Only peer necessary subnets
# Use security groups to control traffic
# Monitor and log VPC flow logs

resource "aws_flow_log" "peering_logs" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_logs.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
  
  tags = {
    Name = "vpc-peering-flow-logs"
  }
}
```

### 2. Network Segmentation
```hcl
# Use separate route tables for different tiers
# Database subnets should have minimal peering routes
# Public subnets should avoid unnecessary peering
```

## Requirements

| Name       | Version   |
|------------|-----------|
| terraform  | ~> 1.3    |
| aws        | ~> 5.97.0 |

## License

This module is released under the MIT License.