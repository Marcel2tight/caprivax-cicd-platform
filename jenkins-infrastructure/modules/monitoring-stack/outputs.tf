output "monitor_ip" {
  # References the 'monitor' resource name you found via grep
  value       = google_compute_instance.monitor.network_interface[0].access_config[0].nat_ip
  description = "The public IP of the monitoring server"
}

output "monitor_internal_ip" {
  value       = google_compute_instance.monitor.network_interface[0].network_ip
  description = "The internal IP of the monitoring server"
}
