# Networking Module for Jenkins CI/CD Platform
resource "google_compute_network" "jenkins_vpc" {
  name                    = "${var.naming_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id

  delete_default_routes_on_create = false

  labels = merge(var.custom_labels, {
    purpose = "jenkins-cicd"
  })
}

resource "google_compute_subnetwork" "jenkins_subnet" {
  name          = "${var.naming_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.jenkins_vpc.name
  project       = var.project_id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }

  labels = merge(var.custom_labels, {
    purpose = "jenkins-cicd"
  })
}

# Firewall rule for SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.naming_prefix}-allow-ssh"
  network = google_compute_network.jenkins_vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ips
  target_tags   = ["ssh-enabled"]

  labels = merge(var.custom_labels, {
    purpose = "ssh-access"
  })
}

# Firewall rule for Jenkins web interface
resource "google_compute_firewall" "allow_jenkins_web" {
  name    = "${var.naming_prefix}-allow-jenkins-web"
  network = google_compute_network.jenkins_vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "80", "443"]
  }

  source_ranges = var.allowed_web_ips
  target_tags   = ["jenkins-web"]

  labels = merge(var.custom_labels, {
    purpose = "jenkins-web-access"
  })
}

# Firewall rule for internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.naming_prefix}-allow-internal"
  network = google_compute_network.jenkins_vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["internal-communication"]

  labels = merge(var.custom_labels, {
    purpose = "internal-comms"
  })
}
