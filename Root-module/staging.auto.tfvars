# Staging Environment - Pre-production Validation
project_id  = "caprivax-stging-platform-infra"
environment = "staging"
region      = "us-central1"
zone        = "us-central1-b"

# VM Defaults - Balanced Resources
default_machine_type = "e2-medium"

# FinOps: Staging-specific cost tracking
labels = {
  "owner"       = "marcel"
  "project"     = "caprivax-platform"
  "cost-center" = "qa-staging"
  "managed-by"  = "terraform"
}

# Staging VMs - Production-like configuration
developer_vms = {
  "webapp-qa" = {
    machine_type     = "e2-medium"
    instance_number  = 1
    enable_public_ip = false # Validate IAP access here first!
  }
}
