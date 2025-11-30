output "vpc_name" {
  description = "Name of the created VPC"
  value       = google_compute_network.jenkins_vpc.name
}

output "vpc_self_link" {
  description = "Self link of the created VPC"
  value       = google_compute_network.jenkins_vpc.self_link
}

output "subnet_name" {
  description = "Name of the created subnet"
  value       = google_compute_subnetwork.jenkins_subnet.name
}

output "subnet_self_link" {
  description = "Self link of the created subnet"
  value       = google_compute_subnetwork.jenkins_subnet.self_link
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.jenkins_subnet.ip_cidr_range
}

output "firewall_rules" {
  description = "Names of created firewall rules"
  value = {
    ssh   = google_compute_firewall.allow_ssh.name
    web   = google_compute_firewall.allow_jenkins_web.name
    internal = google_compute_firewall.allow_internal.name
  }
}
