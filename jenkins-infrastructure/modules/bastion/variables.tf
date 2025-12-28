variable "project_id" {
  type        = string
  description = "The GCP Project ID where the bastion will be deployed"
}

variable "naming_prefix" {
  type        = string
  description = "Prefix for resource naming (e.g., capx-prd)"
}

variable "zone" {
  type        = string
  description = "The GCP zone for the bastion instance"
}

variable "network_link" {
  type        = string
  description = "Self-link or name of the VPC network"
}

variable "subnetwork_link" {
  type        = string
  description = "Self-link or name of the subnetwork"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account to attach to the bastion"
}
