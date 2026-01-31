resource "google_compute_disk" "additional" {
  for_each = { for disk in var.additional_disks : disk.name => disk }

  name    = "${var.name}-${each.value.name}"
  type    = each.value.type
  size    = each.value.size
  zone    = var.zone
  project = var.project_id
}

resource "google_compute_instance" "default" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = var.tags

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  dynamic "attached_disk" {
    for_each = google_compute_disk.additional
    content {
      source      = attached_disk.value.self_link
      device_name = try(var.additional_disks[index(var.additional_disks.*.name, replace(attached_disk.value.name, "${var.name}-", ""))].device_name, null)
    }
  }

  scheduling {
    preemptible        = var.spot_instance
    automatic_restart  = !var.spot_instance
    provisioning_model = var.spot_instance ? "SPOT" : "STANDARD"
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    stack_type = var.enable_ipv6 ? "IPV4_IPV6" : "IPV4_ONLY"

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        nat_ip = var.static_public_ip
      }
    }

    dynamic "ipv6_access_config" {
      for_each = var.enable_ipv6 ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  metadata = merge(
    var.metadata,
    length(var.ssh_keys) > 0 ? {
      "ssh-keys" = join("\n", [for key in var.ssh_keys : "${key.user}:${key.public_key}"])
    } : {}
  )
  metadata_startup_script = var.metadata_startup_script

  dynamic "service_account" {
    for_each = var.service_account != null ? [var.service_account] : []
    content {
      email  = service_account.value.email
      scopes = service_account.value.scopes
    }
  }
}
