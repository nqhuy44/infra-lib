output "network" {
  value       = google_compute_network.network
  description = "The created network"
}

output "subnets" {
  value       = google_compute_subnetwork.subnetwork
  description = "The created subnets resources (keyed by region/name)"
}

output "subnets_by_name" {
  value       = { for id, s in google_compute_subnetwork.subnetwork : s.name => s }
  description = "The created subnets resources (keyed by name). Use this if subnet names are unique across regions."
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
