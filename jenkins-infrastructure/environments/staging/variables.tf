# Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 lowercase letters, digits, or hyphens, and must start with a letter."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# GCP Configuration
variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR range for VPC"
  type        = string
  default     = "10.100.0.0/16"
}

# Jenkins Configuration
variable "jenkins_machine_type" {
  description = "Machine type for Jenkins controller"
  type        = string
  default     = "e2-medium"
}

variable "jenkins_disk_size" {
  description = "Boot disk size for Jenkins (GB)"
  type        = number
  default     = 50
}

variable "enable_public_ip" {
  description = "Whether to assign public IP to Jenkins"
  type        = bool
  default     = true
}

# Security Configuration
variable "allowed_ssh_ips" {
  description = "List of IPs allowed to SSH to Jenkins"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_web_ips" {
  description = "List of IPs allowed to access Jenkins web interface"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
