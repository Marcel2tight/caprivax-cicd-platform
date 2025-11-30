# IAM Module for Jenkins CI/CD Platform
resource "google_service_account" "jenkins" {
  account_id   = "${var.naming_prefix}-sa"
  display_name = "Jenkins CI/CD Service Account"
  description  = "Service account for Jenkins CI/CD platform in ${var.environment} environment"
  project      = var.project_id
}

# IAM roles for Jenkins service account
resource "google_project_iam_member" "jenkins_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_monitoring_admin" {
  project = var.project_id
  role    = "roles/monitoring.admin"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

# Service account key for initial setup (optional)
resource "google_service_account_key" "jenkins_key" {
  service_account_id = google_service_account.jenkins.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
