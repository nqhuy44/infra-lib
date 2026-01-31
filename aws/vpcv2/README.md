# AWS VPC v2 Module

A flexible Terraform module for creating AWS VPC with complete control over subnets, routing, and NAT gateways. Unlike traditional VPC modules, this module doesn't impose any default subnet structure - you define exactly what you need.

## Features

- ✅ **Zero Default Subnets** - Only creates what you explicitly define
- ✅ **Complete Flexibility** - Define any subnet configuration (public, private, isolated)
- ✅ **Custom Routing** - Full control over route tables and associations
- ✅ **Mixed NAT Strategies** - Single, multi-AZ, or selective NAT gateway placement
- ✅ **Isolated Subnets** - Create subnets with no internet access
- ✅ **Custom Routes** - Support for VPC peering, VPN, Transit Gateway, etc.
- ✅ **Granular Control** - Every aspect is configurable

## Architecture Patterns Supported

- Single AZ or Multi-AZ deployments
- Cost-optimized (single NAT) or HA (multi-NAT) configurations
- DMZ, application, and database tier separation
- Complex routing scenarios with custom gateways

## Usage

### Basic Example: Single AZ with Mixed Routing

```terraform
module "vpc" {
  source = "./vpcv2"

  vpc_cidr           = "10.0.0.0/16"
  vpc_name          = "my-app-vpc"
  availability_zones = ["us-east-1a"]

  # Define 5 custom subnets
  subnets = {
    # 2 subnets that use Internet Gateway (public)
    "web-public" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      type             = "public"
    }
    "alb-public" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1a"
      type             = "public"
    }
    
    # 3 subnets that use NAT Gateway (private)
    "app-private" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "us-east-1a"
      type             = "private"
    }
    "worker-private" = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-east-1a"
      type             = "private"
    }
    "cache-private" = {
      cidr_block        = "10.0.12.0/24"
      availability_zone = "us-east-1a"
      type             = "private"
    }
  }

  # Single NAT gateway in the first public subnet
  nat_gateways = {
    "main-nat" = {
      availability_zone = "us-east-1a"
      public_subnet_key = "web-public"
    }
  }

  # Define route tables
  route_tables = {
    # Route table for public subnets (uses Internet Gateway)
    "public-rt" = {
      type = "public"
    }
    
    # Route table for private subnets (uses NAT Gateway)
    "private-rt" = {
      type            = "private"
      nat_gateway_key = "main-nat"
    }
  }

  # Associate subnets with route tables
  subnet_route_table_associations = {
    # 2 subnets use Internet Gateway
    "web-public" = "public-rt"
    "alb-public" = "public-rt"
    
    # 3 subnets use NAT Gateway
    "app-private"    = "private-rt"
    "worker-private" = "private-rt"
    "cache-private"  = "private-rt"
  }

  tags = {
    Environment = "production"
    Architecture = "single-az"
  }
}
```

### Multi-AZ Example with High Availability

```terraform
module "vpc" {
  source = "./vpcv2"

  vpc_cidr           = "10.0.0.0/16"
  vpc_name          = "ha-vpc"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  subnets = {
    # Public subnets across 3 AZs
    "web-public-1a" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      type             = "public"
    }
    "web-public-1b" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
      type             = "public"
    }
    "web-public-1c" = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1c"
      type             = "public"
    }
    
    # Private subnets across 3 AZs
    "app-private-1a" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "us-east-1a"
      type             = "private"
    }
    "app-private-1b" = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-east-1b"
      type             = "private"
    }
    "app-private-1c" = {
      cidr_block        = "10.0.12.0/24"
      availability_zone = "us-east-1c"
      type             = "private"
    }
    
    # Isolated database subnets
    "db-isolated-1a" = {
      cidr_block        = "10.0.20.0/24"
      availability_zone = "us-east-1a"
      type             = "isolated"
    }
    "db-isolated-1b" = {
      cidr_block        = "10.0.21.0/24"
      availability_zone = "us-east-1b"
      type             = "isolated"
    }
    "db-isolated-1c" = {
      cidr_block        = "10.0.22.0/24"
      availability_zone = "us-east-1c"
      type             = "isolated"
    }
  }

  # NAT gateways in each AZ for high availability
  nat_gateways = {
    "nat-1a" = {
      availability_zone = "us-east-1a"
      public_subnet_key = "web-public-1a"
    }
    "nat-1b" = {
      availability_zone = "us-east-1b"
      public_subnet_key = "web-public-1b"
    }
    "nat-1c" = {
      availability_zone = "us-east-1c"
      public_subnet_key = "web-public-1c"
    }
  }

  route_tables = {
    "public-rt" = {
      type = "public"
    }
    "private-rt-1a" = {
      type            = "private"
      nat_gateway_key = "nat-1a"
    }
    "private-rt-1b" = {
      type            = "private"
      nat_gateway_key = "nat-1b"
    }
    "private-rt-1c" = {
      type            = "private"
      nat_gateway_key = "nat-1c"
    }
    "isolated-rt" = {
      type = "isolated"
    }
  }

  subnet_route_table_associations = {
    # Public subnets
    "web-public-1a" = "public-rt"
    "web-public-1b" = "public-rt"
    "web-public-1c" = "public-rt"
    
    # Private subnets (each AZ uses its own NAT)
    "app-private-1a" = "private-rt-1a"
    "app-private-1b" = "private-rt-1b"
    "app-private-1c" = "private-rt-1c"
    
    # Isolated subnets (no internet access)
    "db-isolated-1a" = "isolated-rt"
    "db-isolated-1b" = "isolated-rt"
    "db-isolated-1c" = "isolated-rt"
  }

  tags = {
    Environment = "production"
    Architecture = "multi-az-ha"
  }
}
```

### Complex Routing Example

```terraform
module "vpc" {
  source = "./vpcv2"

  vpc_cidr           = "10.0.0.0/16"
  vpc_name          = "complex-vpc"
  availability_zones = ["us-east-1a"]

  subnets = {
    "dmz-public" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      type             = "public"
    }
    "app-private" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "us-east-1a"
      type             = "private"
    }
    "mgmt-isolated" = {
      cidr_block        = "10.0.100.0/24"
      availability_zone = "us-east-1a"
      type             = "isolated"
    }
  }

  nat_gateways = {
    "dmz-nat" = {
      availability_zone = "us-east-1a"
      public_subnet_key = "dmz-public"
    }
  }

  route_tables = {
    "dmz-rt" = {
      type = "public"
    }
    "app-rt" = {
      type            = "private"
      nat_gateway_key = "dmz-nat"
    }
    "mgmt-rt" = {
      type = "custom"
      routes = [
        {
          destination_cidr_block = "192.168.0.0/16"
          # Add your VPN gateway ID here
          # gateway_id = "vgw-xxxxxxxxx"
        }
      ]
    }
  }

  subnet_route_table_associations = {
    "dmz-public"    = "dmz-rt"
    "app-private"   = "app-rt"
    "mgmt-isolated" = "mgmt-rt"
  }
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `vpc_cidr` | CIDR block for VPC | `string` |
| `vpc_name` | Name of the VPC | `string` |
| `availability_zones` | List of availability zones | `list(string)` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `subnets` | Map of subnet configurations | `map(object)` | `{}` |
| `nat_gateways` | Map of NAT Gateway configurations | `map(object)` | `{}` |
| `route_tables` | Map of route table configurations | `map(object)` | `{}` |
| `subnet_route_table_associations` | Map subnet keys to route table keys | `map(string)` | `{}` |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` |
| `enable_dns_support` | Enable DNS support in VPC | `bool` | `true` |
| `enable_dns_hostnames` | Enable DNS hostnames in VPC | `bool` | `true` |

### Subnet Configuration Object

```terraform
{
  cidr_block                = string           # Required: CIDR block for subnet
  availability_zone        = string           # Required: AZ for subnet
  type                     = string           # Required: "public", "private", "isolated"
  map_public_ip_on_launch  = optional(bool, false)  # Auto-assign public IPs
  tags                     = optional(map(string), {})  # Additional tags
}
```

### NAT Gateway Configuration Object

```terraform
{
  availability_zone = string    # Required: AZ for NAT Gateway
  public_subnet_key = string    # Required: Which public subnet to place NAT in
  tags             = optional(map(string), {})  # Additional tags
}
```

### Route Table Configuration Object

```terraform
{
  type            = string                    # Required: "public", "private", "isolated", "custom"
  nat_gateway_key = optional(string)          # Which NAT gateway to route to (for private tables)
  routes = optional(list(object({             # Custom routes
    destination_cidr_block    = string
    gateway_id               = optional(string)
    nat_gateway_id           = optional(string)
    instance_id              = optional(string)
    vpc_peering_connection_id = optional(string)
  })), [])
  tags = optional(map(string), {})           # Additional tags
}
```

## Outputs

### VPC Outputs
- `vpc_id` - ID of the VPC
- `vpc_arn` - ARN of the VPC
- `vpc_cidr_block` - CIDR block of the VPC
- `internet_gateway_id` - ID of the Internet Gateway

### Subnet Outputs
- `subnet_ids` - Map of subnet names to IDs
- `subnet_arns` - Map of subnet names to ARNs
- `subnet_cidr_blocks` - Map of subnet names to CIDR blocks
- `subnet_availability_zones` - Map of subnet names to availability zones

### Grouped Subnet Outputs
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `isolated_subnet_ids` - List of isolated subnet IDs

### NAT Gateway Outputs
- `nat_gateway_ids` - Map of NAT Gateway names to IDs
- `nat_gateway_public_ips` - Map of NAT Gateway names to public IPs
- `elastic_ip_ids` - Map of Elastic IP names to IDs
- `elastic_ip_public_ips` - Map of Elastic IP names to public IPs

### Route Table Outputs
- `route_table_ids` - Map of route table names to IDs

### Convenience Outputs
- `public_subnet_ids_by_az` - Map of AZ to public subnet IDs
- `private_subnet_ids_by_az` - Map of AZ to private subnet IDs

## Usage Examples for Common Scenarios

### ALB with EC2 Instances

```terraform
# Use VPC outputs for ALB and EC2 placement
resource "aws_lb" "main" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids

  security_groups = [aws_security_group.alb.id]
}

resource "aws_instance" "app" {
  for_each = toset(module.vpc.private_subnet_ids)
  
  ami           = "ami-xxxxxxxxx"
  instance_type = "t3.micro"
  subnet_id     = each.value

  security_groups = [aws_security_group.app.id]
}
```

### RDS Subnet Group

```terraform
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = module.vpc.isolated_subnet_ids

  tags = {
    Name = "Main DB subnet group"
  }
}
```

### Security Group Rules

```terraform
resource "aws_security_group" "app" {
  name_prefix = "app-sg"
  vpc_id      = module.vpc.vpc_id

  # Allow traffic from ALB subnets
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [for id in module.vpc.public_subnet_ids : module.vpc.subnet_cidr_blocks[keys(module.vpc.subnet_ids)[index(values(module.vpc.subnet_ids), id)]]]
  }
}
```

## Subnet Types and Routing

| Type | Internet Access | NAT Gateway | Use Cases |
|------|----------------|-------------|-----------|
| `public` | ✅ Direct via IGW | ❌ | Load balancers, bastion hosts, NAT gateways |
| `private` | ✅ Via NAT Gateway | ✅ | Application servers, workers, lambda functions |
| `isolated` | ❌ None | ❌ | Databases, internal services, security-sensitive resources |

## Cost Optimization Tips

1. **Single NAT Gateway**: Use one NAT gateway for cost savings (reduces HA)
2. **Isolated Subnets**: Use isolated subnets for databases to avoid NAT costs
3. **VPC Endpoints**: Use VPC endpoints for AWS services to avoid NAT traffic
4. **Right-size NAT Gateways**: Choose appropriate NAT gateway size based on bandwidth needs

## Migration from VPC v1

This module is designed as a complete replacement for traditional VPC modules. Key differences:

- **No default subnets** - you must explicitly define all subnets
- **Flexible routing** - route tables are not automatically created based on subnet types
- **Custom subnet naming** - you control all subnet names and organization
- **Granular control** - every aspect of networking is configurable

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0

## License

This module is released under the MIT License.