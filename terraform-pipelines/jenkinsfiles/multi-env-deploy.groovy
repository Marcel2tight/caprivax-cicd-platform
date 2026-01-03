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
                    
                    // Verify the auto.tfvars file
                    dir(TF_PATH) {
                        sh """
                            echo "=== Verifying ${params.ENVIRONMENT}.auto.tfvars ==="
                            if [ -f "${params.ENVIRONMENT}.auto.tfvars" ]; then
                                echo "Current content:"
                                cat "${params.ENVIRONMENT}.auto.tfvars"
                                echo ""
                                echo "Project ID from file:"
                                grep -i "project_id" "${params.ENVIRONMENT}.auto.tfvars"
                            else
                                echo "Creating ${params.ENVIRONMENT}.auto.tfvars..."
                                echo 'project_id = "caprivax-stging-platform-infra"' > "${params.ENVIRONMENT}.auto.tfvars"
                                echo 'region = "us-central1"' >> "${params.ENVIRONMENT}.auto.tfvars"
                            fi
                        """
                    }
                }
            }
        }

        stage('Initialize & Patch') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Test GCP authentication and verify project exists
                        sh """
                            echo "=== Testing GCP Authentication ==="
                            gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                            
                            echo "=== Verifying GCP Project ==="
                            PROJECT_ID="caprivax-stging-platform-infra"
                            if gcloud projects describe \$PROJECT_ID >/dev/null 2>&1; then
                                echo "✓ Project \$PROJECT_ID exists and is accessible"
                                gcloud config set project \$PROJECT_ID
                            else
                                echo "✗ Project \$PROJECT_ID not found or not accessible"
                                echo "Available projects:"
                                gcloud projects list --format="value(projectId)" | head -10
                            fi
                        """
                        
                        // Find module directories
                        def jenkinsModulePath = sh(script: """
                            find "${env.WORKSPACE}" -type d -name "jenkins-controller" | head -1
                        """, returnStdout: true).trim()
                        
                        def networkingModulePath = sh(script: """
                            find "${env.WORKSPACE}" -type d -name "networking" | head -1
                        """, returnStdout: true).trim()
                        
                        def saModulePath = sh(script: """
                            find "${env.WORKSPACE}" -type d -name "service-accounts" | head -1
                        """, returnStdout: true).trim()
                        
                        def monitoringModulePath = sh(script: """
                            find "${env.WORKSPACE}" -type d -name "monitoring-stack" | head -1
                        """, returnStdout: true).trim()
                        
                        echo "Found modules at:"
                        echo "- Jenkins: ${jenkinsModulePath}"
                        echo "- Networking: ${networkingModulePath}"
                        echo "- Service Accounts: ${saModulePath}"
                        echo "- Monitoring: ${monitoringModulePath}"
                        
                        dir(TF_PATH) {
                            echo "--- 🛠️ Generating main.tf ---"
                            
                            // Ensure the project_id in auto.tfvars is correct
                            sh """
                                # Ensure project_id is correct
                                if grep -q "project_id" "${params.ENVIRONMENT}.auto.tfvars"; then
                                    sed -i 's/project_id\\s*=.*/project_id = "caprivax-stging-platform-infra"/' "${params.ENVIRONMENT}.auto.tfvars"
                                else
                                    echo 'project_id = "caprivax-stging-platform-infra"' >> "${params.ENVIRONMENT}.auto.tfvars"
                                fi
                                
                                # Ensure region is set
                                if ! grep -q "region" "${params.ENVIRONMENT}.auto.tfvars"; then
                                    echo 'region = "us-central1"' >> "${params.ENVIRONMENT}.auto.tfvars"
                                fi
                                
                                echo "Final ${params.ENVIRONMENT}.auto.tfvars:"
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
                            if (networkingModulePath) {
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
                            } else {
                                error "❌ Networking module not found!"
                            }
                            
                            // Add service accounts module
                            if (saModulePath) {
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
                            } else {
                                error "❌ Service Accounts module not found!"
                            }
                            
                            // Add jenkins module
                            if (jenkinsModulePath) {
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
                            } else {
                                error "❌ Jenkins Controller module not found!"
                            }
                            
                            // Add monitoring module if exists
                            if (monitoringModulePath) {
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
                            } else {
                                echo "// Monitoring module not included (optional)"
                            }
                            
                            // Show final configuration
                            sh """
                                echo "=== Generated main.tf (first 50 lines) ==="
                                head -50 main.tf
                                echo ""
                                echo "=== Module source paths ==="
                                grep "source =" main.tf
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
                            echo "Using variables from: ${params.ENVIRONMENT}.auto.tfvars"
                            cat ${params.ENVIRONMENT}.auto.tfvars
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
                    // Manual Approval Gate for staging/prod
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