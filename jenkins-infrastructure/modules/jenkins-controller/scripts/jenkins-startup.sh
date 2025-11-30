#!/bin/bash
set -e

# Log everything
exec > /var/log/jenkins-startup.log 2>&1

echo "=== Jenkins Controller Startup Script Started at $(date) ==="

# Variables
JENKINS_HOSTNAME=$(hostname)
PROJECT_ID="${project_id}"
ENVIRONMENT="${environment}"

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install prerequisites
apt-get install -y \
    openjdk-11-jdk \
    curl \
    git \
    unzip \
    python3 \
    python3-pip \
    docker.io

# Add Jenkins user to docker group
usermod -aG docker jenkins

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install -y jenkins

# Install Terraform
TERRAFORM_VERSION="1.5.0"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
mv terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update && apt-get install -y google-cloud-sdk

# Configure Jenkins
mkdir -p /var/lib/jenkins/init.groovy.d

# Create initial configuration script
cat > /var/lib/jenkins/init.groovy.d/init.groovy << 'GROOVY'
import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Set number of executors
instance.setNumExecutors(2)

// Enable agent-to-master security
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

// Save configuration
instance.save()
GROOVY

# Set proper permissions
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

# Start and enable services
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 30

# Install Google Cloud Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Create info file
cat > /etc/jenkins-info.txt << INFO
Jenkins Controller Information
==============================
Hostname: $JENKINS_HOSTNAME
Project: $PROJECT_ID
Environment: $ENVIRONMENT
Installation Time: $(date)

Access URLs:
- Web Interface: http://$(curl -s ifconfig.me):8080
- SSH Access: gcloud compute ssh $JENKINS_HOSTNAME

Initial Admin Password: /var/lib/jenkins/secrets/initialAdminPassword
INFO

echo "=== Jenkins Startup Script Completed at $(date) ==="
echo "Initial admin password: \$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
