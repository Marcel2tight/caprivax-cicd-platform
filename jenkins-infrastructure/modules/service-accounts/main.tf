resource "google_service_account" "sa" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "CI/CD Service Account for ${var.environment}"
}

resource "google_project_iam_member" "sa_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/storage.admin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}
