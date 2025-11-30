#!/bin/bash
set -e

echo "í´ Caprivax CI/CD Platform - Project Verification"
echo "================================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}âœ… PASS:${NC} $1"; }
fail() { echo -e "${RED}âŒ FAIL:${NC} $1"; }
warn() { echo -e "${YELLOW}âš ï¸  WARN:${NC} $1"; }

# Test 1: Directory Structure
echo "1. Checking Directory Structure..."
directories=(
  "jenkins-infrastructure/modules/jenkins-controller"
  "jenkins-infrastructure/modules/gcp-iam" 
  "jenkins-infrastructure/modules/networking"
  "jenkins-infrastructure/modules/monitoring"
  "jenkins-infrastructure/environments/dev"
  "jenkins-infrastructure/environments/staging"
  "jenkins-infrastructure/environments/prod"
  "terraform-pipelines/jenkinsfiles"
  "scripts/setup"
  "scripts/deployment"
  "config/jenkins"
  "docs/setup"
)

for dir in "${directories[@]}"; do
  if [ -d "$dir" ]; then
    pass "Directory exists: $dir"
  else
    fail "Directory missing: $dir"
  fi
done

# Test 2: Critical Files
echo ""
echo "2. Checking Critical Files..."
files=(
  "main.tf"
  "variables.tf"
  "outputs.tf"
  "README.md"
  "scripts/setup/init-project.sh"
  "jenkins-infrastructure/environments/dev/dev.auto.tfvars"
  "jenkins-infrastructure/environments/dev/backend.hcl"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    pass "File exists: $file"
  else
    fail "File missing: $file"
  fi
done

# Test 3: File Permissions
echo ""
echo "3. Checking Script Permissions..."
scripts=(
  "scripts/setup/init-project.sh"
  "scripts/setup/verify-project.sh"
)

for script in "${scripts[@]}"; do
  if [ -x "$script" ]; then
    pass "Script is executable: $script"
  else
    fail "Script is not executable: $script"
  fi
done

# Test 4: Terraform Syntax (if terraform is installed)
echo ""
echo "4. Checking Terraform Configuration..."
if command -v terraform &> /dev/null; then
  if terraform validate > /dev/null 2>&1; then
    pass "Terraform configuration is valid"
  else
    fail "Terraform configuration has errors"
    terraform validate
  fi
else
  warn "Terraform not installed - skipping validation"
fi

# Test 5: Environment Configurations
echo ""
echo "5. Checking Environment Configurations..."
env_files=(
  "jenkins-infrastructure/environments/dev/dev.auto.tfvars"
  "jenkins-infrastructure/environments/staging/staging.auto.tfvars"
  "jenkins-infrastructure/environments/prod/prod.auto.tfvars"
)

for env_file in "${env_files[@]}"; do
  if grep -q "project_id" "$env_file"; then
    pass "Project ID configured in: $env_file"
  else
    warn "Project ID not found in: $env_file"
  fi
done

# Test 6: Git Repository
echo ""
echo "6. Checking Git Repository..."
if [ -d ".git" ]; then
  pass "Git repository initialized"
  if git remote -v | grep -q "origin"; then
    pass "Git remote 'origin' configured"
  else
    warn "Git remote 'origin' not configured"
  fi
else
  fail "Git repository not initialized"
fi

# Summary
echo ""
echo "í³Š VERIFICATION SUMMARY"
echo "======================"
echo "Project Location: $(pwd)"
echo "Total Directories: $(find . -type d | wc -l)"
echo "Total Files: $(find . -type f | wc -l)"
echo "Terraform Files: $(find . -name "*.tf" | wc -l)"
echo "Script Files: $(find . -name "*.sh" | wc -l)"

echo ""
echo "í¾¯ NEXT STEPS:"
echo "1. Customize environment configurations"
echo "2. Set up remote Git repository"
echo "3. Deploy development environment"
echo "4. Configure Jenkins and pipelines"

echo ""
echo "âœ… Project verification completed!"
