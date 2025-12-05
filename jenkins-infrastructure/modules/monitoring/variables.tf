variable "project_id" {}
variable "naming_prefix" {}
variable "jenkins_instance_id" {}
variable "jenkins_external_ip" { default = null }

# FIX: Add these definitions so the module accepts them
variable "environment" { default = "dev" }
variable "jenkins_zone" { default = "us-central1-a" }
