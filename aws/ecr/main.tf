######################
# ECR Repository
######################
resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_id
  }

  # Removed deprecated image_scanning_configuration block
  # Scanning is now controlled at the registry level

  tags = merge(
    {
      Name = var.repository_name
    },
    var.tags
  )
}

######################
# ECR Repository Policy
######################
resource "aws_ecr_repository_policy" "this" {
  count      = var.repository_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy
}

######################
# ECR Lifecycle Policy
######################
resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}

######################
# ECR Registry Scanning Configuration (for all repositories)
######################
resource "aws_ecr_registry_scanning_configuration" "this" {
  count = var.create_registry_scan_config ? 1 : 0

  scan_type = var.registry_scan_type

  dynamic "rule" {
    for_each = var.registry_scan_rules
    content {
      scan_frequency = rule.value.scan_frequency
      dynamic "repository_filter" {
        for_each = rule.value.filters
        content {
          filter      = repository_filter.value.filter
          filter_type = repository_filter.value.filter_type
        }
      }
    }
  }
}

######################
# ECR Pull Through Cache Rule
######################
resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each              = var.pull_through_cache_rules
  ecr_repository_prefix = each.value.ecr_repository_prefix
  upstream_registry_url = each.value.upstream_registry_url
  credential_arn        = lookup(each.value, "credential_arn", null)
}
