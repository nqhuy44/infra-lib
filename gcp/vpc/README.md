# GCP VPC Module

This module creates a VPC network in Google Cloud Platform with custom subnets.

## Usage

```hcl
module "vpc" {
  source       = "../../gcp/vpc"
  project_id   = "my-project-id"
  network_name = "my-vpc"
  
  subnets = [
    {
      subnet_name           = "subnet-01"
      subnet_ip             = "10.0.1.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = true
      description           = "This is a test subnet"
      
      # Optional: Secondary Ranges
      secondary_ip_range = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
      
      # Optional: VPC Flow Logs
      log_config = {
        aggregation_interval = "INTERVAL_10_MIN"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project where this VPC will be created | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | The name of the VPC network being created | `string` | n/a | yes |
| <a name="input_routing_mode"></a> [routing\_mode](#input\_routing\_mode) | The network routing mode (default 'GLOBAL') | `string` | `"GLOBAL"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The list of subnets being created | <pre>list(object({<br>    subnet_name           = string<br>    subnet_ip             = string<br>    subnet_region         = string<br>    subnet_private_access = optional(bool, false)<br>    description           = optional(string)<br>    secondary_ip_range    = optional(list(object({<br>      range_name    = string<br>      ip_cidr_range = string<br>    })), [])<br>    log_config            = optional(object({<br>      aggregation_interval = optional(string)<br>      flow_sampling        = optional(number)<br>      metadata             = optional(string)<br>      metadata_fields      = optional(list(string))<br>      filter_expr          = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_mtu"></a> [mtu](#input\_mtu) | The network MTU (If set to 0, meaning it is not set) | `number` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network"></a> [network](#output\_network) | The created network resource |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | The created subnets resources |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | The name of the VPC network |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | The ID of the VPC network |
| <a name="output_network_self_link"></a> [network\_self\_link](#output\_network\_self\_link) | The URI of the VPC network |
