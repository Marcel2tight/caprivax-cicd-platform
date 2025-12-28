terraform {
  backend "gcs" { bucket = "caprivax-tf-state"; prefix = "jenkins/prod" }
}
provider "google" { project = var.project_id; region = var.region }

module "sa" { source = "../../modules/service-accounts"; project_id = var.project_id; environment = "prod"; service_account_id = "capx-prod-sa" }
module "net" { source = "../../modules/networking"; project_id = var.project_id; naming_prefix = "capx-prd"; region = var.region; subnet_cidr = "10.30.0.0/24"; environment = "prod" }
# Production gets a Bastion host for IAP access
module "bastion" { source = "../../modules/bastion"; project_id = var.project_id; naming_prefix = "capx-prd"; zone = "${var.region}-c"; network_link = module.net.vpc_link; subnetwork_link = module.net.subnet_link; service_account_email = module.sa.email }
module "jenkins" {
  source = "../../modules/jenkins-controller"
  project_id = var.project_id; naming_prefix = "capx-prd"; zone = "${var.region}-c"
  machine_type = "e2-standard-4"; network_link = module.net.vpc_link; subnetwork_link = module.net.subnet_link; public_ip = false
  source_image = "debian-cloud/debian-11"; service_account_email = module.sa.email
}
# Production monitoring
module "mon" { source = "../../modules/monitoring-stack"; project_id = var.project_id; naming_prefix = "capx-prd"; zone = "${var.region}-c"; network_link = module.net.vpc_link; subnetwork_link = module.net.subnet_link; jenkins_ip = module.jenkins.internal_ip; service_account_email = module.sa.email }
