output "monitor_ip" {
  value       = google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip
  description = "The public IP of the monitoring server"
}

output "grafana_password" {
  value       = nonsensitive(random_password.grafana_admin.result)
  description = "The auto-generated Grafana admin password"
}

output "grafana_ui_url" {
  value       = "http://${google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip}:3000"
  description = "Link to access the Grafana Dashboard"
}
