variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "naming_prefix" {
  type        = string
  description = "Prefix for resource naming"
}

variable "region" {
  type        = string
}

variable "subnet_cidr" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "allowed_web_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ssh_ranges" {
  type        = list(string)
  description = "List of CIDR ranges allowed to SSH into instances"
  default     = ["35.235.240.0/20"] # Default to IAP only for safety
}
