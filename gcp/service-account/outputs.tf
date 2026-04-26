output "email" {
  description = "The e-mail address of the service account."
  value       = google_service_account.sa.email
}

output "name" {
  description = "The fully-qualified name of the service account."
  value       = google_service_account.sa.name
}

output "unique_id" {
  description = "The unique id of the service account."
  value       = google_service_account.sa.unique_id
}
