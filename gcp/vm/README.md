# GCP VM Module

This module creates a Compute Engine instance in Google Cloud Platform.

## Usage

```hcl
module "vm" {
  source          = "../../gcp/vm"
  project_id      = "my-project-id"
  name            = "example-vm"
  machine_type    = "e2-micro"
  zone            = "us-central1-a"
  network         = "default"
  subnetwork      = "default"
  boot_disk_image = "debian-cloud/debian-11"
  boot_disk_size  = 50
  boot_disk_type  = "pd-ssd"
  
  # Optional: Public IP
  assign_public_ip = true
  
  # Optional: IPv6
  enable_ipv6      = true
  
  # Optional: Spot Instance
  spot_instance    = true
  
  # Optional: Tags (e.g. from firewall)
  tags = ["web-server", "ssh-access"]
  
  # Optional: SSH Keys
  ssh_keys = [
    {
      user       = "myuser"
      public_key = "ssh-rsa AAA..."
    }
  ]
  
  # Optional: Additional Data Disks
  additional_disks = [
    {
      name = "data-disk",
      size = 50,
      type = "pd-standard"
    },
    {
      name = "log-disk",
      size = 20,
      type = "pd-ssd"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID where the VM will be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the instance. | `string` | n/a | yes |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Machine type to create (e.g., e2-micro). | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone to create the instance in. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Name or self\_link of the network to attach to. | `string` | n/a | yes |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Name or self\_link of the subnetwork to attach to. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Network tags. | `list(string)` | `[]` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | List of SSH keys to inject into the instance metadata. | <pre>list(object({<br>    user       = string<br>    public_key = string<br>  }))</pre> | `[]` | no |
| <a name="input_boot_disk_image"></a> [boot\_disk\_image](#input\_boot\_disk\_image) | Image to use for the boot disk. | `string` | `"debian-cloud/debian-11"` | no |
| <a name="input_boot_disk_size"></a> [boot\_disk\_size](#input\_boot\_disk\_size) | Size of the boot disk in GB. | `number` | `10` | no |
| <a name="input_boot_disk_type"></a> [boot\_disk\_type](#input\_boot\_disk\_type) | Type of the boot disk (e.g., pd-standard, pd-ssd, pd-balanced). | `string` | `"pd-standard"` | no |
| <a name="input_additional_disks"></a> [additional\_disks](#input\_additional\_disks) | List of additional data disks to create and attach to the instance. | <pre>list(object({<br>    name        = string<br>    size        = number<br>    type        = optional(string, "pd-standard")<br>    device_name = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | If true, assigns a public IPv4 address to the instance. | `bool` | `false` | no |
| <a name="input_static_public_ip"></a> [static\_public\_ip](#input\_static\_public\_ip) | The static external IP address to assign to the instance. Requires assign\_public\_ip to be true. | `string` | `null` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | If true, enable IPv6 on the network interface. | `bool` | `false` | no |
| <a name="input_spot_instance"></a> [spot\_instance](#input\_spot\_instance) | If true, provision as a Spot VM (preemptible). | `bool` | `false` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Metadata key/value pairs. | `map(string)` | `{}` | no |
| <a name="input_metadata_startup_script"></a> [metadata\_startup\_script](#input\_metadata\_startup\_script) | Startup script to run when the instance starts. | `string` | `null` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to attach to the instance. | <pre>object({<br>    email  = string<br>    scopes = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance"></a> [instance](#output\_instance) | The created instance resource |
| <a name="output_name"></a> [name](#output\_name) | The name of the instance |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The server-assigned unique identifier of this instance |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | The URI of the created resource |
| <a name="output_network_interface"></a> [network\_interface](#output\_network\_interface) | The network interface of the instance |
| <a name="output_additional_disk_ids"></a> [additional\_disk\_ids](#output\_additional\_disk\_ids) | The IDs of the additional disks created |
