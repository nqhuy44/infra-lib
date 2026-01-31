# Global Accelerator Module

This module creates an AWS Global Accelerator with listeners and endpoint groups, allowing you to route traffic to NLBs, ALBs, EIPs, or EC2 instances across multiple regions with low latency.

## Usage

```hcl
module "global_accelerator" {
  source = "../../modules/global-accelerator"
  
  name            = "my-global-accelerator"
  ip_address_type = "IPV4"
  enabled         = true
  
  # Listeners configuration
  listeners = {
    http = {
      port     = 80
      protocol = "TCP"
      port_ranges = [
        {
          from_port = 80
          to_port   = 80
        }
      ]
    }
  }
  
  # Endpoint groups configuration
  endpoint_groups = {
    us_east = {
      listener_key  = "http"
      region        = "us-east-1"
      endpoints = [
        {
          endpoint_id = "nlb-12345"
          weight      = 100
          client_ip_preservation_enabled = true
        }
      ]
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

## Input Variables

| Name                | Description                          | Type        | Default | Required |
| ------------------- | ------------------------------------ | ----------- | ------- | -------- |
| name                | Name of the Global Accelerator       | string      | n/a     | yes      |
| enabled             | Whether the accelerator is enabled   | bool        | true    | no       |
| ip_address_type     | IP address type (IPV4 or DUAL_STACK) | string      | "IPV4"  | no       |
| flow_logs_enabled   | Whether flow logs are enabled        | bool        | false   | no       |
| flow_logs_s3_bucket | S3 bucket for flow logs              | string      | null    | no       |
| flow_logs_s3_prefix | S3 prefix for flow logs              | string      | null    | no       |
| listeners           | Map of listener configurations       | map(object) | {}      | no       |
| endpoint_groups     | Map of endpoint group configurations | map(object) | {}      | no       |
| tags                | Tags to apply to all resources       | map(string) | {}      | no       |

Listener Object Structure
```hcl
listeners = {
  key = {
    port            = number
    protocol        = string  # "TCP" or "UDP"
    client_affinity = optional(string)
    port_ranges = list(object({
      from_port = number
      to_port   = number
    }))
  }
}
```

Endpoint Group Object Structure
```hcl
endpoint_groups = {
  key = {
    listener_key               = string
    region                     = string
    health_check_interval      = optional(number)
    health_check_path          = optional(string)
    health_check_port          = optional(number)
    health_check_protocol      = optional(string)
    threshold_count            = optional(number)
    traffic_dial_percentage    = optional(number)
    endpoints = list(object({
      endpoint_id                    = string
      weight                         = optional(number)
      client_ip_preservation_enabled = optional(bool)
    }))
  }
}
```

## Outputs

| Name            | Description                                        |
| --------------- | -------------------------------------------------- |
| accelerator_id  | ID of the Global Accelerator                       |
| accelerator_arn | ARN of the Global Accelerator                      |
| dns_name        | DNS name of the Global Accelerator                 |
| hosted_zone_id  | Route 53 hosted zone ID for the Global Accelerator |
| ip_sets         | IP address set of the Global Accelerator           |
| listeners       | Map of listeners created                           |
| endpoint_groups | Map of endpoint groups created                     |

## Examples

Multi-Region Global Accelerator
```hcl
module "multi_region_ga" {
  source = "../../modules/global-accelerator"
  
  name = "multi-region-ga"
  
  # Listeners for different protocols
  listeners = {
    http = {
      protocol = "TCP"
      port_ranges = [
        {
          from_port = 80
          to_port   = 80
        },
        {
          from_port = 443
          to_port   = 443
        }
      ]
    }
  }
  
  # Endpoint groups in different regions
  endpoint_groups = {
    us_east = {
      listener_key = "http"
      region       = "us-east-1"
      endpoints = [
        {
          endpoint_id = module.us_east_nlb.id
          weight      = 100
          client_ip_preservation_enabled = true
        }
      ]
    },
    eu_west = {
      listener_key = "http"
      region       = "eu-west-1"
      endpoints = [
        {
          endpoint_id = module.eu_west_nlb.id
          weight      = 100
          client_ip_preservation_enabled = true
        }
      ]
    }
  }
  
  tags = {
    Environment = "production"
    Service     = "global-web"
  }
}
```
