output "jenkins_external_ip" {
  value     = module.main_platform.jenkins_external_ip
  sensitive = true
}

output "jenkins_url" {
  value = module.main_platform.jenkins_url
}

output "setup_instructions" {
  value = module.main_platform.setup_instructions
}
