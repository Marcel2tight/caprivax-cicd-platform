output "project_info" {
  description = "Project information"
  value = {
    project_id  = var.project_id
    environment = var.environment
    region      = var.region
  }
}

output "setup_instructions" {
  description = "Initial setup instructions"
  value = <<-EOT
  íº€ Caprivax CI/CD Platform - Basic Setup Complete!
  
  Next Steps:
  1. Review and customize environment configurations
  2. Set up remote Git repository
  3. Create Jenkins infrastructure modules
  4. Deploy development environment
  
  Project Location: ~/OneDrive/Documents/Google-Cloud-Platform/Repositories/caprivax-cicd-platform
  EOT
}
