output "secret_ids" {
  description = "A list of the created secret IDs."
  value       = [for secret in google_secret_manager_secret.secrets : secret.secret_id]
}

output "secret_names" {
  description = "A map of secret keys to their fully qualified resource names."
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.name }
}

output "secret_version_names" {
  description = "A map of secret keys to their fully qualified secret version resource names."
  value       = { for k, v in google_secret_manager_secret_version.versions : k => v.name }
}
