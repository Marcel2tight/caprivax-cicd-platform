# Caprivax CI/CD Platform - Main Infrastructure
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # Use local backend for development (no bucket needed)
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Locals for common values
locals {
  common_tags = {
    Project     = "caprivax-cicd"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    Repository  = "caprivax-cicd-platform"
  }
  
  naming_prefix = "capx-cicd-${var.environment}"
}

# Module composition
module "networking" {
  source = "./jenkins-infrastructure/modules/networking"
  
  project_id       = var.project_id
  naming_prefix    = local.naming_prefix
  region           = var.region
  subnet_cidr      = var.vpc_cidr
  allowed_ssh_ips  = var.allowed_ssh_ips
  allowed_web_ips  = var.allowed_web_ips
  custom_labels    = local.common_tags
}

module "jenkins_iam" {
  source = "./jenkins-infrastructure/modules/gcp-iam"
  
  project_id     = var.project_id
  naming_prefix  = local.naming_prefix
  environment    = var.environment
  custom_labels  = local.common_tags
}

module "jenkins_controller" {
  source = "./jenkins-infrastructure/modules/jenkins-controller"
  
  project_id          = var.project_id
  naming_prefix       = local.naming_prefix
  environment         = var.environment
  region              = var.region
  zone                = var.zone
  machine_type        = var.jenkins_machine_type
  boot_disk_size      = var.jenkins_disk_size
  enable_public_ip    = var.enable_public_ip
  network             = module.networking.vpc_self_link
  subnetwork          = module.networking.subnet_self_link
  service_account     = module.jenkins_iam.jenkins_service_account_email
  custom_labels       = local.common_tags
  dependencies        = [module.networking.vpc_name, module.jenkins_iam.jenkins_service_account_email]
}

module "monitoring" {
  source = "./jenkins-infrastructure/modules/monitoring"
  
  project_id           = var.project_id
  naming_prefix        = local.naming_prefix
  environment          = var.environment
  jenkins_instance_id  = module.jenkins_controller.self_link
  jenkins_external_ip  = module.jenkins_controller.external_ip
  jenkins_zone         = var.zone
  custom_labels        = local.common_tags
}
