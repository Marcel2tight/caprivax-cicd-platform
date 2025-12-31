output "jenkins_public_url" {
  value       = "http://${module.jenkins.external_ip}:8080"
  description = "Access the Jenkins UI here"
}

output "jenkins_private_ip" {
  value       = module.jenkins.internal_ip
  description = "Use this for internal routing or monitoring"
}

output "monitor_ip" {
  value       = module.mon.monitor_ip
  description = "The public IP of the monitoring server (Grafana/Prometheus)"
}
