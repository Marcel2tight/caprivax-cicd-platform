terraform {
  backend "gcs" {
    bucket = "caprivax-tf-state"
    prefix = "jenkins/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Service Account Management
module "sa" {
  source             = "../../modules/service-accounts"
  project_id         = var.project_id
  environment        = "prod"
  service_account_id = "capx-prod-sa"
}

# Network Infrastructure
module "net" {
  source         = "../../modules/networking"
  project_id     = var.project_id
  naming_prefix  = "capx-prd"
  region         = var.region
  subnet_cidr    = "10.30.0.0/24"
  environment    = "prod"
}

# Production Bastion Host (Zero-Trust Entry Point)
module "bastion" {
  source                = "../../modules/bastion"
  project_id            = var.project_id
  naming_prefix         = "capx-prd"
  zone                  = "${var.region}-c"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  service_account_email = module.sa.email
}

# Primary Jenkins Controller
module "jenkins" {
  source                = "../../modules/jenkins-controller"
  project_id            = var.project_id
  naming_prefix         = "capx-prd"
  zone                  = "${var.region}-c"
  machine_type          = "e2-standard-4"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  public_ip             = false
  source_image          = "debian-cloud/debian-11"
  service_account_email = module.sa.email
}

# Production Monitoring Stack (Grafana/Prometheus)
module "mon" {
  source                = "../../modules/monitoring-stack"
  project_id            = var.project_id
  naming_prefix         = "capx-prd"
  zone                  = "${var.region}-c"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  jenkins_ip            = module.jenkins.internal_ip
  service_account_email = module.sa.email
}
