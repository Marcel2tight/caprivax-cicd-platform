output "jenkins_external_ip" {
  description = "External IP address of the Jenkins controller"
  value       = module.platform_wrapper.jenkins_external_ip
  sensitive   = true
}

output "jenkins_url" {
  description = "HTTP URL for the Jenkins controller"
  value       = module.platform_wrapper.jenkins_url
}

output "setup_instructions" {
  description = "Instructions for accessing and setting up Jenkins"
  value       = module.platform_wrapper.setup_instructions
}
