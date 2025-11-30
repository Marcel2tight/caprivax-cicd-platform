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

variable "custom_labels" {
  description = "Custom labels to apply to resources"
  type        = map(string)
  default     = {}
}
