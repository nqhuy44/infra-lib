# --- Local variables ---
locals {
  # Tags
  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
      Terraform   = "true"
    }
  )

  # Determine if we have any secret content to create
  has_key_value = length(var.secret_key_value) > 0
  has_string    = var.secret_string != null && var.secret_string != ""
  has_binary    = var.secret_binary != null && var.secret_binary != ""
  has_content   = local.has_key_value || local.has_string || local.has_binary

  # Process secret content - ensure we always have a string if creating version
  processed_secret_string = local.has_key_value ? jsonencode(var.secret_key_value) : var.secret_string
}

# --- Secret resource ---
resource "aws_secretsmanager_secret" "this" {
  name                           = var.name
  description                    = var.description
  kms_key_id                     = var.kms_key_id
  recovery_window_in_days        = var.recovery_window_in_days
  force_overwrite_replica_secret = var.force_overwrite_replica_secret

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region     = replica.value.region
      kms_key_id = lookup(replica.value, "kms_key_id", null)
    }
  }

  tags = local.tags
}

# --- Secret version (only if content provided) ---
resource "aws_secretsmanager_secret_version" "this" {
  count = local.has_content ? 1 : 0

  secret_id = aws_secretsmanager_secret.this.id

  # Ensure we always provide either secret_string OR secret_binary, never both null
  secret_string = var.secret_binary == null ? local.processed_secret_string : null
  secret_binary = var.secret_binary != null ? var.secret_binary : null

  version_stages = var.version_stages

  # Ignore changes to secret content after creation
  lifecycle {
    ignore_changes = [
      secret_string,
      secret_binary,
      version_stages
    ]
  }

  depends_on = [aws_secretsmanager_secret.this]
}

# --- Secret policy ---
resource "aws_secretsmanager_secret_policy" "this" {
  count = var.resource_policy != null ? 1 : 0

  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = var.resource_policy

  depends_on = [aws_secretsmanager_secret.this]
}

# --- Automatic rotation ---
resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.enable_rotation && var.rotation_lambda_arn != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_interval_days
  }

  depends_on = [aws_secretsmanager_secret_version.this]
}