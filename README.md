# 🏗️ Caprivax Enterprise Platform Infrastructure
### **GCP Multi-Environment Orchestration with Terraform & Zero-Trust Security**

## 📖 Overview
This project implements a production-grade, multi-tenant infrastructure on Google Cloud Platform (GCP). It utilizes a **Decoupled Modular Architecture** to manage Development, Staging, and Production environments with strict **Zero-Trust** security principles.



## 🛠️ Key Technical Features
* **Modular Design:** Reusable `standard-vm` child module for consistent deployments.
* **Zero-Trust Connectivity:** Complete removal of Public IPs in Staging/Prod; management via **Identity-Aware Proxy (IAP)**.
* **Outbound Governance:** **Cloud NAT** gateways for private instances to perform secure updates/patching.
* **State Management:** Remote state storage in **GCS** with **Terraform Workspaces** for environment isolation.
* **FinOps Integration:** Automated resource labeling for granular cost tracking.

---

## 📂 Project Structure
```text
capx-platform-infrastructure/
├── Modules/
│   └── standard-vm/            # The Blueprint (Compute, IAP Firewalls, Startup Logic)
├── Root-module/                # The Orchestrator (Environment Composition)
│   ├── dev.auto.tfvars         # Cost-optimized (Spot instances, Public IP)
│   ├── staging.auto.tfvars     # Pre-prod validation (Private IP, Cloud NAT)
│   └── prod.auto.tfvars        # Zero-Trust hardened (Private IP, High-Availability)
🚀 Deployment Runbook1. Initialize Project APIsAPI enablement is project-scoped. Run this to ensure IAP and Compute services are ready:BashPROJECTS=("caprivax-dev-platform-infra" "caprivax-stging-platform-infra" "caprivax-prod-platform-infra")
for PROJECT in "${PROJECTS[@]}"; do
  gcloud services enable compute.googleapis.com iap.googleapis.com --project=$PROJECT
done
2. Environment Lifecycle (Using Workspaces)Bashcd Root-module
terraform workspace select staging || terraform workspace new staging
terraform plan -var-file="staging.auto.tfvars" -out=staging.tfplan
terraform apply "staging.tfplan"
3. Secure Service Verification (IAP Tunneling)Since instances are private, use an IAP TCP tunnel to verify services like Nginx:Bash# Terminal 1: Open the Tunnel
gcloud compute start-iap-tunnel [VM_NAME] 80 --local-host-port=localhost:8080

# Terminal 2: Test the Service
curl -I http://localhost:8080
🛡️ Zero-Trust Security MatrixFeatureDevelopmentStagingProductionPublic IPEnabled (Speed)DisabledDisabledInbound AccessDirect SSH / IAPIAP OnlyIAP OnlyOutbound AccessDirect IGWCloud NATCloud NATAttack SurfaceExposedHiddenHidden♻️ Decommissioning ProtocolTo prevent orphaned resources and billing leaks, destroy in Reverse Promotion Order:Production: terraform workspace select prod && terraform destroy -var-file="prod.auto.tfvars"Staging: terraform workspace select staging && terraform destroy -var-file="staging.auto.tfvars"Development: terraform workspace select dev && terraform destroy -var-file="dev.auto.tfvars"