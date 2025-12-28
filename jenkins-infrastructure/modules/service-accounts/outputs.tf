output "email" {
  value       = google_service_account.sa.email
  description = "The email address of the created CI/CD service account"
}

output "unique_id" {
  value       = google_service_account.sa.unique_id
  description = "The unique ID of the created service account"
}
