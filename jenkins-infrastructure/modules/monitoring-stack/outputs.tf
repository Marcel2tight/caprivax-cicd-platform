output "monitor_ip" {
  # The Public IP for accessing the UIs (Grafana/Prometheus)
  value       = google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip
  description = "The public IP of the monitoring server"
}

output "monitor_internal_ip" {
  # The Internal IP for secure communication within the VPC
  value       = google_compute_instance.monitor.network_interface[0].network_ip
  description = "The internal IP of the monitoring server"
}

output "grafana_password" {
  # Making the password visible in Jenkins logs for immediate access
  value       = nonsensitive(random_password.grafana_admin.result)
  description = "The auto-generated Grafana admin password"
}

output "grafana_ui_url" {
  value       = "http://${google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip}:3000"
  description = "Link to access the Grafana Dashboard"
}
