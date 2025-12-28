terraform {
  backend "gcs" { bucket = "caprivax-tf-state"; prefix = "jenkins/dev" }
}
provider "google" { project = var.project_id; region = var.region }

module "sa" { source = "../../modules/service-accounts"; project_id = var.project_id; environment = "dev"; service_account_id = "capx-dev-sa" }
module "net" { source = "../../modules/networking"; project_id = var.project_id; naming_prefix = "capx-dev"; region = var.region; subnet_cidr = "10.10.0.0/24"; environment = "dev" }
module "jenkins" {
  source = "../../modules/jenkins-controller"
  project_id = var.project_id; naming_prefix = "capx-dev"; zone = "${var.region}-a"
  network_link = module.net.vpc_link; subnetwork_link = module.net.subnet_link; public_ip = true
  machine_type = "e2-medium"; source_image = "debian-cloud/debian-11"; service_account_email = module.sa.email
}
module "mon" { source = "../../modules/monitoring-stack"; project_id = var.project_id; naming_prefix = "capx-dev"; zone = "${var.region}-a"; network_link = module.net.vpc_link; subnetwork_link = module.net.subnet_link; jenkins_ip = module.jenkins.internal_ip; service_account_email = module.sa.email }
