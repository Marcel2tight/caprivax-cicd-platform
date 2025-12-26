project_id  = "caprivax-prod-platform-infra"
environment = "prod"
developer_vms = {
  "app-server" = {
    machine_type     = "e2-medium"
    instance_number  = 1
    enable_public_ip = false
  }
}