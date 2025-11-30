#!/bin/bash
set -e

echo "íº€ Initializing Caprivax CI/CD Platform Project"
echo "=============================================="
echo "Location: $(pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        print_warning "Terraform not found. Installing..."
        wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
        unzip terraform_1.5.0_linux_amd64.zip
        sudo mv terraform /usr/local/bin/
        rm terraform_1.5.0_linux_amd64.zip
    fi
    
    print_status "Prerequisites satisfied."
}

# Initialize Git repository
init_git() {
    print_status "Initializing Git repository..."
    
    if [ ! -d ".git" ]; then
        git init
        git branch -M main
        
        cat > .gitignore << 'GITIGNORE'
# Terraform
**/.terraform/*
**/*.tfstate*
**/*.tfvars
**/.terraform.lock.hcl

# Jenkins
**/secrets/
**/jobs/
**/plugins/

# Logs
**/*.log
**/logs/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Temporary
*.tmp
*.temp
GITIGNORE
        
        git add .
        git commit -m "feat: initial commit - Caprivax CI/CD Platform"
        print_status "Git repository initialized."
    else
        print_status "Git repository already exists."
    fi
}

# Verify project structure
verify_structure() {
    print_status "Verifying project structure..."
    
    local required_dirs=(
        "jenkins-infrastructure/modules/jenkins-controller"
        "jenkins-infrastructure/modules/gcp-iam"
        "jenkins-infrastructure/modules/networking"
        "jenkins-infrastructure/environments/dev"
        "scripts/setup"
        "terraform-pipelines/jenkinsfiles"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_error "Missing directory: $dir"
            exit 1
        fi
    done
    
    print_status "Project structure verified."
}

# Display next steps
show_next_steps() {
    cat << 'NEXT_STEPS'

í¾‰ Project Initialization Complete!

Next Steps:
1. Review environment configurations in:
   - jenkins-infrastructure/environments/dev/dev.auto.tfvars
   - jenkins-infrastructure/environments/staging/staging.auto.tfvars  
   - jenkins-infrastructure/environments/prod/prod.auto.tfvars

2. Set up remote Git repository:
   git remote add origin <your-repo-url>
   git push -u origin main

3. Deploy development environment:
   cd jenkins-infrastructure/environments/dev
   terraform init -backend-config=backend.hcl
   terraform plan -var-file="dev.auto.tfvars"
   terraform apply -var-file="dev.auto.tfvars"

4. Access Jenkins and complete setup

Project Location: ~/OneDrive/Documents/Google-Cloud-Platform/Repositories/caprivax-cicd-platform
NEXT_STEPS
}

main() {
    check_prerequisites
    verify_structure
    init_git
    show_next_steps
}

main "$@"
