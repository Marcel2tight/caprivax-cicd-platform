terraform {
  backend "gcs" {
    bucket = "caprivax-tf-state"
    prefix = "jenkins/staging"
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
  environment        = "stg"
  service_account_id = "capx-stg-sa"
}

# Network Infrastructure (Staging CIDR)
module "net" {
  source        = "../../modules/networking"
  project_id    = var.project_id
  naming_prefix = "capx-stg"
  region        = var.region
  subnet_cidr   = "10.20.0.0/24"
  environment   = "stg"
}

# Jenkins Controller (Staging Specs)
module "jenkins" {
  source                = "../../modules/jenkins-controller"
  project_id            = var.project_id
  naming_prefix         = "capx-stg"
  zone                  = "${var.region}-b"
  machine_type          = "e2-standard-2"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  public_ip             = true
  source_image          = "debian-cloud/debian-11"
  service_account_email = module.sa.email
}

# Monitoring Stack
module "mon" {
  source                = "../../modules/monitoring-stack"
  project_id            = var.project_id
  naming_prefix         = "capx-stg"
  zone                  = "${var.region}-b"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  jenkins_ip            = module.jenkins.internal_ip
  service_account_email = module.sa.email
}
