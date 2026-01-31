# AWS Elastic IP (EIP) Module
This Terraform module creates and manages AWS Elastic IP addresses (EIPs) with the option to associate them with EC2 instances or network interfaces.

## Features
- Create one or multiple Elastic IPs
- Flexible naming options
- Optional direct association with EC2 instances or network interfaces
- Support for separate EIP associations (for better lifecycle management)
- Comprehensive tagging support
- Protection against accidental EIP recreation when associations change

## Usage
Basic Example: Single EIP
```hcl
module "single_eip" {
  source = "../../modules/eip"

  name = "web-server"
  
  tags = {
    Environment = "Production"
    Service     = "WebApp"
  }
}
```

Associate EIP with an EC2 Instance
```hcl
module "server_eip" {
  source = "../../modules/eip"

  name = "api-server"
  
  # Directly associate with instance
  associate_with_instance = true
  instance_ids = [module.api_server.instance_id]
  
  tags = {
    Environment = "Production"
    Service     = "API"
  }
}
```

Multiple EIPs for a Cluster
```hcl
module "cluster_eips" {
  source = "../../modules/eip"

  name           = "app-cluster"
  number_of_eips = 3
  
  # Use separate association resources
  create_separate_association = true
  instance_ids = [
    module.app_server_1.instance_id,
    module.app_server_2.instance_id,
    module.app_server_3.instance_id
  ]
  
  tags = {
    Environment = "Production"
    Cluster     = "App-Cluster"
  }
}
```

Custom EIP Names
```hcl
module "named_eips" {
  source = "../../modules/eip"

  name           = "gateway"
  number_of_eips = 2
  eip_names      = ["primary-gateway", "failover-gateway"]
  
  tags = {
    Environment = "Production"
    Role        = "Gateway"
  }
}
```

## Input Variables
| Name                        | Description                                                | Type         | Default | Required |
| --------------------------- | ---------------------------------------------------------- | ------------ | ------- | -------- |
| create                      | Whether to create the Elastic IP resources                 | bool         | true    | no       |
| name                        | Name prefix for the Elastic IPs                            | string       | "eip"   | no       |
| number_of_eips              | Number of Elastic IPs to create                            | number       | 1       | no       |
| network_border_group        | The network border group to create the EIP within          | string       | null    | no       |
| public_ipv4_pool            | The public IPv4 pool from which to allocate the Elastic IP | string       | null    | no       |
| eip_names                   | Explicit names for the Elastic IPs (overrides name prefix) | list(string) | null    | no       |
| associate_with_instance     | Whether to associate the EIPs with EC2 instances           | bool         | false   | no       |
| create_separate_association | Whether to create a separate EIP association resource      | bool         | false   | no       |
| instance_ids                | List of EC2 instance IDs to associate with the EIPs        | list(string) | null    | no       |
| network_interface_ids       | List of network interface IDs to associate with the EIPs   | list(string) | null    | no       |
| tags                        | A map of tags to assign to all resources                   | map(string)  | {}      | no       |
| eip_tags                    | Additional tags for the Elastic IPs                        | map(string)  | {}      | no       |

## Outputs
| Name         | Description                                                                     |
| ------------ | ------------------------------------------------------------------------------- |
| ids          | List of Elastic IP allocation IDs                                               |
| public_ips   | List of Elastic IP public IP addresses                                          |
| private_ips  | List of Elastic IP private IP addresses (if associated with network interfaces) |
| public_dns   | List of Elastic IP public DNS names                                             |
| associations | List of Elastic IP association IDs                                              |

## Association Options

This module provides two ways to associate EIPs with instances:

1. Direct association: Set associate_with_instance = true and provide instance_ids. This approach is simpler but can lead to EIP recreation if associations change.

2. Separate association resources: Set create_separate_association = true and provide instance_ids. This approach uses separate aws_eip_association resources, which allows changing associations without recreating the EIPs.

## Notes
- EIPs are a limited resource in AWS accounts (5 per region by default)
- EIPs may incur charges when not associated with running instances
- The module includes a lifecycle configuration to prevent recreation of EIPs when associations change
- If both instance_ids and network_interface_ids are provided, precedence follows AWS rules (generally, instance associations take precedence)

## Requirements
terraform >= 1.0.0
aws >= 4.0.0