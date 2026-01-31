output "network" {
  value       = google_compute_network.network
  description = "The created network"
}

output "subnets" {
  value       = google_compute_subnetwork.subnetwork
  description = "The created subnets"
}

output "network_name" {
  value       = google_compute_network.network.name
  description = "The name of the VPC network"
}

output "network_id" {
  value       = google_compute_network.network.id
  description = "The ID of the VPC network"
}

output "network_self_link" {
  value       = google_compute_network.network.self_link
  description = "The URI of the VPC network"
}
