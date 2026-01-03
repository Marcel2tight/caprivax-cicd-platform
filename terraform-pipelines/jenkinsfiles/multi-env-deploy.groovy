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
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [
                        // Clean before checkout
                        [$class: 'CleanBeforeCheckout'],
                        // Clone all branches and tags
                        [$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false]
                    ],
                    userRemoteConfigs: [[url: 'https://github.com/your-org/your-repo.git']]
                ])
                
                script {
                    if (params.ROLLBACK_COMMIT != '') {
                        sh "git checkout ${params.ROLLBACK_COMMIT}"
                        env.GIT_AUTHOR = "Rollback System"
                    } else {
                        env.GIT_AUTHOR = sh(script: "git log -1 --pretty=format:'%an'", returnStdout: true).trim()
                    }
                    
                    // DEBUG: Print complete repository structure
                    sh """
                        echo "=== FULL REPOSITORY STRUCTURE ==="
                        echo "Workspace: ${env.WORKSPACE}"
                        echo "Current directory:"
                        pwd
                        echo "Complete tree (first 50 lines):"
                        find . -type f -name "*.tf" | sort | head -50
                        echo ""
                        echo "=== CHECKING MODULES DIRECTORIES ==="
                        echo "Looking for modules at: ${env.WORKSPACE}/jenkins-infrastructure/modules/"
                        if [ -d "${env.WORKSPACE}/jenkins-infrastructure/modules/" ]; then
                            echo "✓ Found jenkins-infrastructure/modules/"
                            ls -la "${env.WORKSPACE}/jenkins-infrastructure/modules/"
                        else
                            echo "✗ NOT FOUND: jenkins-infrastructure/modules/"
                        fi
                        echo ""
                        echo "Looking for modules at: ${env.WORKSPACE}/modules/"
                        if [ -d "${env.WORKSPACE}/modules/" ]; then
                            echo "✓ Found modules/"
                            ls -la "${env.WORKSPACE}/modules/"
                        else
                            echo "✗ NOT FOUND: modules/"
                        fi
                        echo ""
                        echo "=== SEARCHING FOR SPECIFIC MODULES ==="
                        echo "Searching for 'jenkins-controller' directory:"
                        find . -type d -name "jenkins-controller" 2>/dev/null
                        echo ""
                        echo "Searching for 'networking' directory:"
                        find . -type d -name "networking" 2>/dev/null
                        echo ""
                        echo "=== LISTING ALL .tf FILES ==="
                        find . -type f -name "*.tf" | head -30
                    """
                }
            }
        }

        stage('Initialize & Patch') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Find the actual module directories
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
                        
                        // Get the common parent directory for modules
                        def modulesDir = sh(script: """
                            # Find common parent
                            dirs="${jenkinsModulePath} ${networkingModulePath} ${saModulePath} ${monitoringModulePath}"
                            echo "\$dirs" | tr ' ' '\\n' | xargs -I {} dirname {} | sort | uniq -c | sort -rn | head -1 | awk '{print \$2}'
                        """, returnStdout: true).trim()
                        
                        if (!modulesDir) {
                            modulesDir = "${env.WORKSPACE}/modules"
                        }
                        
                        echo "Using modules directory: ${modulesDir}"
                        
                        dir(TF_PATH) {
                            echo "--- 🛠️ Generating main.tf ---"
                            
                            // Use the actual found paths for each module
                            sh """
                            cat <<'EOF' > main.tf
                            terraform {
                              required_version = ">= 1.5.0"
                              required_providers {
                                google = { source = "hashicorp/google", version = ">= 5.0" }
                              }
                              backend "gcs" {}
                            }

                            provider "google" {
                              project = var.project_id
                              region  = var.region
                            }
EOF
                            """
                            
                            // Add modules with their actual paths
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
                            }
                            
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
                            }
                            
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
                            }
                            
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
                            }
                            
                            // Show the generated main.tf
                            sh "echo '=== Generated main.tf ===' && cat main.tf"
                            
                            // Initialize terraform
                            sh "terraform init -backend-config=${params.ENVIRONMENT}.tfbackend -reconfigure"
                        }
                    }
                }
            }
        }

        stage('Plan') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(TF_PATH) {
                        sh "terraform plan -var-file=${params.ENVIRONMENT}.auto.tfvars -out=tfplan"
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
                            sh "terraform apply -auto-approve tfplan"
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