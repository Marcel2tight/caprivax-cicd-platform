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

module "platform_wrapper" { # CORRECTED MODULE NAME
  source = "../../../"
  
  project_id = var.project_id
  environment = var.environment
  region = var.region
  zone = var.zone
  vpc_cidr = var.vpc_cidr
  jenkins_machine_type = var.jenkins_machine_type
  jenkins_disk_size = var.jenkins_disk_size
  enable_public_ip = var.enable_public_ip
  enable_preemptible = var.enable_preemptible
  automatic_restart = var.automatic_restart
  allowed_ssh_ips = var.allowed_ssh_ips
  allowed_web_ips = var.allowed_web_ips
}
