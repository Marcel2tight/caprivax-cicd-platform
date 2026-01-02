output "public_ip" {
  # try() prevents "Invalid Index" errors if the network is still provisioning
  value       = try(google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip, "Pending")
  description = "The public IP of the bastion host"
}
