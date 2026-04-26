# GCP Service Account Module

This module simplifies the creation and configuration of Google Cloud Service Accounts.

## Features

- Creates a Service Account.
- Optionally assigns a list of project-level IAM roles to the Service Account.
- Optionally assigns `roles/iam.serviceAccountUser` to a list of members, allowing them to use or impersonate the Service Account.

## Usage

```hcl
module "app_sa" {
  source       = "../../gcp/service-account"
  project_id   = "my-project-id"
  account_id   = "my-app-sa"
  display_name = "My App Service Account"
  
  # Roles to grant TO the service account (what the SA can do)
  project_roles = [
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client"
  ]
  
  # Members who can USE/IMPERSONATE this service account
  sa_users = [
    "user:developer@example.com",
    "group:backend-team@example.com"
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. | `string` | n/a | yes |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account id that is used to generate the service account email address. | `string` | n/a | yes |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | The display name for the service account. | `string` | `""` | no |
| <a name="input_description"></a> [description](#input\_description) | A text description of the service account. | `string` | `""` | no |
| <a name="input_project_roles"></a> [project\_roles](#input\_project\_roles) | A list of roles to be added to the created service account. | `list(string)` | `[]` | no |
| <a name="input_sa_users"></a> [sa\_users](#input\_sa\_users) | A list of IAM members who are allowed to impersonate/use this service account. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_email"></a> [email](#output\_email) | The e-mail address of the service account. |
| <a name="output_name"></a> [name](#output\_name) | The fully-qualified name of the service account. |
| <a name="output_unique_id"></a> [unique\_id](#output\_unique\_id) | The unique id of the service account. |
