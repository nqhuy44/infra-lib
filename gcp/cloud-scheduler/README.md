# GCP Cloud Scheduler Module for Cloud Run Jobs

This module creates a Google Cloud Scheduler job specifically designed to trigger Cloud Run Jobs on a schedule (cron-like). It automatically creates the necessary Service Account and IAM bindings (`roles/run.invoker`) if you don't provide one.

## Usage

```hcl
module "chiwi_job_scheduler" {
  source          = "../../gcp/cloud-scheduler"
  project_id      = "my-project-id"
  region          = "us-central1"
  name            = "trigger-chiwi-job"
  description     = "Trigger Chiwi Worker Job every day at 2 AM"
  
  schedule        = "0 2 * * *"
  time_zone       = "Asia/Ho_Chi_Minh"
  
  # The exact name of the Cloud Run Job you want to trigger
  target_job_name = "chiwi-worker-job"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region of the Cloud Scheduler. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Cloud Scheduler job. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Description of the Cloud Scheduler job. | `string` | `""` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | The cron schedule expression (e.g., '0 2 * * *'). | `string` | n/a | yes |
| <a name="input_time_zone"></a> [time\_zone](#input\_time\_zone) | The timezone for the schedule. | `string` | `"Asia/Ho_Chi_Minh"` | no |
| <a name="input_target_job_name"></a> [target\_job\_name](#input\_target\_job\_name) | The name of the Cloud Run Job to trigger. | `string` | n/a | yes |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | Service account email to use. If empty, a new SA will be created automatically. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | An identifier for the resource. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Cloud Scheduler job. |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | The service account email used to trigger the job. |
