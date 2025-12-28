variable "project_id" {
  type        = string
  description = "The GCP Project ID where Jenkins will be deployed"
}

variable "naming_prefix" {
  type        = string
  description = "Prefix for resource naming (e.g., capx-dev)"
}

variable "zone" {
  type        = string
  description = "The GCP zone for the Jenkins instance"
}

variable "machine_type" {
  type        = string
  description = "The compute instance tier (e.g., e2-medium or e2-standard-4)"
}

variable "network_link" {
  type        = string
  description = "Self-link or name of the VPC network"
}

variable "subnetwork_link" {
  type        = string
  description = "Self-link or name of the subnetwork"
}

variable "public_ip" {
  type        = bool
  description = "Toggle to assign a public IP to the Jenkins controller"
}

variable "source_image" {
  type        = string
  description = "The OS image for the boot disk"
}

variable "service_account_email" {
  type        = string
  description = "The service account email to attach to the controller"
}
