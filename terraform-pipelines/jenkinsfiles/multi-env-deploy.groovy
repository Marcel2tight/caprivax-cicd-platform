pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Select target environment')
        booleanParam(name: 'DRY_RUN', defaultValue: true, description: 'Checked = Plan only. Uncheck to Apply.')
        string(name: 'ROLLBACK_COMMIT', defaultValue: '', description: 'Enter Git Commit Hash to rollback (leave empty for latest).')
    }

    environment {
        TF_PATH = "jenkins-infrastructure/environments/${params.ENVIRONMENT}"
        SLACK_CHANNEL = '#deployments' 
    }

    stages {
        stage('Checkout & Sync') {
            steps {
                checkout scm
                script {
                    if (params.ROLLBACK_COMMIT != '') {
                        sh "git checkout ${params.ROLLBACK_COMMIT}"
                        env.GIT_AUTHOR = "Rollback System"
                    } else {
                        env.GIT_AUTHOR = sh(script: "git log -1 --pretty=format:'%an'", returnStdout: true).trim()
                    }
                    
                    // Comprehensive directory search
                    sh """
                        echo "=== COMPREHENSIVE DIRECTORY SCAN ==="
                        echo "Workspace: ${env.WORKSPACE}"
                        echo ""
                        echo "1. Full directory structure (top 3 levels):"
                        find . -maxdepth 3 -type d | sort
                        echo ""
                        echo "2. All .tf files in repository:"
                        find . -name "*.tf" -type f | sort
                        echo ""
                        echo "3. Searching for any module directories:"
                        find . -type d -name "*module*" -o -name "*jenkins*" -o -name "*networking*" -o -name "*service*" | sort
                        echo ""
                        echo "4. Checking common module locations:"
                        echo "   - ./modules/:"
                        ls -la modules/ 2>/dev/null || echo "    Not found"
                        echo "   - ./jenkins-infrastructure/modules/:"
                        ls -la jenkins-infrastructure/modules/ 2>/dev/null || echo "    Not found"
                        echo "   - ./terraform/modules/:"
                        ls -la terraform/modules/ 2>/dev/null || echo "    Not found"
                        echo "   - ./infrastructure/modules/:"
                        ls -la infrastructure/modules/ 2>/dev/null || echo "    Not found"
                    """
                }
            }
        }

        stage('Initialize & Patch') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Create placeholder modules if they don't exist
                        def createPlaceholderModule = { moduleName ->
                            def modulePath = "${env.WORKSPACE}/placeholder-modules/${moduleName}"
                            sh """
                                mkdir -p "${modulePath}"
                                cat > "${modulePath}/main.tf" << 'EOF'
# Placeholder ${moduleName} module
# TODO: Replace with actual implementation

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

output "vpc_link" {
  value = "projects/\${var.project_id}/global/networks/\${var.environment}-vpc"
}

output "subnet_link" {
  value = "projects/\${var.project_id}/regions/us-central1/subnetworks/\${var.environment}-subnet"
}

output "email" {
  value = "\${var.environment}-sa@\${var.project_id}.iam.gserviceaccount.com"
}

output "internal_ip" {
  value = "10.20.0.10"
}
EOF
                            """
                            return modulePath
                        }
                        
                        // Try to find real modules or create placeholders
                        def findOrCreateModule = { moduleName ->
                            def foundPath = sh(script: """
                                find "${env.WORKSPACE}" -type d -name "${moduleName}" | head -1
                            """, returnStdout: true).trim()
                            
                            if (foundPath && fileExists("${foundPath}/main.tf")) {
                                echo "✓ Found real ${moduleName} module at: ${foundPath}"
                                return foundPath
                            } else {
                                echo "⚠️ Creating placeholder for ${moduleName} module"
                                return createPlaceholderModule(moduleName)
                            }
                        }
                        
                        // Find or create modules
                        def networkingModulePath = findOrCreateModule("networking")
                        def saModulePath = findOrCreateModule("service-accounts")
                        def jenkinsModulePath = findOrCreateModule("jenkins-controller")
                        def monitoringModulePath = findOrCreateModule("monitoring-stack")
                        
                        echo "Using modules:"
                        echo "- Networking: ${networkingModulePath}"
                        echo "- Service Accounts: ${saModulePath}"
                        echo "- Jenkins Controller: ${jenkinsModulePath}"
                        echo "- Monitoring Stack: ${monitoringModulePath}"
                        
                        dir(TF_PATH) {
                            echo "--- 🛠️ Generating main.tf ---"
                            
                            // Ensure variables file exists
                            sh """
                                if [ ! -f "${params.ENVIRONMENT}.auto.tfvars" ]; then
                                    echo 'project_id = "caprivax-stging-platform-infra"' > "${params.ENVIRONMENT}.auto.tfvars"
                                    echo 'region = "us-central1"' >> "${params.ENVIRONMENT}.auto.tfvars"
                                fi
                                
                                echo "Using variables:"
                                cat "${params.ENVIRONMENT}.auto.tfvars"
                            """
                            
                            sh """
                            cat <<'EOF' > main.tf
                            terraform {
                              required_version = ">= 1.5.0"
                              required_providers {
                                google = { 
                                  source = "hashicorp/google" 
                                  version = ">= 5.0" 
                                }
                              }
                              backend "gcs" {
                                bucket = "terraform-state-caprivax-stging-platform-infra"
                                prefix = "terraform/state/${params.ENVIRONMENT}"
                              }
                            }

                            # Variable declarations
                            variable "project_id" {
                              description = "The GCP project ID"
                              type        = string
                              default     = "caprivax-stging-platform-infra"
                            }

                            variable "region" {
                              description = "The GCP region"
                              type        = string
                              default     = "us-central1"
                            }

                            provider "google" {
                              project = var.project_id
                              region  = var.region
                            }
EOF
                            """
                            
                            // Add networking module
                            sh """
                            cat <<'EOF' >> main.tf

                            module "net" {
                              source             = "${networkingModulePath}"
                              project_id         = var.project_id
                              naming_prefix      = "capx-${params.ENVIRONMENT}"
                              region             = var.region
                              subnet_cidr        = "10.20.0.0/24"
                              environment        = "${params.ENVIRONMENT}"
                              allowed_web_ranges = ["0.0.0.0/0"]
                              allowed_ssh_ranges = ["35.235.240.0/20"] 
                            }
EOF
                            """
                            
                            // Add service accounts module
                            sh """
                            cat <<'EOF' >> main.tf

                            module "sa" {
                              source             = "${saModulePath}"
                              project_id         = var.project_id
                              environment        = "${params.ENVIRONMENT}"
                              service_account_id = "capx-${params.ENVIRONMENT}-sa"
                            }
EOF
                            """
                            
                            // Add jenkins module
                            sh """
                            cat <<'EOF' >> main.tf

                            module "jenkins" {
                              source                = "${jenkinsModulePath}"
                              project_id            = var.project_id
                              naming_prefix         = "capx-${params.ENVIRONMENT}"
                              zone                  = "\${var.region}-b"
                              machine_type          = "e2-standard-2"
                              network_link          = module.net.vpc_link
                              subnetwork_link       = module.net.subnet_link
                              public_ip             = true
                              source_image          = "debian-cloud/debian-11"
                              service_account_email = module.sa.email
                            }
EOF
                            """
                            
                            // Add monitoring module
                            sh """
                            cat <<'EOF' >> main.tf

                            module "mon" {
                              source                = "${monitoringModulePath}"
                              project_id            = var.project_id
                              naming_prefix         = "capx-${params.ENVIRONMENT}"
                              zone                  = "\${var.region}-b"
                              network_link          = module.net.vpc_link
                              subnetwork_link       = module.net.subnet_link
                              jenkins_ip            = module.jenkins.internal_ip
                              service_account_email = module.sa.email
                            }
EOF
                            """
                            
                            // Show configuration
                            sh """
                                echo "=== Generated main.tf ==="
                                cat main.tf
                                echo ""
                                echo "=== Module paths ==="
                                grep -A1 "module \"" main.tf | grep -E "module|source"
                            """
                            
                            // Initialize terraform
                            sh """
                                echo "=== Initializing Terraform ==="
                                terraform init -backend-config=${params.ENVIRONMENT}.tfbackend -reconfigure -input=false
                            """
                        }
                    }
                }
            }
        }

        stage('Plan') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(TF_PATH) {
                        sh """
                            echo "=== Running Terraform Plan ==="
                            terraform plan -var-file=${params.ENVIRONMENT}.auto.tfvars -out=tfplan
                        """
                    }
                }
            }
        }

        stage('Apply') {
            when { expression { !params.DRY_RUN } }
            steps {
                script {
                    // Manual Approval Gate
                    if (params.ENVIRONMENT == 'staging' || params.ENVIRONMENT == 'prod') {
                        input message: "Approve deployment to ${params.ENVIRONMENT}?", ok: "Yes, Deploy"
                    }
                    withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        dir(TF_PATH) {
                            sh """
                                echo "=== Applying Terraform Changes ==="
                                terraform apply -auto-approve tfplan
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up
            sh "rm -rf ${env.WORKSPACE}/placeholder-modules 2>/dev/null || true"
            dir(TF_PATH) {
                sh "rm -f tfplan 2>/dev/null || true"
            }
        }
        success {
            slackSend(channel: env.SLACK_CHANNEL, color: 'good', 
                message: "✅ *Success*: ${params.ENVIRONMENT.toUpperCase()} updated by *${env.GIT_AUTHOR}*.\n*Build*: ${env.BUILD_URL}")
        }
        failure {
            slackSend(channel: env.SLACK_CHANNEL, color: 'danger', 
                message: "❌ *Failure*: ${params.ENVIRONMENT.toUpperCase()} failed.\n*Logs*: ${env.BUILD_URL}console")
        }
    }
}