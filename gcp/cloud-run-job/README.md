# GCP Cloud Run Job Module

This module creates a Cloud Run (v2) Job in Google Cloud Platform. Cloud Run Jobs are used to run scripts, batch processing, or other tasks that run to completion, unlike Cloud Run Services which listen for and respond to web requests.

## Usage

```hcl
module "cloud_run_job" {
  source          = "../../gcp/cloud-run-job"
  project_id      = "my-project-id"
  name            = "my-job"
  location        = "us-central1"
  image           = "gcr.io/my-project/my-image:latest"
  
  env_vars = {
    DATABASE_URL = "postgres://..."
  }

  secret_vars = {
    API_KEY = "my-api-key-secret-name"
  }

  cpu_limit    = "1000m"
  memory_limit = "512Mi"
  
  task_count   = 10
  parallelism  = 3
  timeout      = "600s"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Cloud Run Job. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location of the Cloud Run Job. | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | The image to deploy to the Cloud Run Job. | `string` | n/a | yes |
| <a name="input_command"></a> [command](#input\_command) | Entrypoint command. Leaves empty to use the default. | `list(string)` | `[]` | no |
| <a name="input_args"></a> [args](#input\_args) | Arguments to the entrypoint command. | `list(string)` | `[]` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A map of environment variables to set in the container. | `map(string)` | `{}` | no |
| <a name="input_secret_vars"></a> [secret\_vars](#input\_secret\_vars) | A map of environment variables to set from Google Secret Manager. | `map(string)` | `{}` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | The CPU limit for the container (e.g., '1000m' or '1'). | `string` | `"1000m"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | The memory limit for the container (e.g., '512Mi'). | `string` | `"512Mi"` | no |
| <a name="input_task_count"></a> [task\_count](#input\_task\_count) | Number of tasks to run per execution. | `number` | `1` | no |
| <a name="input_parallelism"></a> [parallelism](#input\_parallelism) | Max number of tasks to run in parallel. | `number` | `1` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Max duration a task is allowed to run (e.g. '600s'). | `string` | `"600s"` | no |
| <a name="input_execution_environment"></a> [execution\_environment](#input\_execution\_environment) | The execution environment for the Cloud Run Job (e.g., EXECUTION_ENVIRONMENT_GEN2). | `string` | `"EXECUTION_ENVIRONMENT_GEN2"` | no |
| <a name="input_vpc_connector"></a> [vpc\_connector](#input\_vpc\_connector) | The VPC connector to use for the Cloud Run Job. | `string` | `null` | no |
| <a name="input_egress_settings"></a> [egress\_settings](#input\_egress\_settings) | The egress settings for the VPC connector. | `string` | `"ALL_TRAFFIC"` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email address of the service account to use for the Cloud Run Job. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of labels to apply to the Cloud Run Job. | `map(string)` | `{}` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | A list of volumes (secret, empty_dir, gcs, etc) to make available to containers. | `list(object)` | `[]` | no |
| <a name="input_volume_mounts"></a> [volume_mounts](#input\_volume_mounts) | A list of volume mounts (name, mount_path) to mount in the container. | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | An identifier for the resource. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Cloud Run Job. |
| <a name="output_location"></a> [location](#output\_location) | The location of the Cloud Run Job. |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The project ID in which the job was created. |
| <a name="output_latest_created_execution"></a> [latest\_created\_execution](#output\_latest\_created\_execution) | Name of the last created execution. |
