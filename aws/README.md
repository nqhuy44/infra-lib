# Terraform AWS Modules

This repository contains reusable Terraform modules for provisioning AWS resources, specifically designed for use across multiple projects and environments. The modules provide infrastructure-as-code definitions for networking, compute, container orchestration, databases, security, and global service acceleration.

## Modules

### Currently Supported Modules

| Category | Module | Status | Description |
|----------|--------|--------|-------------|
| **Networking** | [VPC](vpc/) | ✅ | Virtual Private Cloud with subnets and routing |
| | [ALB](alb/) | ✅ | Application Load Balancer for HTTP/HTTPS traffic |
| | [NLB](nlb/) | ✅ | Network Load Balancer for TCP/UDP traffic |
| | [Security Group](security-group/) | ✅ | Network security rules |
| | [EIP](eip/) | ✅ | Elastic IP addresses |
| | [VPC Peering](vpc-peering/) | ✅ | VPC connectivity |
| | [Global Accelerator](global-accelerator/) | ✅ | Global traffic optimization |
| **Compute & Containers** | [EC2](ec2/) | ✅ | Virtual machines and compute instances |
| | [EKS](eks/) | ✅ | Kubernetes service |
| | [ECR](ecr/) | ✅ | Container registry |
| **Storage & Databases** | [S3](s3/) | ✅ | Object storage |
| | [RDS](rds/) | ✅ | Relational databases |
| | [Redis](redis/) | ✅ | In-memory data store |
| **Security & Monitoring** | [WAF](waf/) | ✅ | Web Application Firewall |
| | [IAM](iam/) | ⚠️ | Identity and Access Management |
| | [Secret Manager](secret-manager/) | ✅ | Secrets management |
| | [Cloudwatch](cloudwatch/) | ⚠️ | Logging and monitoring |
| **Messaging & Streaming** | [MSK](msk/) | ✅ | Managed Kafka service |

### Status Legend
- ✅ **Stable**: Ready, well-tested modules
- ⚠️ **Unstable**: Modules under active development, may have breaking changes

### VPC Module

The VPC module creates a Virtual Private Cloud with public and private subnets across multiple availability zones, along with associated resources such as route tables, internet gateway, and NAT gateways.

- **Location**: [`vpc/`](vpc/)
- **Documentation**: [VPC Module README](vpc/README.md)

### EKS Module

The EKS module provisions an Amazon Elastic Kubernetes Service cluster with managed node groups, add-ons, IAM roles for service accounts (IRSA), and cluster access entries.

- **Location**: [`eks/`](eks/)
- **Documentation**: [EKS Module README](eks/README.md)

### EC2 Module

The EC2 module creates compute instances with configurable instance types, storage volumes, network interfaces, metadata options, and GPU support.

- **Location**: [`ec2/`](ec2/)
- **Documentation**: [EC2 Module README](ec2/README.md)

### Application Load Balancer (ALB) Module

The ALB module creates and manages AWS Application Load Balancers with support for multiple listeners, target groups, routing rules, access logs, and security configurations.

- **Location**: [`alb/`](alb/)
- **Documentation**: [ALB Module README](alb/README.md)

### Network Load Balancer (NLB) Module

The NLB module provisions a Network Load Balancer with target groups, listeners, and health checks for TCP/UDP traffic distribution.

- **Location**: [`nlb/`](nlb/)
- **Documentation**: [NLB Module README](nlb/README.md)

### RDS Module

The RDS module creates AWS RDS instances or Aurora clusters with associated resources like parameter groups, subnet groups, and option groups. Supports MySQL, PostgreSQL, and Oracle engines.

- **Location**: [`rds/`](rds/)
- **Documentation**: [RDS Module README](rds/README.md)

### Redis Module

The Redis module deploys Amazon ElastiCache for Redis with support for both cluster mode (sharded) and non-cluster mode configurations, encryption, and automatic failover.

- **Location**: [`redis/`](redis/)
- **Documentation**: [Redis Module README](redis/README.md)

### S3 Module

The S3 module creates and manages AWS S3 buckets with comprehensive configuration options including versioning, encryption, lifecycle rules, CORS, logging, website hosting, and access controls.

- **Location**: [`s3/`](s3/)
- **Documentation**: [S3 Module README](s3/README.md)

### ECR Module

The ECR module creates and manages AWS Elastic Container Registry repositories with support for repository policies, lifecycle policies, scanning configurations, and pull-through cache rules.

- **Location**: [`ecr/`](ecr/)
- **Documentation**: [ECR Module README](ecr/README.md)

### Security Group Module

The Security Group module creates and manages AWS Security Groups with comprehensive configuration options for ingress and egress rules, supporting CIDR blocks, security group references, and prefix lists.

- **Location**: [`security-group/`](security-group/)
- **Documentation**: [Security Group Module README](security-group/README.md)

### WAF Module

The WAF module creates and manages AWS WAF v2 Web ACLs with advanced logging capabilities, managed rules, custom rules, IP sets, and resource associations for ALB, CloudFront, and API Gateway.

- **Location**: [`waf/`](waf/)
- **Documentation**: [WAF Module README](waf/README.md)

### CloudWatch Module ⚠️

The CloudWatch module creates and manages AWS CloudWatch Log Groups, Log Streams, Metric Filters, and Subscription Filters with support for both single and multiple log group configurations.

- **Location**: [`cloudwatch/`](cloudwatch/)
- **Documentation**: [CloudWatch Module README](cloudwatch/README.md)
- **Status**: ⚠️ **Unstable** - Under active development, API may change

### Secrets Manager Module

The Secrets Manager module creates and manages AWS Secrets Manager secrets with schema-only mode support, secret replication, automatic rotation, and resource policy management.

- **Location**: [`secret-manager/`](secret-manager/)
- **Documentation**: [Secrets Manager Module README](secret-manager/README.md)

### IAM Module ⚠️

The IAM module provides reusable configurations for AWS Identity and Access Management resources including roles, policies, users, and groups.

- **Location**: [`iam/`](iam/)
- **Documentation**: [IAM Module README](iam/README.md)
- **Status**: ⚠️ **Unstable** - Under active development, API may change

### Elastic IP (EIP) Module

The EIP module creates and manages AWS Elastic IP addresses with optional association to EC2 instances or network interfaces, supporting flexible lifecycle management.

- **Location**: [`eip/`](eip/)
- **Documentation**: [EIP Module README](eip/README.md)

### MSK Module

The MSK module provisions Amazon Managed Streaming for Apache Kafka clusters with MSK Connect connectors, custom plugins, and worker configurations.

- **Location**: [`msk/`](msk/)
- **Documentation**: [MSK Module README](msk/README.md)

### VPC Peering Module

The VPC Peering module establishes network connectivity between two VPCs, enabling resources in either VPC to communicate with each other using private IP addresses.

- **Location**: [`vpc-peering/`](vpc-peering/)
- **Documentation**: [VPC Peering Module README](vpc-peering/README.md)

### Global Accelerator Module

The Global Accelerator module creates a global network service that routes traffic to optimal AWS regional endpoints for improved availability and performance.

- **Location**: [`global-accelerator/`](global-accelerator/)
- **Documentation**: [Global Accelerator Module README](global-accelerator/README.md)

## Environments

This repository includes example environments for both development and production deployments.

### Development Environment
- **Location**: `environments/dev`
- **Main Configuration**: `main.tf`

### Production Environment
- **Location**: `environments/prod`
- **Main Configuration**: `main.tf`

### Thailand Environment
- **Location**: `environments/th`
- **Main Configuration**: `main.tf`

## Usage

To deploy infrastructure using these modules:

1. **Initialize Terraform:**
```bash
terraform init
```

2. **Plan the deployment:**
```bash
terraform plan
```

3. **Apply the configuration:**
```bash
terraform apply
```

### Example Module Usage

```hcl
# VPC with public and private subnets
module "vpc" {
  source = "./vpc"
  
  name               = "my-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
  
  tags = {
    Environment = "production"
  }
}

# Application Load Balancer
module "alb" {
  source = "./alb"
  
  name    = "my-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnet_ids
  
  target_groups = [
    {
      name             = "web-tg"
      backend_protocol = "HTTP"
      backend_port     = 80
    }
  ]
}

# RDS Database
module "database" {
  source = "./rds"
  
  identifier     = "my-database"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  subnet_ids = module.vpc.private_subnet_ids
}
```

## Module Versioning

Modules are versioned using git tags following semantic versioning principles:

```bash
# Tag a release for all AWS modules
git tag -a "v1.0.0" -m "Release v1.0.0 of AWS modules collection"
```

**Example: Reference a specific module version**
```hcl
module "vpc" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/vpc?ref=v1.0.0"
}

module "eks" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/eks?ref=v1.0.0"
}
```

**Example: Reference a specific module branch**
```hcl
module "eks" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/eks?ref=develop"
}
```

## ⚠️ Important Notes for Unstable Modules

### CloudWatch Module
- **Current State**: Under active development
- **Known Issues**: API changes may occur in future versions
- **Recommendation**: Use with caution in production environments
- **Testing**: Thoroughly test in development before production deployment

### IAM Module
- **Current State**: Under active development
- **Known Issues**: Interface may change as requirements evolve
- **Recommendation**: Pin to specific commit when using in production
- **Testing**: Validate permissions carefully in non-production environments first

### Using Unstable Modules
When using unstable modules, consider:

1. **Pin to specific commits** instead of using latest:
```hcl
module "cloudwatch" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/cloudwatch?ref=abc123def"
}
```

2. **Test thoroughly** in development environments
3. **Monitor for breaking changes** in module updates
4. **Have rollback plans** ready for production deployments

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0 |

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Create a feature branch from main
2. Make your changes following the module structure
3. Add tests and documentation
4. Submit a pull request

### Module Structure

Each module should follow this structure:
```
module-name/
├── main.tf          # Main resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── terraform.tf     # Provider requirements
└── README.md        # Module documentation
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.