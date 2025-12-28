variable "project_id" {
  type        = string
  description = "The GCP Project ID where the monitoring stack will be deployed"
}

variable "naming_prefix" {
  type        = string
  description = "Prefix for resource naming (e.g., capx-dev)"
}

variable "zone" {
  type        = string
  description = "The GCP zone for the monitoring instance"
}

variable "network_link" {
  type        = string
  description = "Self-link or name of the VPC network"
}

variable "subnetwork_link" {
  type        = string
  description = "Self-link or name of the subnetwork"
}

variable "jenkins_ip" {
  type        = string
  description = "The internal IP of the Jenkins controller for Prometheus scraping"
}

variable "service_account_email" {
  type        = string
  description = "The service account email to attach to the monitoring instance"
}
