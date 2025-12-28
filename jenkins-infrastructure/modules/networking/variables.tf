variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "naming_prefix" {
  type        = string
  description = "Prefix for resource naming (e.g., capx-dev)"
}

variable "region" {
  type        = string
  description = "The GCP region for the network"
}

variable "subnet_cidr" {
  type        = string
  description = "The IP range for the subnetwork in CIDR notation (e.g., 10.10.0.0/24)"
  
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "The subnet_cidr must be a valid IPv4 CIDR range."
  }
}

variable "environment" {
  type        = string
  description = "The deployment environment (dev, stg, or prod)"
}

variable "allowed_web_ranges" {
  type        = list(string)
  description = "List of CIDR ranges allowed to access web services (Jenkins/Grafana)"
  default     = ["0.0.0.0/0"]
}
