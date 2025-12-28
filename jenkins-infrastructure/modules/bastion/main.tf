resource "google_compute_instance" "bastion" {
  name = "${var.naming_prefix}-bastion"
  machine_type = "e2-micro"
  zone = var.zone
  project = var.project_id
  tags = ["bastion-host"]
  boot_disk { initialize_params { image = "debian-cloud/debian-11" } }
  network_interface { network = var.network_link; subnetwork = var.subnetwork_link }
  metadata = { enable-oslogin = "TRUE" }
}
resource "google_compute_firewall" "allow_iap" {
  name = "${var.naming_prefix}-allow-iap-ssh"
  network = var.network_link
  project = var.project_id
  allow { protocol = "tcp"; ports = ["22"] }
  source_ranges = ["35.235.240.0/20"]
  target_tags = ["bastion-host"]
}
