output "jenkins_external_ip" {
  value     = module.jenkins_controller.external_ip
  sensitive = true
}

output "jenkins_url" {
  value = module.jenkins_controller.external_ip != null ? "http://${module.jenkins_controller.external_ip}:8080" : null
}

output "grafana_url" {
  value = module.monitoring_stack.grafana_url
}

output "prometheus_url" {
  value = module.monitoring_stack.prometheus_url
}

output "setup_instructions" {
  value = <<-EOT
  íº€ Caprivax CI/CD Platform - Setup Complete!
  
  â–º Jenkins: ${module.jenkins_controller.external_ip != null ? "http://${module.jenkins_controller.external_ip}:8080" : "http://localhost:8080 (Requires IAP Tunnel)"}
  â–º Grafana: ${module.monitoring_stack.grafana_url} (Login: admin/admin)
  
  Get Initial Password:
  gcloud compute ssh capx-cicd-${var.environment}-controller --project=${var.project_id} --zone=${var.zone} --command="sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  EOT
}
