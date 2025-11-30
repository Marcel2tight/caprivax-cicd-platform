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

variable "jenkins_instance_id" {
  description = "Instance ID of the Jenkins controller"
  type        = string
}

variable "jenkins_external_ip" {
  description = "External IP of the Jenkins controller"
  type        = string
}

variable "jenkins_zone" {
  description = "Zone of the Jenkins controller"
  type        = string
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "custom_labels" {
  description = "Custom labels"
  type        = map(string)
  default     = {}
}
