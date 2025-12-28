output "vpc_name" {
  value       = google_compute_network.vpc.name
  description = "The name of the VPC"
}

output "vpc_link" {
  value       = google_compute_network.vpc.self_link
  description = "The URI (self_link) of the VPC"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "The name of the created subnetwork"
}

output "subnet_link" {
  value       = google_compute_subnetwork.subnet.self_link
  description = "The URI (self_link) of the subnetwork"
}
