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
