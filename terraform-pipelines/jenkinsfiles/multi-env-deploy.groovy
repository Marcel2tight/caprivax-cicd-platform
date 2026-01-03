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
                    
                    // DEBUG: Print complete workspace structure
                    sh """
                        echo "=== WORKSPACE STRUCTURE DEBUG ==="
                        echo "Workspace: ${env.WORKSPACE}"
                        echo "Current directory:"
                        pwd
                        echo "Listing all directories:"
                        find . -type d -name "modules" | head -10
                        echo "Looking for module directories:"
                        find . -type d -name "networking" -o -name "service-accounts" -o -name "jenkins-controller" -o -name "monitoring-stack" | head -20
                        echo "Checking specific paths:"
                        ls -la modules/ 2>/dev/null || echo "No modules/ at root"
                        ls -la jenkins-infrastructure/ 2>/dev/null || echo "No jenkins-infrastructure/ directory"
                        ls -la jenkins-infrastructure/modules/ 2>/dev/null || echo "No jenkins-infrastructure/modules/"
                    """
                }
            }
        }

        stage('Initialize & Patch') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // First, find where modules actually are
                        def modulesDir = sh(script: """
                            # Look for modules directory
                            if [ -d "modules" ]; then
                                echo "${env.WORKSPACE}/modules"
                            elif [ -d "jenkins-infrastructure/modules" ]; then
                                echo "${env.WORKSPACE}/jenkins-infrastructure/modules"
                            elif [ -d "infrastructure/modules" ]; then
                                echo "${env.WORKSPACE}/infrastructure/modules"
                            else
                                # Try to find any modules directory
                                find "${env.WORKSPACE}" -type d -name "modules" | head -1
                            fi
                        """, returnStdout: true).trim()
                        
                        if (!modulesDir) {
                            error "❌ No modules directory found in the repository!"
                        }
                        
                        echo "✅ Found modules at: ${modulesDir}"
                        
                        // Verify each module exists
                        def requiredModules = ['networking', 'service-accounts', 'jenkins-controller', 'monitoring-stack']
                        requiredModules.each { module ->
                            def modulePath = "${modulesDir}/${module}"
                            if (!fileExists(modulePath)) {
                                echo "⚠️ Warning: Module ${module} not found at ${modulePath}"
                                // Try to find it anywhere
                                def foundPath = sh(script: "find ${env.WORKSPACE} -type d -name '${module}' | head -1", returnStdout: true).trim()
                                if (foundPath) {
                                    echo "   Found at alternative location: ${foundPath}"
                                }
                            } else {
                                echo "✓ Module ${module} found at ${modulePath}"
                            }
                        }
                        
                        dir(TF_PATH) {
                            echo "--- 🛠️ Generating main.tf with modules from: ${modulesDir} ---"
                            
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

                            module "net" {
                              source             = "${modulesDir}/networking"
                              project_id         = var.project_id
                              naming_prefix      = "capx-${params.ENVIRONMENT}"
                              region             = var.region
                              subnet_cidr        = "10.20.0.0/24"
                              environment        = "${params.ENVIRONMENT}"
                              allowed_web_ranges = ["0.0.0.0/0"]
                              allowed_ssh_ranges = ["35.235.240.0/20"] 
                            }

                            module "sa" {
                              source             = "${modulesDir}/service-accounts"
                              project_id         = var.project_id
                              environment        = "${params.ENVIRONMENT}"
                              service_account_id = "capx-${params.ENVIRONMENT}-sa"
                            }

                            module "jenkins" {
                              source                = "${modulesDir}/jenkins-controller"
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

                            module "mon" {
                              source                = "${modulesDir}/monitoring-stack"
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
                            
                            // Show the generated main.tf for debugging
                            sh "echo '=== Generated main.tf ===' && head -50 main.tf"
                            
                            // Show module source paths
                            sh "grep 'source =' main.tf"
                            
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