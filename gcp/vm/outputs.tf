output "instance" {
  value       = google_compute_instance.default
  description = "The created instance resource"
}

output "name" {
  value       = google_compute_instance.default.name
  description = "The name of the instance"
}

output "instance_id" {
  value       = google_compute_instance.default.instance_id
  description = "The server-assigned unique identifier of this instance"
}

output "self_link" {
  value       = google_compute_instance.default.self_link
  description = "The URI of the created resource"
}

output "network_interface" {
  value       = google_compute_instance.default.network_interface
  description = "The network interface of the instance"
}

output "additional_disk_ids" {
  value       = [for disk in google_compute_disk.additional : disk.id]
  description = "The IDs of the additional disks created"
}
