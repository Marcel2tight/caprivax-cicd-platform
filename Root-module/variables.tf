variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "default_machine_type" {
  type    = string
  default = "e2-micro"
}

variable "labels" {
  type = map(string)
  default = {
    "managed-by"  = "terraform"
    "cost-center" = "infrastructure-ops"
  }
}

variable "enable_public_ip" {
  type    = bool
  default = false
  description = "Global toggle for public IP assignment"
}

variable "developer_vms" {
  type = map(object({
    machine_type     = string
    instance_number  = number
    enable_public_ip = bool
  }))
}