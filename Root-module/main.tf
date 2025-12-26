module "compute_instances" {
  source   = "../modules/standard-vm"
  for_each = var.developer_vms

  project_id = var.project_id
  # Standardized naming: capx-dev-frontend-01
  vm_name          = "capx-${var.environment}-${each.key}-${format("%02d", each.value.instance_number)}"
  environment      = var.environment
  machine_type     = coalesce(each.value.machine_type, var.default_machine_type)
  zone             = var.zone
  enable_public_ip = each.value.enable_public_ip
  network          = "default"

  # Injecting the global FinOps labels
  labels = var.labels
}

# 1. Create a Cloud Router (Required for NAT)
resource "google_compute_router" "router" {
  name    = "${var.environment}-router"
  project = var.project_id
  region  = var.region
  network = "default"
}

# 2. Create the NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}