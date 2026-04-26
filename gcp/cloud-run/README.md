# GCP Cloud Run Module

This module creates a Cloud Run (v2) service in Google Cloud Platform.

## Usage

```hcl
module "cloud_run" {
  source          = "../../gcp/cloud-run"
  project_id      = "my-project-id"
  name            = "my-service"
  location        = "us-central1"
  image           = "gcr.io/my-project/my-image:latest"
  container_port  = 8080
  
  env_vars = {
    DATABASE_URL = "postgres://..."
  }

  secret_vars = {
    API_KEY = "my-api-key-secret-name"
  }

  cpu_limit    = "1000m"
  memory_limit = "512Mi"
  
  min_instance_count = 0
  max_instance_count = 5
  
  allow_unauthenticated_access = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Cloud Run service. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location of the Cloud Run service. | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | The image to deploy to the Cloud Run service. | `string` | n/a | yes |
| <a name="input_command"></a> [command](#input\_command) | Entrypoint command. Leaves empty to use the default. | `list(string)` | `[]` | no |
| <a name="input_args"></a> [args](#input\_args) | Arguments to the entrypoint command. | `list(string)` | `[]` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port on which the container listens. | `number` | `8080` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A map of environment variables to set in the container. | `map(string)` | `{}` | no |
| <a name="input_secret_vars"></a> [secret\_vars](#input\_secret\_vars) | A map of environment variables to set from Google Secret Manager. | `map(string)` | `{}` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | The CPU limit for the container (e.g., '1000m' or '1'). | `string` | `"1000m"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | The memory limit for the container (e.g., '512Mi'). | `string` | `"512Mi"` | no |
| <a name="input_cpu_idle"></a> [cpu\_idle](#input\_cpu\_idle) | Determines whether CPU is allocated only during requests (true) or always (false). | `bool` | `true` | no |
| <a name="input_startup_cpu_boost"></a> [startup\_cpu\_boost](#input\_startup\_cpu\_boost) | Enable CPU boost on startup. | `bool` | `false` | no |
| <a name="input_min_instance_count"></a> [min\_instance\_count](#input\_min\_instance\_count) | The minimum number of instances to maintain. | `number` | `0` | no |
| <a name="input_max_instance_count"></a> [max\_instance\_count](#input\_max\_instance\_count) | The maximum number of instances to maintain. | `number` | `10` | no |
| <a name="input_max_instance_request_concurrency"></a> [max\_instance\_request\_concurrency](#input\_max\_instance\_request\_concurrency) | Sets the maximum number of requests that each serving instance can receive. | `number` | `null` | no |
| <a name="input_vpc_connector"></a> [vpc\_connector](#input\_vpc\_connector) | The VPC connector to use for the Cloud Run service. | `string` | `null` | no |
| <a name="input_egress_settings"></a> [egress\_settings](#input\_egress\_settings) | The egress settings for the VPC connector. | `string` | `"ALL_TRAFFIC"` | no |
| <a name="input_ingress_settings"></a> [ingress\_settings](#input\_ingress\_settings) | The ingress settings for the Cloud Run service. | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| <a name="input_allow_unauthenticated_access"></a> [allow\_unauthenticated\_access](#input\_allow\_unauthenticated\_access) | Whether to allow unauthenticated access to the Cloud Run service. | `bool` | `false` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email address of the service account to use for the Cloud Run service. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of labels to apply to the Cloud Run service. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_uri"></a> [uri](#output\_uri) | The URI of the Cloud Run service. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Cloud Run service. |
| <a name="output_location"></a> [location](#output\_location) | The location of the Cloud Run service. |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The project ID in which the service was created. |
| <a name="output_latest_ready_revision"></a> [latest\_ready\_revision](#output\_latest\_ready\_revision) | The latest ready revision name of the Cloud Run service. |
