output "external_ip" {
  value = try(google_compute_instance.jenkins_controller.network_interface[0].access_config[0].nat_ip, null)
}
output "internal_ip" {
  value = google_compute_instance.jenkins_controller.network_interface[0].network_ip
}

output "instance_id" {
  description = "The instance ID"
  value       = google_compute_instance.jenkins_controller.instance_id
}

output "instance_name" {
  description = "The instance name"
  value       = google_compute_instance.jenkins_controller.name
}
