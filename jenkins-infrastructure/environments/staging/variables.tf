variable "project_id" { type = string }
variable "environment" { type = string }
variable "region" { default = "us-central1" }
variable "zone" { default = "us-central1-a" }
variable "vpc_cidr" { default = "10.100.0.0/16" }

variable "jenkins_machine_type" { default = "e2-medium" }
variable "jenkins_disk_size" { default = 50 }
variable "enable_public_ip" { default = true }
variable "enable_preemptible" { default = false }
variable "automatic_restart" { default = true }

variable "allowed_ssh_ips" { default = ["0.0.0.0/0"] }
variable "allowed_web_ips" { default = ["0.0.0.0/0"] }
