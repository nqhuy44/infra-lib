# AWS Security Group Module
This Terraform module creates and manages AWS Security Groups with comprehensive configuration options for ingress and egress rules. It supports various rule types including CIDR blocks, security group references, and prefix lists.

## Usage
```hcl
module "web_server_sg" {
  source = "../../modules/security-group"

  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules
  ingress_rules = [
    {
      description = "Allow HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow SSH from specific IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  # Egress rules - default allows all outbound traffic
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Input Variables
| Name        | Description                                         | Type        | Default                | Required |
| ----------- | --------------------------------------------------- | ----------- | ---------------------- | -------- |
| name        | Name tag for the Security Group                     | string      | n/a                    | yes      |
| description | Description for the Security Group                  | string      | "Managed by Terraform" | no       |
| vpc_id      | The VPC ID where the Security Group will be created | string      | n/a                    | yes      |
| tags        | A map of additional tags to assign to the SG        | map(string) | {}                     | no       |

Ingress and Egress Rules
| Name          | Description                                  | Type         | Default              | Required |
| ------------- | -------------------------------------------- | ------------ | -------------------- | -------- |
| ingress_rules | List of ingress rules for the security group | list(object) | []                   | no       |
| egress_rules  | List of egress rules for the security group  | list(object) | [Allow all outbound] | no       |

Each rule in `ingress_rules` and `egress_rules` is an object with the following attributes:
| Attribute         | Description                                | Type         | Required |
| ----------------- | ------------------------------------------ | ------------ | -------- |
| description       | Description of the rule                    | string       | no       |
| from_port         | Start port range                           | number       | yes      |
| to_port           | End port range                             | number       | yes      |
| protocol          | Protocol (tcp, udp, icmp, or "-1" for all) | string       | yes      |
| cidr_blocks       | List of CIDR blocks                        | list(string) | no       |
| ipv6_cidr_blocks  | List of IPv6 CIDR blocks                   | list(string) | no       |
| prefix_list_ids   | List of prefix list IDs                    | list(string) | no       |
| security_group_id | ID of a source/destination security group  | string       | no       |
| self              | Whether to allow traffic from/to itself    | bool         | no       |

*Note*: For each rule, you must specify exactly one destination type (`cidr_blocks`, `ipv6_cidr_blocks`, `prefix_list_ids`, `security_group_id`, or `self`).

## Outputs
| Name                | Description                            |
| ------------------- | -------------------------------------- |
| security_group_id   | The ID of the created Security Group   |
| security_group_arn  | The ARN of the created Security Group  |
| security_group_name | The name of the created Security Group |

## Examples
Basic Web Server Security Group
```hcl
module "web_server_sg" {
  source = "../../modules/security-group"

  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "Allow HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  tags = {
    Environment = "production"
  }
}
```

Database Security Group (allowing access only from specific security groups)
```hcl
module "database_sg" {
  source = "../../modules/security-group"

  name        = "database-sg"
  description = "Security group for database servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description       = "Allow MySQL from application servers"
      from_port         = 3306
      to_port           = 3306
      protocol          = "tcp"
      security_group_id = module.app_server_sg.security_group_id
    },
    {
      description       = "Allow PostgreSQL from application servers"
      from_port         = 5432
      to_port           = 5432
      protocol          = "tcp"
      security_group_id = module.app_server_sg.security_group_id
    }
  ]
  
  # Restrict outbound traffic
  egress_rules = [
    {
      description = "Allow only necessary outbound traffic"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow DNS queries"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  tags = {
    Environment = "production"
    Type        = "database"
  }
}
```

Self-Referencing Security Group for Cluster Communication
```hcl
module "cluster_sg" {
  source = "../../modules/security-group"

  name        = "cluster-sg"
  description = "Security group for cluster nodes"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "Allow all traffic between cluster nodes"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      self        = true
    },
    {
      description = "Allow SSH from bastion host"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      security_group_id = module.bastion_sg.security_group_id
    }
  ]
  
  tags = {
    Environment = "production"
    Cluster     = "app-cluster"
  }
}
```

Mixed Rule Types with IPv6 Support
```hcl
module "complex_sg" {
  source = "../../modules/security-group"

  name        = "complex-sg"
  description = "Security group with mixed rule types"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description      = "Allow HTTP from IPv4 CIDR"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["10.0.0.0/8"]
    },
    {
      description      = "Allow HTTPS from IPv6 CIDR"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "Allow traffic from VPC endpoint"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      prefix_list_ids  = ["pl-12345678"]
    }
  ]
  
  egress_rules = [
    {
      description = "Allow all outbound IPv4 traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description      = "Allow all outbound IPv6 traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
  
  tags = {
    Environment = "production"
  }
}
```