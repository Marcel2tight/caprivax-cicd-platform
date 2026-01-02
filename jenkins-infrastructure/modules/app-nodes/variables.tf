variable "project_id" {
  type        = string
}

variable "naming_prefix" {
  type        = string
  description = "Prefix used for naming (e.g. capx-dev, capx-prd)"
}

variable "zone" {
  type        = string
}

variable "machine_type" {
  type        = string
}

variable "network_link" {
  type        = string
}

variable "subnetwork_link" {
  type        = string
}

variable "public_ip" {
  type        = bool
  description = "Set to true for Dev/Staging, false for Production"
}

variable "source_image" {
  type        = string
}

variable "service_account_email" {
  type        = string
}
