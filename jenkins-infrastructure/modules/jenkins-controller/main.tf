# Jenkins Controller Module
resource "google_compute_instance" "jenkins_controller" {
  name         = "${var.naming_prefix}-controller"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["jenkins-controller", "ssh-enabled", "jenkins-web"]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        network_tier = "STANDARD"
      }
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
    project_id     = var.project_id
    environment    = var.environment
  }

  metadata_startup_script = templatefile("${path.module}/scripts/jenkins-startup.sh", {
    project_id  = var.project_id
    environment = var.environment
  })

  service_account {
    email  = var.service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = var.environment == "dev" ? true : false
  }

  labels = merge(var.custom_labels, {
    role        = "jenkins-controller"
    environment = var.environment
  })

  depends_on = [var.dependencies]
}

# Reserve static IP if enabled
resource "google_compute_address" "jenkins_static_ip" {
  count = var.enable_public_ip && var.reserve_static_ip ? 1 : 0

  name    = "${var.naming_prefix}-static-ip"
  region  = var.region
  project = var.project_id

  labels = merge(var.custom_labels, {
    purpose = "jenkins-controller"
  })
}
