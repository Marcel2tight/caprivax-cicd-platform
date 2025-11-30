output "alert_policy_names" {
  description = "Names of created alert policies"
  value = {
    high_cpu       = google_monitoring_alert_policy.high_cpu.name
    low_disk_space = google_monitoring_alert_policy.low_disk_space.name
  }
}

output "uptime_check_name" {
  description = "Name of the uptime check"
  value       = google_monitoring_uptime_check_config.jenkins_web.name
}

output "dashboard_url" {
  description = "URL to the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards?project=${var.project_id}"
}
