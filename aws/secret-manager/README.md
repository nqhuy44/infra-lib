# AWS Secrets Manager Terraform Module

A simple Terraform module for creating AWS Secrets Manager secrets with schema initialization. This module creates secrets with a predefined key structure and empty values, allowing you to manage the actual secret values through the AWS Console.

## Features

- ✅ **Schema-only management** - Defines secret structure without managing values
- ✅ **Simple and reliable** - No complex logic or drift detection
- ✅ **Value preservation** - Never overwrites values set in AWS Console
- ✅ **Cross-region replication** support
- ✅ **KMS encryption** support
- ✅ **Automatic rotation** support
- ✅ **Resource policies** support

## Usage

### Basic Example

```terraform
module "database_secret" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/secret-manager?ref=main"

  name = "production-database-credentials"

  secret_key_value = {
    username = ""
    password = ""
    host     = ""
    port     = ""
    database = ""
  }

  environment = "production"

  tags = {
    Application = "myapp"
    Component   = "database"
  }
}
```

### API Keys Secret

```terraform
module "api_keys" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/secret-manager?ref=main"

  name = "external-api-keys"

  secret_key_value = {
    stripe_api_key    = ""
    sendgrid_api_key  = ""
    github_token      = ""
    slack_webhook_url = ""
  }

  description = "External service API keys"
  environment = "production"
}
```

### With KMS Encryption

```terraform
module "encrypted_secret" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/secret-manager?ref=main"

  name = "sensitive-credentials"

  secret_key_value = {
    admin_password = ""
    master_key     = ""
    private_key    = ""
  }

  kms_key_id  = aws_kms_key.secrets.arn
  environment = "production"
}
```

### With Cross-Region Replication

```terraform
module "global_secret" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/secret-manager?ref=main"

  name = "global-service-credentials"

  secret_key_value = {
    service_account_key = ""
    api_endpoint        = ""
    auth_token          = ""
  }

  replica_regions = [
    {
      region = "us-west-2"
    },
    {
      region = "eu-west-1"
    }
  ]

  environment = "production"
}
```

### With Automatic Rotation

```terraform
module "rotated_secret" {
  source = "git::https://github.com/your-org/terraform-modules.git//aws/secret-manager?ref=main"

  name = "database-with-rotation"

  secret_key_value = {
    username = ""
    password = ""
    host     = ""
  }

  enable_rotation         = true
  rotation_lambda_arn     = aws_lambda_function.rotation.arn
  rotation_interval_days  = 30

  environment = "production"
}
```

## Workflow

### 1. Define Schema in Terraform

```terraform
module "app_secret" {
  source = "./secret-manager"

  name = "my-app-credentials"

  secret_key_value = {
    username = ""  # Values don't matter, just define the keys you need
    password = ""
    api_key  = ""
  }
}
```

### 2. Apply Terraform

```bash
terraform apply
```

This creates the secret with empty values for all keys.

### 3. Set Real Values in AWS Console

1. Go to AWS Secrets Manager in the console
2. Find your secret: `my-app-credentials`
3. Click "Retrieve secret value" → "Edit"
4. Set the actual values:
   - `username`: `admin`
   - `password`: `mySecretPassword123`
   - `api_key`: `abc123xyz789`
5. Save

### 4. Terraform Won't Overwrite Values

Future `terraform apply` runs will not modify the secret values you set in the console. Terraform only manages the secret structure and metadata.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the secret | `string` | n/a | yes |
| secret_key_value | Secret schema as key-value pairs (values will be empty, set real values in AWS Console) | `map(string)` | n/a | yes |
| description | Description of the secret | `string` | `"Schema-only secret managed by Terraform"` | no |
| environment | Environment tag for the secret | `string` | `"development"` | no |
| kms_key_id | KMS key ID for encrypting the secret | `string` | `null` | no |
| recovery_window_in_days | Number of days to retain secret after deletion (0-30) | `number` | `30` | no |
| force_overwrite_replica_secret | Whether to overwrite a secret with the same name in the destination region | `bool` | `false` | no |
| version_stages | List of version stages for the secret version | `list(string)` | `["AWSCURRENT"]` | no |
| replica_regions | List of regions to replicate the secret to | `list(object({region = string, kms_key_id = optional(string)}))` | `[]` | no |
| resource_policy | JSON policy document for the secret | `string` | `null` | no |
| enable_rotation | Whether to enable automatic rotation | `bool` | `false` | no |
| rotation_lambda_arn | ARN of the Lambda function for secret rotation | `string` | `null` | no |
| rotation_interval_days | Number of days between automatic rotations | `number` | `30` | no |
| tags | Tags to apply to the secret | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_id | ID of the secret |
| secret_arn | ARN of the secret |
| secret_name | Name of the secret |
| secret_version_id | ID of the secret version |
| secret_schema | List of keys in the secret schema |
| environment | Environment tag value |

## Design Philosophy

This module follows a **schema-only** approach:

- **Terraform manages**: Secret resource, structure (keys), metadata, policies
- **You manage**: Actual secret values through AWS Console
- **Never conflicts**: Terraform will never overwrite values you set manually

### Why Schema-Only?

1. **Security**: Secret values never stored in Terraform state
2. **Simplicity**: No complex value management logic
3. **Flexibility**: Easy to update values without Terraform
4. **Team-friendly**: Different team members can manage values without Terraform access

## Common Patterns

### Application Secrets

```terraform
module "app_secrets" {
  source = "./secret-manager"

  name = "${var.app_name}-${var.environment}-secrets"

  secret_key_value = {
    database_url    = ""
    redis_url      = ""
    jwt_secret     = ""
    encryption_key = ""
  }

  environment = var.environment
  
  tags = {
    Application = var.app_name
    Environment = var.environment
  }
}
```

### Database Credentials

```terraform
module "db_credentials" {
  for_each = var.databases

  source = "./secret-manager"

  name = "${each.key}-database-credentials"

  secret_key_value = {
    username = ""
    password = ""
    host     = ""
    port     = ""
    database = ""
  }

  environment = var.environment
}
```

### Third-Party API Keys

```terraform
module "api_keys" {
  source = "./secret-manager"

  name = "third-party-api-keys"

  secret_key_value = {
    stripe_publishable_key = ""
    stripe_secret_key     = ""
    sendgrid_api_key      = ""
    slack_webhook_url     = ""
    github_token          = ""
  }

  environment = var.environment
}
```

## Best Practices

### Naming Convention

Use consistent naming patterns:
- `{service}-{environment}-{type}`: `myapp-prod-database`
- `{environment}/{service}/{type}`: `prod/myapp/database`

### Secret Structure

Keep related secrets together:
```terraform
# Good: Related database credentials
secret_key_value = {
  username = ""
  password = ""
  host     = ""
  port     = ""
}

# Avoid: Mixing unrelated secrets
secret_key_value = {
  db_password    = ""
  stripe_key     = ""
  random_config  = ""
}
```

### Environment Separation

```terraform
module "prod_secrets" {
  source = "./secret-manager"
  
  name = "myapp-production-secrets"
  environment = "production"
  # ...
}

module "dev_secrets" {
  source = "./secret-manager"
  
  name = "myapp-development-secrets"
  environment = "development"
  # ...
}
```

## Troubleshooting

### Secret Already Exists Error

If you get a "secret already exists" error:

```bash
# Import existing secret
terraform import 'module.my_secret.aws_secretsmanager_secret.this' 'secret-name'
```

### Values Being Reset

If Terraform tries to reset your values:
- Check that you haven't removed the `ignore_changes` in the module
- Ensure you're using the latest version of this module

### Permission Denied

Ensure your AWS credentials have the necessary permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:UpdateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:PutSecretValue",
        "secretsmanager:TagResource"
      ],
      "Resource": "*"
    }
  ]
}
```

## License

This module is released under the MIT License. See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

For issues and questions:
- Create an issue in this repository
- Contact the DevOps team
- Check the AWS Secrets Manager documentation