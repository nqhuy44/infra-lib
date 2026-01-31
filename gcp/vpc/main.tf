resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  project                 = var.project_id
  mtu                     = var.mtu == 0 ? null : var.mtu
}

resource "google_compute_subnetwork" "subnetwork" {
  for_each = {
    for x in var.subnets : "${x.subnet_region}/${x.subnet_name}" => x
  }

  name                     = each.value.subnet_name
  ip_cidr_range            = each.value.subnet_ip
  region                   = each.value.subnet_region
  private_ip_google_access = each.value.subnet_private_access
  network                  = google_compute_network.network.id
  project                  = var.project_id
  description              = each.value.description

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_range
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
      metadata_fields      = log_config.value.metadata_fields
      filter_expr          = log_config.value.filter_expr
    }
  }
}
