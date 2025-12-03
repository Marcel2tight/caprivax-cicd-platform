output "vpc_self_link" { value = google_compute_network.jenkins_vpc.self_link }
output "subnet_self_link" { value = google_compute_subnetwork.jenkins_subnet.self_link }
