resource "google_cloud_run_v2_job" "default" {
  name     = var.name
  location = var.location
  project  = var.project_id
  labels   = var.labels

  template {
    labels      = var.labels
    task_count  = var.task_count
    parallelism = var.parallelism

    template {
      timeout               = var.timeout
      execution_environment = var.execution_environment
      service_account       = var.service_account_email

      dynamic "vpc_access" {
        for_each = var.vpc_connector != null ? [1] : []
        content {
          connector = var.vpc_connector
          egress    = var.egress_settings
        }
      }

      containers {
        image   = var.image
        command = length(var.command) > 0 ? var.command : null
        args    = length(var.args) > 0 ? var.args : null

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = var.secret_vars
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value
                version = "latest"
              }
            }
          }
        }

        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].template[0].containers[0].image,
    ]
  }
}
