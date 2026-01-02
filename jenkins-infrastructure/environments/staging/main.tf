terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
  # Empty backend for Jenkins injection
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Foundation: Networking (Restricted SSH)
module "net" {
  source             = "../../modules/networking"
  project_id         = var.project_id
  naming_prefix      = "capx-stg"
  region             = var.region
  subnet_cidr        = "10.20.0.0/24"
  environment        = "stg"
  allowed_web_ranges = ["0.0.0.0/0"]
  allowed_ssh_ranges = ["35.235.240.0/20"] 
}

# 2. Identity: Service Accounts
module "sa" {
  source             = "../../modules/service-accounts"
  project_id         = var.project_id
  environment        = "stg"
  service_account_id = "capx-stg-sa"
}

# 3. Core: Jenkins Controller
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

# 4. Observability: Monitoring
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
