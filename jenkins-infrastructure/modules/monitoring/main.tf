# Monitoring Module for Jenkins CI/CD Platform

# Alert policy for high CPU utilization
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "${var.naming_prefix} - High CPU Utilization"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "High CPU utilization on Jenkins controller"

    condition_threshold {
      filter     = "resource.type=\"gce_instance\" AND resource.label.\"instance_id\"=\"${var.jenkins_instance_id}\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = var.notification_channels

  documentation {
    content = "Jenkins controller CPU utilization is above 80% for more than 1 minute. This may indicate high load or performance issues."
  }

  labels = {
    environment = var.environment
    service     = "jenkins"
  }
}

# Alert policy for disk space
resource "google_monitoring_alert_policy" "low_disk_space" {
  display_name = "${var.naming_prefix} - Low Disk Space"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Low disk space on Jenkins controller"

    condition_threshold {
      filter     = "resource.type=\"gce_instance\" AND resource.label.\"instance_id\"=\"${var.jenkins_instance_id}\" AND metric.type=\"agent.googleapis.com/disk/percent_used\" AND metric.label.\"state\"=\"used\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 85

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = var.notification_channels

  documentation {
    content = "Jenkins controller disk usage is above 85%. Consider cleaning up or increasing disk size."
  }

  labels = {
    environment = var.environment
    service     = "jenkins"
  }
}

# Uptime check for Jenkins web interface
resource "google_monitoring_uptime_check_config" "jenkins_web" {
  display_name = "${var.naming_prefix} - Jenkins Web Interface"
  timeout      = "10s"

  http_check {
    port         = 8080
    path         = "/login"
    validate_ssl = false
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.jenkins_external_ip
    }
  }

  content_matchers {
    content = "Jenkins"
    matcher = "CONTAINS_STRING"
  }

  checker_type = "STATIC_IP_CHECKERS"
}
