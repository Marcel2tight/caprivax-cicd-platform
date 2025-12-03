variable "project_id" {}
variable "naming_prefix" {}
variable "region" {}
variable "subnet_cidr" {}
variable "allowed_ssh_ips" { type = list(string) }
variable "allowed_web_ips" { type = list(string) }
