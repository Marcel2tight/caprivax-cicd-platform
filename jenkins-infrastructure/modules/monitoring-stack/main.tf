# Generate a random password for Grafana Admin
resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

# Store the password in Secret Manager for safe retrieval
resource "google_secret_manager_secret" "grafana_pw" {
  project   = var.project_id
  secret_id = "${var.naming_prefix}-grafana-password"

  replication {
    auto {} # Modern syntax for automatic replication
  }
}

resource "google_secret_manager_secret_version" "v1" {
  secret      = google_secret_manager_secret.grafana_pw.id
  secret_data = random_password.grafana_admin.result
}

# Monitoring Instance (Prometheus & Grafana)
resource "google_compute_instance" "monitor" {
  name         = "${var.naming_prefix}-monitor"
  machine_type = "e2-medium"
  zone         = var.zone
  project      = var.project_id
  tags         = ["monitoring-stack"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
  }

  network_interface {
    network    = var.network_link
    subnetwork = var.subnetwork_link
    access_config {
      # Public IP for accessing Grafana dashboards
    }
  }

  # Necessary for accessing other GCP APIs if needed
  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -e
    
    # Install Docker and Docker Compose
    apt-get update
    apt-get install -y docker.io docker-compose
    
    mkdir -p /opt/mon/provisioning/datasources
    cd /opt/mon

    # Configure Prometheus to scrape Jenkins
    cat > prometheus.yml <<P_EOF
scrape_configs:
  - job_name: 'jenkins'
    metrics_path: '/prometheus/'
    static_configs:
      - targets: ['${var.jenkins_ip}:8080']
P_EOF

    # Auto-provision Prometheus as a data source in Grafana
    cat > provisioning/datasources/ds.yml <<G_EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
G_EOF

    # Define the stack
    cat > docker-compose.yml <<D_EOF
version: '3'
services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    restart: always

  grafana:
    image: grafana/grafana
    container_name: grafana
    volumes:
      - ./provisioning:/etc/grafana/provisioning
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${random_password.grafana_admin.result}
    restart: always
D_EOF

    docker-compose up -d
  SCRIPT
}

# Ensure the firewall rule exists to allow access to UI ports
resource "google_compute_firewall" "monitoring_ui" {
  name    = "${var.naming_prefix}-allow-monitoring-ui"
  network = var.network_link
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["3000", "9090"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["monitoring-stack"]
}
