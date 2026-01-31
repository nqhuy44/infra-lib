resource "google_compute_firewall" "default" {
  name        = var.name
  network     = var.network
  project     = var.project_id
  description = var.description
  priority    = var.priority

  dynamic "allow" {
    for_each = var.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = var.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  source_ranges = length(var.source_ranges) > 0 ? var.source_ranges : null
  source_tags   = length(var.source_tags) > 0 ? var.source_tags : null
  target_tags   = length(var.target_tags) > 0 ? var.target_tags : null
}
