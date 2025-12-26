# ��� Caprivax CI/CD Platform

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Google Cloud](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Jenkins](https://img.shields.io/badge/jenkins-%232C5263.svg?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)

Enterprise-grade Jenkins CI/CD platform for automated Terraform infrastructure deployment across multiple environments.

## ��� Project Structure
```
caprivax-cicd-platform/
├── jenkins-infrastructure/     # Jenkins platform Terraform
├── terraform-pipelines/        # Pipeline definitions
├── scripts/                    # Automation scripts
├── config/                     # Configuration files
├── modules/                    # Reusable Terraform modules
└── docs/                       # Documentation
```

## ��� Environments

| Environment | Project ID | Status |
|-------------|------------|---------|
| Development | `caprivax-dev-cicd-platform` | ✅ Configured |
| Staging | `caprivax-staging-cicd-platform` | ✅ Configured |
| Production | `caprivax-prod-cicd-platform` | ✅ Configured |

## ��� Quick Start

```bash
# Clone this repository
git clone https://github.com/Marcel2tight/caprivax-cicd-platform.git
cd caprivax-cicd-platform

# Initialize project
./scripts/setup/init-project.sh

# Verify project structure
./scripts/setup/verify-project.sh

# Deploy development environment
cd jenkins-infrastructure/environments/dev
terraform init
terraform plan -var-file="dev.auto.tfvars"
terraform apply -var-file="dev.auto.tfvars"
```

## ��� Prerequisites

- Google Cloud Platform account
- gcloud CLI installed and configured
- Terraform 1.5.0+
- GitHub account (for CI/CD)

## ���️ Architecture

- **Jenkins Controller**: CI/CD orchestration
- **GCP Infrastructure**: Secure networking & IAM
- **Terraform Pipelines**: Automated deployments
- **Multi-environment**: Dev, Staging, Production

## ��� Contributing

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## ��� License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ��� Support

- [Setup Guide](docs/setup/SETUP_GUIDE.md)
- [Troubleshooting](docs/troubleshooting/TROUBLESHOOTING.md)
