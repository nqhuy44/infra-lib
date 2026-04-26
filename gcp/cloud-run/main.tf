resource "google_cloud_run_v2_service" "default" {
  name     = var.name
  location = var.location
  project  = var.project_id
  ingress  = var.ingress_settings
  labels   = var.labels

  template {
    labels                           = var.labels
    max_instance_request_concurrency = var.max_instance_request_concurrency

    scaling {
      max_instance_count = var.max_instance_count
      min_instance_count = var.min_instance_count
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector != null ? [1] : []
      content {
        connector = var.vpc_connector
        egress    = var.egress_settings
      }
    }

    service_account = var.service_account_email

    containers {
      image   = var.image
      command = length(var.command) > 0 ? var.command : null
      args    = length(var.args) > 0 ? var.args : null

      ports {
        container_port = var.container_port
      }

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
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }
    }
  }

  # Optional: Ignore changes to the image if it's managed by an external CI/CD pipeline.
  # Terraform doesn't support variables in `ignore_changes`, so this is statically defined.
  # Remove `template[0].containers[0].image` if you want Terraform to manage image versions.
  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].containers[0].image,
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "noauth" {
  count    = var.allow_unauthenticated_access ? 1 : 0
  project  = google_cloud_run_v2_service.default.project
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
