# Create the compute instance
resource "google_compute_instance" "vm" {
  project      = var.project_id
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  
  tags = concat(var.tags, ["ssh-enabled", "http-server", "https-server"])
  
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
    
    # Conditionally assign public IP
    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        network_tier = "STANDARD"
      }
    }
  }

  metadata = {
    enable-oslogin    = "TRUE"
    enable-monitoring = "TRUE"
    environment       = var.environment
    created-by        = "terraform"
  }

  # Startup script for automated software installation
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF

  # FinOps Label Merging
  labels = merge(var.labels, {
    "env" = var.environment
  })
}

# UNIVERSAL IAP ACCESS FIREWALL
resource "google_compute_firewall" "iap_ssh" {
  project = var.project_id
  name    = "${var.vm_name}-iap-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Official Google IAP netblock
  source_ranges = ["35.235.240.0/20"] 
  target_tags   = ["ssh-enabled"]
}

# Allow IAP to reach Nginx on Port 80
resource "google_compute_firewall" "iap_http" {
  project = var.project_id
  name    = "${var.vm_name}-iap-http"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # The same IAP netblock
  source_ranges = ["35.235.240.0/20"] 
  target_tags   = ["http-server"]
}