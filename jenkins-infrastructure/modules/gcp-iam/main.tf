resource "google_service_account" "jenkins" {
  account_id   = "${var.naming_prefix}-sa"
  display_name = "Jenkins CI/CD Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "jenkins_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser",
    "roles/editor"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}
