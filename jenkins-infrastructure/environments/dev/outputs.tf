output "jenkins_external_ip" {
  # Value derived from the module defined in THIS folder's main.tf
  value     = module.jenkins_controller.external_ip
  sensitive = true
}

output "jenkins_url" {
  value = module.jenkins_controller.external_ip != null ? "http://${module.jenkins_controller.external_ip}:8080" : null
}

output "setup_instructions" {
  value = <<-EOT
  �� Caprivax CI/CD Platform - Setup Complete!
  
  ► Access Jenkins: ${module.jenkins_controller.external_ip != null ? "http://${module.jenkins_controller.external_ip}:8080" : "http://localhost:8080 (Requires IAP Tunnel)"}
  
  ► SSH Command:    gcloud compute ssh capx-cicd-${var.environment}-controller --project=${var.project_id} --zone=${var.zone} ${module.jenkins_controller.external_ip == null ? "--tunnel-through-iap" : ""}
  
  Get Initial Password:
  gcloud compute ssh capx-cicd-${var.environment}-controller --project=${var.project_id} --zone=${var.zone} ${module.jenkins_controller.external_ip == null ? "--tunnel-through-iap" : ""} --command="sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  EOT
}
