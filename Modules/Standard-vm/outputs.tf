output "vm_name" {
  description = "The name of the VM instance"
  value       = google_compute_instance.vm.name
}

output "internal_ip" {
  description = "The internal IP of the VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "external_ip" {
  description = "The external IP of the VM (if it exists)"
  value       = length(google_compute_instance.vm.network_interface[0].access_config) > 0 ? google_compute_instance.vm.network_interface[0].access_config[0].nat_ip : "PRIVATE"
}

output "ssh_iap_command" {
  description = "The command to connect via IAP tunnel"
  value       = "gcloud compute ssh ${google_compute_instance.vm.name} --project=${var.project_id} --zone=${var.zone} --tunnel-through-iap"
}