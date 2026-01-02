output "monitor_ip" {
  value       = module.mon.monitor_ip
  description = "The public IP of the monitoring server"
}

output "bastion_ip" {
  value       = module.bastion.public_ip
  description = "The public IP of the Bastion host"
}

output "vpc_link" {
  value = module.net.vpc_link
}
