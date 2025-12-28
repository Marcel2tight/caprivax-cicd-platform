resource "google_compute_instance" "jenkins" {
  name         = "${var.naming_prefix}-controller"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = ["jenkins-controller", "ssh-enabled"]
  boot_disk { initialize_params { image = var.source_image; size = 50 } }
  network_interface {
    network = var.network_link
    subnetwork = var.subnetwork_link
    dynamic "access_config" { for_each = var.public_ip ? [1] : []; content {} }
  }
  service_account { email = var.service_account_email; scopes = ["cloud-platform"] }
}
