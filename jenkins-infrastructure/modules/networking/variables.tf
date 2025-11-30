variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "naming_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.100.10.0/24"
}

variable "allowed_ssh_ips" {
  description = "List of IP ranges allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_web_ips" {
  description = "List of IP ranges allowed for web access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "custom_labels" {
  description = "Custom labels to apply to resources"
  type        = map(string)
  default     = {}
}
