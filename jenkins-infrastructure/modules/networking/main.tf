resource "google_compute_network" "jenkins_vpc" {
  name                    = "${var.naming_prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "jenkins_subnet" {
  name                     = "${var.naming_prefix}-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.jenkins_vpc.self_link
  project                  = var.project_id
  private_ip_google_access = true
}

# Allow SSH (Port 22)
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
}

# Allow Jenkins Web (Port 8080)
resource "google_compute_firewall" "allow_jenkins_web" {
  name    = "${var.naming_prefix}-allow-jenkins-web"
  network = google_compute_network.jenkins_vpc.name
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = var.allowed_web_ips
  target_tags   = ["jenkins-web"]
}

# NEW: Allow Monitoring Stack (3000/9090)
resource "google_compute_firewall" "allow_monitoring" {
  name    = "${var.naming_prefix}-allow-monitoring"
  network = google_compute_network.jenkins_vpc.name
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["9090", "3000"]
  }
  source_ranges = var.allowed_web_ips
  target_tags   = ["monitoring-stack"]
}
