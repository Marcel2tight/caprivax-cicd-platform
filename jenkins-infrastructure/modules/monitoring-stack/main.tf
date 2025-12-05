resource "google_compute_instance" "monitor" {
  name         = "${var.naming_prefix}-monitor"
  machine_type = "e2-medium"
  zone         = var.zone
  project      = var.project_id
  tags         = ["monitoring-stack", "ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link
    access_config {} # Public IP
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Install Docker
    apt-get update
    apt-get install -y docker.io docker-compose
    
    # Create Directories
    mkdir -p /opt/monitoring
    cd /opt/monitoring

    # Create Prometheus Config (Scraping Jenkins)
    cat > prometheus.yml <<INNER_EOF
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'jenkins'
        metrics_path: '/prometheus/'
        static_configs:
          - targets: ['${var.jenkins_internal_ip}:8080']
    INNER_EOF

    # Create Docker Compose
    cat > docker-compose.yml <<INNER_EOF
    version: '3'
    services:
      prometheus:
        image: prom/prometheus:latest
        volumes:
          - ./prometheus.yml:/etc/prometheus/prometheus.yml
        ports:
          - "9090:9090"
      grafana:
        image: grafana/grafana:latest
        ports:
          - "3000:3000"
    INNER_EOF

    # Start Stack
    docker-compose up -d
  EOT
}
