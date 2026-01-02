# 1. Generate a password WITHOUT characters that break shell/YAML ($ and /)
resource "random_password" "grafana_admin" {
  length           = 16
  special          = true
  # Explicitly excluding '$' to prevent Docker Compose interpolation errors
  override_special = "!#%&*()-_=+[]{}<>:?" 
}

# 2. Store the password in Secret Manager
resource "google_secret_manager_secret" "grafana_pw" {
  project   = var.project_id
  secret_id = "${var.naming_prefix}-grafana-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "v1" {
  secret      = google_secret_manager_secret.grafana_pw.id
  secret_data = random_password.grafana_admin.result
}

# 3. Monitoring Instance
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
    access_config {}
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y docker.io docker-compose
    
    mkdir -p /opt/mon/provisioning/datasources
    cd /opt/mon

    # Prometheus Config
    cat > prometheus.yml <<P_EOF
scrape_configs:
  - job_name: 'jenkins'
    metrics_path: '/prometheus/'
    static_configs:
      - targets: ['${var.jenkins_ip}:8080']
P_EOF

    # Grafana Datasource Config
    cat > provisioning/datasources/ds.yml <<G_EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
G_EOF

    # Docker Compose Stack
    # Using single quotes around the password for shell safety
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
      - 'GF_SECURITY_ADMIN_PASSWORD=${random_password.grafana_admin.result}'
    restart: always
D_EOF

    docker-compose up -d
  SCRIPT
}

# 4. Firewall Rule
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
