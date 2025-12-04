terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
  backend "gcs" {
    bucket = "caprivax-tf-state"
    prefix = "jenkins-cicd/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  naming_prefix = "capx-cicd-${var.environment}"
}

# Networking Module
module "networking" {
  source          = "../../modules/networking"
  project_id      = var.project_id
  naming_prefix   = local.naming_prefix
  region          = var.region
  subnet_cidr     = var.vpc_cidr
  allowed_ssh_ips = var.allowed_ssh_ips
  allowed_web_ips = var.allowed_web_ips
}

# IAM Module
module "jenkins_iam" {
  source        = "../../modules/gcp-iam"
  project_id    = var.project_id
  naming_prefix = local.naming_prefix
  environment   = var.environment
}

# Controller Module
module "jenkins_controller" {
  source = "../../modules/jenkins-controller"
  
  project_id          = var.project_id
  environment         = var.environment
  naming_prefix       = local.naming_prefix
  region              = var.region
  zone                = var.zone
  machine_type        = var.jenkins_machine_type
  boot_disk_size      = var.jenkins_disk_size
  enable_public_ip    = var.enable_public_ip
  enable_preemptible  = var.enable_preemptible
  automatic_restart   = var.automatic_restart
  
  network_self_link     = module.networking.vpc_self_link
  subnetwork_self_link  = module.networking.subnet_self_link
  service_account_email = module.jenkins_iam.jenkins_service_account_email
  instance_tags         = ["jenkins-controller", "ssh-enabled", "jenkins-web"]
}
