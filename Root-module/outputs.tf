# 1. Detailed VM Information
output "vm_details" {
  description = "Connection guide for all VMs"
  value = {
    for name, vm in module.compute_instances : name => {
      name        = vm.vm_name
      internal_ip = vm.internal_ip
      external_ip = vm.external_ip
      ssh_command = vm.ssh_iap_command
    }
  }
}
# 2. Environment Summary
output "environment_summary" {
  description = "Summary of the current deployment environment"
  value = {
    project_id  = var.project_id
    environment = var.environment
    region      = var.region
    zone        = var.zone
  }
}