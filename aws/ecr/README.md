# AWS ECR (Elastic Container Registry) Module
This Terraform module creates and manages an AWS Elastic Container Registry (ECR) repository with support for repository policies, lifecycle policies, scanning configurations, and pull-through cache rules.

## Usage
```hcl
module "ecr_repository" {
  source = "../../modules/ecr"

  repository_name       = "my-application"
  image_tag_mutability  = "IMMUTABLE"
  
  # Enable encryption
  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.ecr.arn
  
  # Define lifecycle policy
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only 10 images",
        selection = {
          tagStatus     = "any",
          countType     = "imageCountMoreThan",
          countNumber   = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  tags = {
    Environment = "production"
    Application = "my-app"
  }
}
```

## Input Variables
| Name                 | Description                                                                 | Type   | Default   | Required |
| -------------------- | --------------------------------------------------------------------------- | ------ | --------- | -------- |
| repository_name      | Name of the ECR repository                                                  | string | n/a       | yes      |
| image_tag_mutability | Image tag mutability setting. Must be one of: MUTABLE or IMMUTABLE          | string | "MUTABLE" | no       |
| encryption_type      | Encryption type for the repository. Must be one of: AES256 or KMS           | string | "AES256"  | no       |
| kms_key_id           | ARN of the KMS key to use for encryption. Required if encryption_type = KMS | string | null      | no       |
| repository_policy    | JSON policy document to apply to the ECR repository                         | string | null      | no       |
| lifecycle_policy     | JSON lifecycle policy document to apply to the ECR repository               | string | null      | no       |

Registry Scanning Configuration
| Name                        | Description                                           | Type         | Default | Required |
| --------------------------- | ----------------------------------------------------- | ------------ | ------- | -------- |
| create_registry_scan_config | Whether to create registry scanning configuration     | bool         | false   | no       |
| registry_scan_type          | Registry scan type. Must be one of: BASIC or ENHANCED | string       | "BASIC" | no       |
| registry_scan_rules         | List of scan rules for the registry                   | list(object) | []      | no       |

Pull Through Cache Configuration
| Name                     | Description                                    | Type        | Default | Required |
| ------------------------ | ---------------------------------------------- | ----------- | ------- | -------- |
| pull_through_cache_rules | Map of pull through cache rules configurations | map(object) | {}      | no       |

Tags
| Name | Description                            | Type        | Default | Required |
| ---- | -------------------------------------- | ----------- | ------- | -------- |
| tags | A map of tags to add to the repository | map(string) | {}      | no       |

## Outputs
| Name                   | Description                           |
| ---------------------- | ------------------------------------- |
| repository_url         | The URL of the ECR repository         |
| repository_arn         | The ARN of the ECR repository         |
| repository_name        | The name of the ECR repository        |
| repository_registry_id | The registry ID of the ECR repository |

## Examples
Basic Repository
```hcl
module "basic_ecr" {
  source = "../../modules/ecr"

  repository_name = "my-app"
  
  tags = {
    Environment = "development"
  }
}
```

Immutable Repository with KMS Encryption
```hcl
module "secure_ecr" {
  source = "../../modules/ecr"

  repository_name      = "secure-app"
  image_tag_mutability = "IMMUTABLE"
  
  # Enable KMS encryption
  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.ecr.arn
  
  tags = {
    Environment = "production"
    Security    = "high"
  }
}
```

Repository with Lifecycle Policy
```hcl
module "ecr_with_lifecycle" {
  source = "../../modules/ecr"

  repository_name = "api-service"
  
  # Define lifecycle policy
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only tagged images",
        selection = {
          tagStatus     = "untagged",
          countType     = "sinceImagePushed",
          countUnit     = "days",
          countNumber   = 1
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep last 30 production images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["prod"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  tags = {
    Environment = "production"
    Service     = "api"
  }
}
```

Repository with Cross-Account Access Policy
```hcl
module "shared_ecr" {
  source = "../../modules/ecr"

  repository_name = "shared-base-image"
  
  # Define cross-account access policy
  repository_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCrossAccountPull",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::111122223333:root",
            "arn:aws:iam::444455556666:root"
          ]
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
  
  tags = {
    Environment = "shared"
    Purpose     = "cross-account-images"
  }
}
```

Repository with Enhanced Scanning
```hcl
module "scanned_ecr" {
  source = "../../modules/ecr"

  repository_name = "scanned-app"
  
  # Enable enhanced scanning
  create_registry_scan_config = true
  registry_scan_type          = "ENHANCED"
  
  registry_scan_rules = [
    {
      scan_frequency = "CONTINUOUS_SCAN"
      filters = [
        {
          filter      = "scanned-app"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]
  
  tags = {
    Environment = "production"
    Security    = "enhanced"
  }
}
```

Repository with Pull-Through Cache for Public Registries
```hcl
module "cached_ecr" {
  source = "../../modules/ecr"

  repository_name = "cached-images"
  
  # Configure pull-through cache for Docker Hub
  pull_through_cache_rules = {
    dockerhub = {
      ecr_repository_prefix = "docker-hub"
      upstream_registry_url = "public.ecr.aws/docker/library"
    }
  }
  
  tags = {
    Environment = "production"
    Purpose     = "cached-public-images"
  }
}
```