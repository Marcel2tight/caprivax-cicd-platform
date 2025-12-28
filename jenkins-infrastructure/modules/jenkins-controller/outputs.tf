output "internal_ip" {
  value       = google_compute_instance.jenkins.network_interface[0].network_ip
  description = "The internal IP address of the Jenkins controller"
}

output "external_ip" {
  value       = try(google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip, "PRIVATE_ONLY")
  description = "The public IP address of the Jenkins controller (if assigned)"
}

output "instance_self_link" {
  value       = google_compute_instance.jenkins.self_link
  description = "The URI of the created instance"
}
