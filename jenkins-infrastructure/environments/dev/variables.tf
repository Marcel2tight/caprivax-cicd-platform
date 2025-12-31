variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "region" {
  type        = string
  description = "The GCP region"
}

variable "naming_prefix" {
  type        = string
  description = "Prefix for resources (e.g., capx-dev)"
}
