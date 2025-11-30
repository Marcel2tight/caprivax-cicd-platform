output "instance_name" {
  description = "Name of the Jenkins controller instance"
  value       = google_compute_instance.jenkins_controller.name
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.jenkins_controller.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP address"
  value       = var.enable_public_ip ? google_compute_instance.jenkins_controller.network_interface[0].access_config[0].nat_ip : null
}

output "static_ip" {
  description = "Static IP address if reserved"
  value       = var.enable_public_ip && var.reserve_static_ip ? google_compute_address.jenkins_static_ip[0].address : null
}

output "zone" {
  description = "Zone of the instance"
  value       = google_compute_instance.jenkins_controller.zone
}

output "self_link" {
  description = "Self link of the instance"
  value       = google_compute_instance.jenkins_controller.self_link
}

output "ssh_command" {
  description = "SSH command to connect to Jenkins"
  value       = "gcloud compute ssh ${google_compute_instance.jenkins_controller.name} --zone=${var.zone} --project=${var.project_id}"
}

output "web_url" {
  description = "Web URL for Jenkins"
  value       = var.enable_public_ip ? "http://${google_compute_instance.jenkins_controller.network_interface[0].access_config[0].nat_ip}:8080" : null
}

output "initial_admin_password_command" {
  description = "Command to get initial admin password"
  value       = "gcloud compute ssh ${google_compute_instance.jenkins_controller.name} --zone=${var.zone} --project=${var.project_id} --command='sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}
