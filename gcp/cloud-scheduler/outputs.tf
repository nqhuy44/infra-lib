output "id" {
  description = "An identifier for the resource."
  value       = google_cloud_scheduler_job.default.id
}

output "name" {
  description = "The name of the Cloud Scheduler job."
  value       = google_cloud_scheduler_job.default.name
}

output "service_account_email" {
  description = "The service account email used to trigger the job."
  value       = local.sa_email
}
