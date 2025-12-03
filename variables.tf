variable "project_id" { type = string }
variable "environment" { type = string }
variable "region" { default = "us-central1" }
variable "zone" { default = "us-central1-a" }
variable "vpc_cidr" { default = "10.100.0.0/16" }

# Jenkins Config
variable "jenkins_machine_type" { default = "e2-medium" }
variable "jenkins_disk_size" { default = 50 }
variable "enable_public_ip" { default = true }

# CRITICAL FIXES - These must be declared in the root to accept values from dev.auto.tfvars
variable "enable_preemptible" { default = false }
variable "automatic_restart" { default = true }

# Security
variable "allowed_ssh_ips" { default = ["0.0.0.0/0"] }
variable "allowed_web_ips" { default = ["0.0.0.0/0"] }
