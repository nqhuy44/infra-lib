resource "google_secret_manager_secret" "secrets" {
  for_each  = var.secrets
  project   = var.project_id
  secret_id = each.key

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "versions" {
  for_each = var.secrets

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value

  lifecycle {
    ignore_changes = [
      secret_data,
    ]
  }
}

locals {
  secret_accessors = flatten([
    for secret_id, val in var.secrets : [
      for accessor in var.accessors : {
        secret_id = secret_id
        member    = accessor
      }
    ]
  ])
}

resource "google_secret_manager_secret_iam_member" "accessors" {
  for_each = {
    for sa in local.secret_accessors : "${sa.secret_id}-${sa.member}" => sa
  }

  project   = google_secret_manager_secret.secrets[each.value.secret_id].project
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}
