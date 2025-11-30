variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "naming_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "machine_type" {
  description = "Machine type for Jenkins controller"
  type        = string
  default     = "e2-medium"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "boot_disk_image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-ssd"
}

variable "enable_public_ip" {
  description = "Whether to assign a public IP"
  type        = bool
  default     = true
}

variable "reserve_static_ip" {
  description = "Whether to reserve a static IP"
  type        = bool
  default     = false
}

variable "enable_secure_boot" {
  description = "Whether to enable Secure Boot"
  type        = bool
  default     = false
}

variable "network" {
  description = "VPC network"
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork"
  type        = string
}

variable "service_account" {
  description = "Service account email"
  type        = string
}

variable "custom_labels" {
  description = "Custom labels"
  type        = map(string)
  default     = {}
}

variable "dependencies" {
  description = "Explicit dependencies"
  type        = any
  default     = []
}
