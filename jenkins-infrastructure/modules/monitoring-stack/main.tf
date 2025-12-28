resource "random_password" "grafana_admin" { length = 16; special = true }
resource "google_secret_manager_secret" "grafana_pw" {
  project = var.project_id
  secret_id = "${var.naming_prefix}-grafana-password"
  replication { automatic = true }
}
resource "google_secret_manager_secret_version" "v1" {
  secret = google_secret_manager_secret.grafana_pw.id
  secret_data = random_password.grafana_admin.result
}
resource "google_compute_instance" "monitor" {
  name = "${var.naming_prefix}-monitor"
  machine_type = "e2-medium"
  zone = var.zone
  project = var.project_id
  boot_disk { initialize_params { image = "debian-cloud/debian-11"; size = 50 } }
  network_interface { network = var.network_link; subnetwork = var.subnetwork_link; access_config {} }
  service_account { email = var.service_account_email; scopes = ["cloud-platform"] }
  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update && apt-get install -y docker.io docker-compose
    mkdir -p /opt/mon/provisioning/datasources && cd /opt/mon
    cat > prometheus.yml <<P_EOF
    scrape_configs:
      - job_name: 'jenkins'
        metrics_path: '/prometheus/'
        static_configs:
          - targets: ['${var.jenkins_ip}:8080']
    P_EOF

    cat > provisioning/datasources/ds.yml <<G_EOF
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus:9090
        isDefault: true
    G_EOF

    cat > docker-compose.yml <<D_EOF
    version: '3'
    services:
      prometheus:
        image: prom/prometheus
        volumes: ["./prometheus.yml:/etc/prometheus/prometheus.yml"]
        ports: ["9090:9090"]
      grafana:
        image: grafana/grafana
        volumes: ["./provisioning:/etc/grafana/provisioning"]
        ports: ["3000:3000"]
        environment:
          - GF_SECURITY_ADMIN_PASSWORD=${random_password.grafana_admin.result}
    D_EOF
    docker-compose up -d
  SCRIPT
}
