variable "project_id" {}
variable "naming_prefix" {}
variable "region" {}
variable "subnet_cidr" {}
variable "environment" {}
variable "allowed_web_ranges" { default = ["0.0.0.0/0"] }
