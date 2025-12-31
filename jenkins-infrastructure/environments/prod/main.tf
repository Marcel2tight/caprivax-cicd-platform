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

# 1. Foundation: Networking (Strict Security)
module "net" {
  source             = "../../modules/networking"
  project_id         = var.project_id
  naming_prefix      = "capx-prd"
  region             = var.region
  subnet_cidr        = "10.30.0.0/24"
  environment        = "prod"
  allowed_web_ranges = ["0.0.0.0/0"] 
  # Absolute Lockdown: Only IAP can touch SSH
  allowed_ssh_ranges = ["35.235.240.0/20"]
}

# 2. Identity: Service Accounts
module "sa" {
  source             = "../../modules/service-accounts"
  project_id         = var.project_id
  environment        = "prod"
  service_account_id = "capx-prod-sa"
}

# 3. Access: Bastion Host
module "bastion" {
  source                = "../../modules/bastion"
  project_id            = var.project_id
  naming_prefix         = "capx-prd"
  zone                  = "${var.region}-c"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  service_account_email = module.sa.email
}

# 4. Core: Jenkins Controller (Private Only)
module "jenkins" {
  source                = "../../modules/jenkins-controller"
  project_id            = var.project_id
  naming_prefix         = "capx-prd"
  zone                  = "${var.region}-c"
  machine_type          = "e2-standard-4"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  public_ip             = false # No external IP - Zero Trust
  source_image          = "debian-cloud/debian-11"
  service_account_email = module.sa.email
}

# 5. Observability: Monitoring
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
