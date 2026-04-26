output "id" {
  description = "An identifier for the resource with format projects/{{project}}/locations/{{location}}/jobs/{{name}}"
  value       = google_cloud_run_v2_job.default.id
}

output "name" {
  description = "The name of the Cloud Run Job."
  value       = google_cloud_run_v2_job.default.name
}

output "location" {
  description = "The location of the Cloud Run Job."
  value       = google_cloud_run_v2_job.default.location
}

output "project_id" {
  description = "The project ID in which the job was created."
  value       = google_cloud_run_v2_job.default.project
}

output "latest_created_execution" {
  description = "Name of the last created execution."
  value       = google_cloud_run_v2_job.default.latest_created_execution
}
