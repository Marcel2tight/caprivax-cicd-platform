project_id       = "caprivax-dev-platform-infra"
environment      = "dev"
enable_public_ip = true

developer_vms = {
  "sandbox" = {
    machine_type     = "e2-micro"
    instance_number  = 1
    enable_public_ip = true
  }
}