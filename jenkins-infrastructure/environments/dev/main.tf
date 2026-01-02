terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0" # Changed to >= to accommodate your v7.14 installation
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
   backend "gcs" {
    bucket = "caprivax-tf-state"  
    prefix = "terraform/state"           # Optional: Folder path within bucket
  }
 }

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Foundation: Networking
module "net" {
  source             = "../../modules/networking"
  project_id         = var.project_id
  naming_prefix      = var.naming_prefix
  region             = var.region
  subnet_cidr        = "10.10.0.0/24"
  environment        = "dev"
  allowed_web_ranges = ["0.0.0.0/0"]
  allowed_ssh_ranges = ["0.0.0.0/0"] 
}

# 2. Identity: Service Accounts
module "sa" {
  source             = "../../modules/service-accounts"
  project_id         = var.project_id
  environment        = "dev"
  service_account_id = "capx-dev-sa"
}

# 3. Access: Bastion Host
module "bastion" {
  source                = "../../modules/bastion"
  project_id            = var.project_id
  naming_prefix         = var.naming_prefix
  zone                  = "${var.region}-a"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  service_account_email = module.sa.email
}

# 4. Observability: Monitoring
module "mon" {
  source                = "../../modules/monitoring-stack"
  project_id            = var.project_id
  naming_prefix         = var.naming_prefix
  zone                  = "${var.region}-a"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  jenkins_ip            = module.jenkins.internal_ip
  service_account_email = module.sa.email
}
