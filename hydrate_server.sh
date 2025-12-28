#!/bin/bash
set -e

echo "--- í´§ Installing Java & Jenkins ---"
# 1. Install Java (Required for Jenkins)
sudo apt-get update
sudo apt-get install -y fontconfig openjdk-17-jre

# 2. Add Jenkins GPG Key (Official 2023 Key)
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  [https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key](https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key)

# 3. Add Jenkins Repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 4. Install Jenkins Package
sudo apt-get update
sudo apt-get install -y jenkins

# 5. Enable and Start Service
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "--- í´§ Installing CI/CD Tools ---"
# 6. Install Git and dependencies
sudo apt-get install -y git gnupg curl lsb-release

# 7. Install Terraform (HashiCorp Official Repo)
wget -O- [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
[https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

echo "âœ… Hydration Complete. Versions:"
java -version
jenkins --version
terraform --version
git --version
