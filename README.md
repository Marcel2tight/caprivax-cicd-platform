# Caprivax CI/CD Platform 🚀
### Enterprise-Grade Infrastructure-as-Code & Automated Observability on GCP

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Jenkins](https://img.shields.io/badge/jenkins-%23D24939.svg?style=for-the-badge&logo=jenkins&logoColor=white)
![GCP](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)

## 📌 Project Overview
This repository contains the complete architecture for a multi-environment CI/CD platform deployed on Google Cloud Platform. It utilizes a **Modular Monorepo** pattern to manage Infrastructure-as-Code (IaC), automated server hydration, and a full observability stack.

### Key Highlights:
- **Separation of Planes:** Logic divided into a "Management Plane" (Bootstrap) and "Data Plane" (Dev/Staging/Prod).
- **Security First:** Zero-trust Production environment using IAP Tunneling (No Public IPs).
- **Self-Healing:** Automated VM hydration via startup scripts.
- **Full-Stack Monitoring:** Integrated Prometheus and Grafana with automated data source provisioning.

---

## 🏗️ Repository Structure
```text
caprivax-cicd-platform/
├── bootstrap/                # Standalone Management Plane (Hydration scripts)
├── jenkins-infrastructure/   # The Data Plane
│   ├── modules/              # Reusable blocks (Networking, Monitoring, IAM)
│   └── environments/         # Environment-specific configs (Dev, Staging, Prod)
├── terraform-pipelines/      # Groovy Pipelines-as-Code for Jenkins orchestration
└── terraform-deployer-role.yaml # Custom Least-Privilege IAM Role definition
🛠️ Tech Stack & Tools
Infrastructure: Terraform (Modular HCL)

CI/CD: Jenkins (Multistage Groovy Pipelines)

Cloud: Google Cloud Platform (VPC, Compute Engine, Secret Manager, IAM)

Monitoring: Prometheus, Grafana, Node Exporter

Security: IAP (Identity-Aware Proxy), Service Account Impersonation, RBAC

🚀 Deployment Logic
1. The Bootstrap (Management)
The platform begins with a manually hydrated Manager VM (The Director). This VM acts as the Jenkins Controller, configured via bootstrap/hydrate_manager.sh to include all necessary binaries (Terraform, Git, Java).

2. Multi-Environment Orchestration
The Jenkins pipeline (terraform-pipelines/jenkinsfiles/multi-env-deploy.groovy) handles the lifecycle of three distinct environments:

Dev: Rapid iteration, public UIs, open debugging.

Staging: Pre-production parity check.

Prod: Hardened, private-only infrastructure with manual approval gates.

3. Observability Stack
Deployed as a Docker-Compose stack within the infrastructure, featuring:

Prometheus: Scrapes Jenkins job metrics and hardware telemetry.

Grafana: Visualizes health via Dashboards 1860 (Hardware) and 9964 (Jenkins Health).

Alerting: Integrated Slack notifications for real-time deployment status.

🔒 Security Posture
Identity: All actions are performed via a dedicated CI/CD Service Account with a custom-defined role (terraform-deployer-role.yaml).

Secrets: Grafana admin passwords and sensitive credentials are dynamically generated and stored in GCP Secret Manager.

Network: Production workloads are isolated from the public internet, requiring IAP for administrative access.


👤 Author
Marcel Owhonda - Cloud & DevOps Engineer
- GitHub: [@Marcel2tight](https://github.com/Marcel2tight)
- LinkedIn: [Marcel Owhonda](https://www.linkedin.com/in/marcel-owhonda-devops)

---
*This project was built as a capstone for demonstrating advanced expertise in GCP Cloud Engineering and DevOps Automation.*