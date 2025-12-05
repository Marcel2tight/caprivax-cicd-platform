output "grafana_url" {
  value = "http://${google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip}:3000"
}
output "prometheus_url" {
  value = "http://${google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip}:9090"
}
