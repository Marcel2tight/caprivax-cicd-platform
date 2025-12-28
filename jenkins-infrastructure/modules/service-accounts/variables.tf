variable "project_id" {
  type        = string
  description = "The GCP Project ID where the service account will be created"
}

variable "service_account_id" {
  type        = string
  description = "The unique ID for the service account (e.g., capx-dev-sa)"
}

variable "environment" {
  type        = string
  description = "The deployment environment (dev, stg, or prod)"
}
