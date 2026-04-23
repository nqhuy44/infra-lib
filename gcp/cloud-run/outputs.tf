output "uri" {
  description = "The URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.uri
}

output "name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.name
}

output "location" {
  description = "The location of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.location
}

output "project_id" {
  description = "The project ID in which the service was created."
  value       = google_cloud_run_v2_service.default.project
}

output "latest_ready_revision" {
  description = "The latest ready revision name of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.latest_ready_revision
}
