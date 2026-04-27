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
      max_retries           = var.max_retries
      execution_environment = var.execution_environment
      service_account       = var.service_account_email

      dynamic "vpc_access" {
        for_each = var.vpc_connector != null ? [1] : []
        content {
          connector = var.vpc_connector
          egress    = var.egress_settings
        }
      }

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
