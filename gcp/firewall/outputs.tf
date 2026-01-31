output "firewall_rule" {
  value       = google_compute_firewall.default
  description = "The created firewall rule resource"
}

output "name" {
  value       = google_compute_firewall.default.name
  description = "The name of the firewall rule"
}

output "self_link" {
  value       = google_compute_firewall.default.self_link
  description = "The URI of the firewall rule"
}
