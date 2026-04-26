# Create a dedicated Service Account if one is not provided
resource "google_service_account" "scheduler_sa" {
  count        = var.service_account_email == null ? 1 : 0
  project      = var.project_id
  account_id   = "${var.name}-sa"
  display_name = "Cloud Scheduler SA for ${var.name}"
}

# Grant run.invoker role to the Service Account
resource "google_project_iam_member" "scheduler_invoker" {
  count   = var.service_account_email == null ? 1 : 0
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}

locals {
  sa_email = var.service_account_email != null ? var.service_account_email : google_service_account.scheduler_sa[0].email
  
  # Endpoint to trigger a Cloud Run Job
  job_uri = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.target_job_name}:run"
}

resource "google_cloud_scheduler_job" "default" {
  name        = var.name
  project     = var.project_id
  region      = var.region
  description = var.description
  schedule    = var.schedule
  time_zone   = var.time_zone

  http_target {
    http_method = "POST"
    uri         = local.job_uri

    oauth_token {
      service_account_email = local.sa_email
    }
  }

  depends_on = [
    google_project_iam_member.scheduler_invoker
  ]
}
