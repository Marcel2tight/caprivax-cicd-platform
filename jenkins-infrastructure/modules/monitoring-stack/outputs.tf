output "grafana_ip" {
  value       = google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip
  description = "The public IP address to access the Grafana dashboard"
}

output "grafana_password_secret_path" {
  value       = google_secret_manager_secret.grafana_pw.id
  description = "The GCP Secret Manager path for the Grafana admin password"
}

output "monitoring_internal_ip" {
  value       = google_compute_instance.monitor.network_interface[0].network_ip
  description = "The internal IP of the monitoring host"
}
