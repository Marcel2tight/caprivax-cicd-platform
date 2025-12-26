variable "project_id" {
  type        = string
  description = "The GCP Project ID where resources will be deployed"
}

variable "vm_name" {
  type        = string
  description = "The name of the virtual machine instance"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "The GCP zone for the instance"
}

variable "machine_type" {
  type        = string
  default     = "e2-micro"
  description = "The compute instance tier"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, or prod)"
}

# FinOps: Mandatory labeling map for cost tracking
variable "labels" {
  type = map(string)
  default = {
    "managed-by"  = "terraform"
    "cost-center" = "infrastructure"
  }
}

# Security: Toggles Public IP exposure
variable "enable_public_ip" {
  type    = bool
  default = false
}

# Networking
variable "network" {
  type    = string
  default = "default"
}

variable "subnetwork" {
  type    = string
  default = null
}

# Boot Disk Configuration
variable "boot_disk_image" {
  type    = string
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
  type    = number
  default = 20
}

variable "boot_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "tags" {
  type    = list(string)
  default = []
}