# AWS VPC Endpoint Module
This Terraform module creates and manages a VPC Endpoint with comprehensive configuration options including VPC Endpoint type (Gateway and Interface), Endpoint Service, Security Group Attachment, and Subnet Configuration. 

## Usage
```hcl
module "vpc_endpoint" {
  source = "../../modules/vpc-endpoint"
  
  # Name of the Endpoint
  name = "vpc-endpoint"
  
  # VPC Id where the VPC Endpoint belongs to
  vpc_id = "vpc-1234"
  
  # Endpoint Service
  endpoint_service = "s3"

  # Endpoint Region
  region = "ap-southeast-1"
  
  # Endpoit Service Type Interface or Gateway (Value `Interface` is set by default)
  endpoint_service_type = "Interface"
  
  # Subnet Attachment for the VPC Endpoint Interface Type
  subnet_ids = ["subnet_01", "subnet_02"]
  
  # Security Group of the VPC Endpoint
  security_group_ids = ["security_group_01", "security_group_02"]
  
  tags = {
    Environment = "production"
    Project        = "common-infra"
  }
}
```

## Input Variables

### Must-have variables for two types of VPC Endpoint
| Name                  | Description                                                      | Type        | Default | Required |
| --------------------- | ---------------------------------------------------------------- | ----------- | ------- | -------- |
| name                  | The name of the VPC Endpoint                                     | string      | ""      | no       |
| region                | The region where the VPC Endpoint belongs to                     | string      | ""      | yes      |
| vpc_id                | The ID of the VPC in which the endpoint will be used             | string      | ""      | yes      |
| endpoint_service      | Endpoint Service with the type of string                         | string      | ""      | yes      | 
| endpoint_service_type | Endpoint Service Type (Interface or Gateway)                     | string      | ""      | yes      |

### Variables for the Endpoint with the type of `Interface`
| Name                  | Description                                                                                        | Type             | Default | Required |
| --------------------- | -------------------------------------------------------------------------------------------------- | ---------------- | ------- | -------- |
| security_group_ids    | Security group IDs to associate with the VPC endpoint (If no security group IDs declared, a default SG will be created) | list(string)     | []      | no       |
| subnet_ids            | Subnets IDs to associate with the VPC endpoint                                                    | list(string)     | []      | no       |
| subnet_configurations | A list of interface endpoint containing their properties and configurations                       | list(object)     | []      | no       |
| dns_options_list      | A list of DNS Option                                                                               | list(object)     | []      | no       |


### Variables for the Endpoint with the type of `Gateway`

| Name                    | Description                                                              | Type         | Default | Required |
| ----------------------- | ------------------------------------------------------------------------ | -----------  | ------- | -------- |
| route_table_ids         | List of route table IDs to associate with the VPC endpoint              | list(string) | []      | no       |


## Outputs
| Name                            | Description                                                                                          |
| ------------------------------- | ---------------------------------------------------------------------------------------------------- |
| endpoint_id                     | VPC Endpoint ID                                                                                      |
| endpoint_arn                    | VPC Endpoint ARN                                                                                     |
| endpoint_cidr_blocks            | The list of CIDR blocks for the exposed AWS service. Applicable for endpoint of type Gateway        |
| endpoint_dns_entry              | The DNS entries for the VPC Endpoint. Applicable for endpoint of type Interface                     |
| endpoint_network_interface_ids  | One or more network interfaces for the VPC Endpoint. Applicable for endpoint of type Interface      |
| security_group_arn              | Amazon Resource Name (ARN) of the default security group. Applicable for endpoint of type Interface |
| security_group_id               | ID of the default security group of the `Interface` VPC Endpoint                                     |

## Examples

### VPC Endpoint with the type of `Interface` (No subnet configuration)
```hcl
module my_s3_interface_endpoint {
  source = "../../modules/vpc-endpoint"
  
  # Name of the VPC Endpoint
  name  = "my-s3-interface-endpoint"

  # VPC ID of the Endpoint
  vpc_id = "vpc-xxxx"

  # Name of the Endpoint Service
  endpoint_service = "s3"

  # Endpoint Region
  region = "ap-southeast-1"

  # Type of Endpoint Service
  endpoint_service_type = "Interface"
  
  # Endpoint Security Group
  security_group_ids = ["sg-xxxx", "sg-yyyyy"]
}
```

### VPC Endpoint with the type of `Interface` (With subnet configuration)

```hcl
module my_s3_interface_endpoint_with_subnet_config {
  source = "../../modules/vpc-endpoint"
  
  # Name of the VPC Endpoint
  name  = "my-s3-interface-endpoint"

  # VPC ID of the Endpoint
  vpc_id = "vpc-xxxx"

  # Name of the Endpoint Service
  endpoint_service = "s3"

  # Endpoint Region
  region = "ap-southeast-1"

  # Type of Endpoint Service
  endpoint_service_type = "Interface"
  
  # Endpoint Security Group
  security_group_ids = ["sg-xxxx", "sg-yyyyy"]
  
  # Subnet ID
  subnet_ids = [
    "subnet-xxxxxx",
    "subnet-yyyyyy"
  ]

  subnet_configurations = [
    {
      subnet_id = "subnet-xxxxxx"
      ipv4      = "x.y.z.t"
    },
    {
      subnet_id = "subnet-yyyyyy"
      ipv4      = "x.y.m.n"
    }
  ]
}
```

### VPC Endpoint with the type of `Gateway`
```hcl
module my_s3_gateway_endpoint {
  source = "../../modules/vpc-endpoint"

  # Name of the VPC Endpoint
  name  = "my-s3-endpoint-gw"

  # VPC ID of the Endpoint
  vpc_id = "vpc-xxxxx"

  # Endpoint Region
  region = "ap-southeast-1"

  # Name of the Endpoint Service
  endpoint_service = "s3"

  # Type of Endpoint Service
  endpoint_service_type = "Gateway"

  # Route table for the Gateway Endpoint
  route_table_ids = ["rtb-xxxx"]
}
```

## Notes

### VPC Endpoint with `Interface` type

- If `security_group_ids` is not declared, a default SG will be created and associated with the VPC Endpoint
- If `subnet_ids` is not declared, VPC Endpoint still be created and we cannot see the associated interface
- When we define the `subnet_configurations`, each subnet can use only one CNI. It means that the configuration below is **invalid**.

```hcl
subnet_configurations = [
    {
      subnet_id = "subnet-xxxxxx"
      ipv4      = "x.y.z.t"
    },
    {
      subnet_id = "subnet-xxxxxx"
      ipv4      = "x.y.n.m"
    }
  ]
```
### VPC Endpoint with `Gateway` type

- If `route_table_ids` is not declared, the VPC Endpoint will not associated with any route tables.