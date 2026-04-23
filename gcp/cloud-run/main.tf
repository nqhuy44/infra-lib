resource "google_cloud_run_v2_service" "default" {
  name     = var.name
  location = var.location
  project  = var.project_id
  ingress  = var.ingress_settings
  labels   = var.labels

  template {
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
      image = var.image

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

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }
    }
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
