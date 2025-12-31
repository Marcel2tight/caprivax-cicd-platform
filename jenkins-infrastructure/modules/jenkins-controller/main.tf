resource "google_compute_instance" "jenkins" {
  name         = "${var.naming_prefix}-controller"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  
  # Network tags for firewall routing (Matches your Networking Module)
  tags = ["jenkins-controller", "ssh-enabled"]

  boot_disk {
    initialize_params {
      image = var.source_image
      size  = 50
    }
  }

  network_interface {
    network    = var.network_link
    subnetwork = var.subnetwork_link

    # Logic: Only add a public IP if public_ip variable is true
    dynamic "access_config" {
      for_each = var.public_ip ? [1] : []
      content {
        # Ephemeral external IP
      }
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
    environment    = var.naming_prefix
  }

  # AUTOMATED HYDRATION: Installs Jenkins, Java, and Git on boot
  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -e
    echo "Starting automated hydration for: ${var.naming_prefix}"

    # 1. System Updates & Dependencies
    apt-get update
    apt-get install -y fontconfig openjdk-17-jre wget git gnupg lsb-release

    # 2. Install Jenkins
    wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update
    apt-get install -y jenkins

    # 3. Install Terraform (So Jenkins can manage infrastructure)
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update && apt-get install -y terraform

    # 4. Start Services
    systemctl enable jenkins
    systemctl start jenkins

    echo "Hydration complete for environment: ${var.naming_prefix}"
  SCRIPT
}
