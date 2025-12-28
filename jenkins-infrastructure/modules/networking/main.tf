# 1. Create the Custom VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.naming_prefix}-vpc"
  auto_create_subnetworks = false # Best practice for production
  project                 = var.project_id
}

# 2. Create the Regional Subnetwork
resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.naming_prefix}-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.self_link
  project                  = var.project_id
  
  # Allows private VMs to reach Google APIs (Secret Manager, GCS, etc.)
  private_ip_google_access = true
}

# 3. Security: Allow IAP Tunneling (SSH)
resource "google_compute_firewall" "allow_iap" {
  name    = "${var.naming_prefix}-fw-allow-iap"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Official Google IAP netblock
  source_ranges = ["35.235.240.0/20"]
}

# 4. Security: Allow Web/Service Traffic
resource "google_compute_firewall" "allow_web" {
  name    = "${var.naming_prefix}-fw-allow-web"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "3000", "9090"] # Jenkins, Grafana, Prometheus
  }

  source_ranges = var.allowed_web_ranges
}
