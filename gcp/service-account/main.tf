resource "google_service_account" "sa" {
  account_id   = var.account_id
  display_name = var.display_name != "" ? var.display_name : var.account_id
  description  = var.description
  project      = var.project_id
}

resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_service_account_iam_member" "sa_users" {
  for_each = toset(var.sa_users)

  service_account_id = google_service_account.sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
