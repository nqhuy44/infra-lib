resource "google_cloud_run_v2_service" "default" {
  name     = var.name
  location = var.location
  project  = var.project_id
  ingress  = var.ingress_settings
  labels   = var.labels

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = var.traffic_percent
  }

  template {
    labels                           = var.labels
    max_instance_request_concurrency = var.max_instance_request_concurrency
    timeout                          = var.request_timeout
    execution_environment            = var.execution_environment

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

    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value.name

        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []
          content {
            medium     = empty_dir.value.medium
            size_limit = empty_dir.value.size_limit
          }
        }

        dynamic "secret" {
          for_each = volumes.value.secret != null ? [volumes.value.secret] : []
          content {
            secret       = secret.value.secret
            default_mode = secret.value.default_mode
            
            dynamic "items" {
              for_each = secret.value.items != null ? secret.value.items : []
              content {
                path    = items.value.path
                version = items.value.version
                mode    = items.value.mode
              }
            }
          }
        }

        dynamic "cloud_sql_instance" {
          for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []
          content {
            instances = cloud_sql_instance.value.instances
          }
        }

        dynamic "gcs" {
          for_each = volumes.value.gcs != null ? [volumes.value.gcs] : []
          content {
            bucket    = gcs.value.bucket
            read_only = gcs.value.read_only
          }
        }

        dynamic "nfs" {
          for_each = volumes.value.nfs != null ? [volumes.value.nfs] : []
          content {
            server    = nfs.value.server
            path      = nfs.value.path
            read_only = nfs.value.read_only
          }
        }
      }
    }

    containers {
      image   = var.image
      command = length(var.command) > 0 ? var.command : null
      args    = length(var.args) > 0 ? var.args : null

      dynamic "volume_mounts" {
        for_each = var.volume_mounts
        content {
          name       = volume_mounts.value.name
          mount_path = volume_mounts.value.mount_path
        }
      }

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

      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          timeout_seconds       = liveness_probe.value.timeout_seconds
          period_seconds        = liveness_probe.value.period_seconds
          failure_threshold     = liveness_probe.value.failure_threshold

          dynamic "http_get" {
            for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = http_get.value.port
            }
          }

          dynamic "tcp_socket" {
            for_each = liveness_probe.value.tcp_socket != null ? [liveness_probe.value.tcp_socket] : []
            content {
              port = tcp_socket.value.port
            }
          }
        }
      }

      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        content {
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          timeout_seconds       = startup_probe.value.timeout_seconds
          period_seconds        = startup_probe.value.period_seconds
          failure_threshold     = startup_probe.value.failure_threshold

          dynamic "http_get" {
            for_each = startup_probe.value.http_get != null ? [startup_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = http_get.value.port
            }
          }

          dynamic "tcp_socket" {
            for_each = startup_probe.value.tcp_socket != null ? [startup_probe.value.tcp_socket] : []
            content {
              port = tcp_socket.value.port
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
