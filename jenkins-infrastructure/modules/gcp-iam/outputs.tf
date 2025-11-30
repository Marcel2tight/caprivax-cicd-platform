output "jenkins_service_account_email" {
  description = "Email of the Jenkins service account"
  value       = google_service_account.jenkins.email
}

output "jenkins_service_account_name" {
  description = "Name of the Jenkins service account"
  value       = google_service_account.jenkins.name
}

output "service_account_key" {
  description = "Service account key (base64 encoded)"
  value       = google_service_account_key.jenkins_key.private_key
  sensitive   = true
}

output "assigned_roles" {
  description = "List of IAM roles assigned to Jenkins service account"
  value = [
    "roles/compute.admin",
    "roles/storage.admin", 
    "roles/iam.serviceAccountUser",
    "roles/logging.admin",
    "roles/monitoring.admin",
    "roles/artifactregistry.admin"
  ]
}
