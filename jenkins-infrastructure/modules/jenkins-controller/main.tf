locals {
  naming_prefix = var.naming_prefix
}

resource "google_compute_instance" "jenkins_controller" {
  name         = "${local.naming_prefix}-controller"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = var.instance_tags

  # Scheduling Block (The fix for Preemptible errors)
  scheduling {
    automatic_restart   = var.automatic_restart
    preemptible         = var.enable_preemptible
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.boot_disk_size
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link
    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {}
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}
