resource "google_compute_network" "vpc" {
  name = "${var.naming_prefix}-vpc"
  auto_create_subnetworks = false
  project = var.project_id
}
resource "google_compute_subnetwork" "subnet" {
  name = "${var.naming_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  region = var.region
  network = google_compute_network.vpc.self_link
  project = var.project_id
  private_ip_google_access = true
}
resource "google_compute_firewall" "allow_iap" {
  name = "${var.naming_prefix}-fw-allow-iap"
  network = google_compute_network.vpc.name
  project = var.project_id
  allow { protocol = "tcp"; ports = ["22"] }
  source_ranges = ["35.235.240.0/20"]
}
resource "google_compute_firewall" "allow_web" {
  name = "${var.naming_prefix}-fw-allow-web"
  network = google_compute_network.vpc.name
  project = var.project_id
  allow { protocol = "tcp"; ports = ["8080", "3000", "9090"] }
  source_ranges = var.allowed_web_ranges
}
