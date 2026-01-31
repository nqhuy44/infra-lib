# GCP Firewall Module

This module creates a firewall rule in Google Cloud Platform.

## Usage

```hcl
module "firewall" {
  source     = "../../gcp/firewall"
  project_id = "my-project-id"
  name       = "allow-ssh"
  network    = "default"
  target_tags = ["ssh-enabled"]
  
  allow = [
    {
      protocol = "tcp"
      ports    = ["22"]
    }
  ]
  
  source_ranges = ["0.0.0.0/0"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID where the firewall rule will be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the firewall rule. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Name or self\_link of the network this rule applies to. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Description of the firewall rule. | `string` | `null` | no |
| <a name="input_allow"></a> [allow](#input\_allow) | List of allowing protocols and ports. | <pre>list(object({<br>    protocol = string<br>    ports    = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_deny"></a> [deny](#input\_deny) | List of denying protocols and ports. | <pre>list(object({<br>    protocol = string<br>    ports    = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_source_ranges"></a> [source\_ranges](#input\_source\_ranges) | Source IP ranges. | `list(string)` | `[]` | no |
| <a name="input_source_tags"></a> [source\_tags](#input\_source\_tags) | Source tags. | `list(string)` | `[]` | no |
| <a name="input_target_tags"></a> [target\_tags](#input\_target\_tags) | Target tags. | `list(string)` | `[]` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | Priority of the rule. | `number` | `1000` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_rule"></a> [firewall\_rule](#output\_firewall\_rule) | The created firewall rule resource |
| <a name="output_name"></a> [name](#output\_name) | The name of the firewall rule |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | The URI of the firewall rule |
| <a name="output_target_tags"></a> [target\_tags](#output\_target\_tags) | The target tags applied by the firewall rule |
