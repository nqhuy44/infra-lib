# GCP Secret Manager Module

This module provisions Google Cloud Secret Manager secrets in bulk. It is designed to easily provision the secret infrastructure (and optionally assign `secretAccessor` permissions) while ignoring changes to the secret values (`secret_data`) after creation. This allows external tools, CI/CD, or manual intervention to manage the real secret values without Terraform overriding them.

## Features

- Provision multiple secrets via a simple map (`secrets = { name = "placeholder" }`).
- Automatically ignores changes to the actual secret values (lifecycle ignore_changes).
- Bulk assigns `roles/secretmanager.secretAccessor` to a list of users or service accounts across all created secrets.
- Supports applying labels (tags) to all secrets.

## Usage

```hcl
module "secrets" {
  source     = "../../gcp/secret-manager"
  project_id = "my-project-id"

  secrets = {
    "DB_PASSWORD" = "changeme"
    "API_KEY"     = "changeme"
  }

  accessors = [
    "serviceAccount:my-app-sa@my-project-id.iam.gserviceaccount.com"
  ]

  labels = {
    environment = "production"
    team        = "backend"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. | `string` | n/a | yes |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | A map of secret names to their initial placeholder values. | `map(string)` | n/a | yes |
| <a name="input_accessors"></a> [accessors](#input\_accessors) | A list of IAM members to grant roles/secretmanager.secretAccessor to all secrets. | `list(string)` | `[]` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of labels (tags) to apply to all secrets. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | A list of the created secret IDs. |
| <a name="output_secret_names"></a> [secret\_names](#output\_secret\_names) | A map of secret keys to their fully qualified resource names. |
| <a name="output_secret_version_names"></a> [secret\_version_names](#output\_secret\_version_names) | A map of secret keys to their fully qualified secret version resource names. |
