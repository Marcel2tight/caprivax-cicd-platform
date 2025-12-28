output "vpc_link" { value = google_compute_network.vpc.self_link }
output "subnet_link" { value = google_compute_subnetwork.subnet.self_link }
