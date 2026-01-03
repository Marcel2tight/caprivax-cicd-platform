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
                    
                    // Debug: Show repository structure
                    sh '''
                        echo "=== REPOSITORY STRUCTURE ==="
                        echo "Looking for Terraform files..."
                        find . -name "*.tf" -type f | head -20
                        echo ""
                        echo "Looking for module directories..."
                        find . -type d -name "*module*" -o -name "*jenkins*" -o -name "*networking*" | head -20
                    '''
                }
            }
        }

        stage('Initialize & Patch') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Create simple placeholder modules
                        def createSimpleModule = { moduleName ->
                            def moduleDir = "${env.WORKSPACE}/temp-modules/${moduleName}"
                            sh """
                                mkdir -p "${moduleDir}"
                                cat > "${moduleDir}/main.tf" << 'PLACEHOLDER_MODULE'
# Placeholder ${moduleName} module

variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

# Simple outputs to allow dependency chain
output "vpc_link" {
  value = "projects/\${var.project_id}/global/networks/\${var.environment}-vpc"
}

output "subnet_link" {
  value = "projects/\${var.project_id}/regions/\${var.region}/subnetworks/\${var.environment}-subnet"
}

output "email" {
  value = "\${var.environment}-sa@\${var.project_id}.iam.gserviceaccount.com"
}

output "internal_ip" {
  value = "10.20.0.10"
}
PLACEHOLDER_MODULE
                            """
                            return moduleDir
                        }
                        
                        // Try to find existing modules or create placeholders
                        def modulePaths = [:]
                        def moduleNames = ['networking', 'service-accounts', 'jenkins-controller', 'monitoring-stack']
                        
                        moduleNames.each { moduleName ->
                            def foundPath = sh(script: """
                                find "${env.WORKSPACE}" -type d -name "${moduleName}" | grep -v temp-modules | head -1
                            """, returnStdout: true).trim()
                            
                            if (foundPath) {
                                echo "Found ${moduleName} at: ${foundPath}"
                                modulePaths[moduleName] = foundPath
                            } else {
                                echo "Creating placeholder for ${moduleName}"
                                modulePaths[moduleName] = createSimpleModule(moduleName)
                            }
                        }
                        
                        dir(TF_PATH) {
                            // Create or verify variables file
                            sh """
                                if [ ! -f "${params.ENVIRONMENT}.auto.tfvars" ]; then
                                    echo 'project_id = "caprivax-stging-platform-infra"' > "${params.ENVIRONMENT}.auto.tfvars"
                                    echo 'region = "us-central1"' >> "${params.ENVIRONMENT}.auto.tfvars"
                                fi
                                echo "Using variables from ${params.ENVIRONMENT}.auto.tfvars:"
                                cat "${params.ENVIRONMENT}.auto.tfvars"
                            """
                            
                            // Create main.tf with proper escaping
                            writeFile file: 'main.tf', text: """terraform {
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

module "net" {
  source             = "${modulePaths['networking']}"
  project_id         = var.project_id
  naming_prefix      = "capx-${params.ENVIRONMENT}"
  region             = var.region
  subnet_cidr        = "10.20.0.0/24"
  environment        = "${params.ENVIRONMENT}"
  allowed_web_ranges = ["0.0.0.0/0"]
  allowed_ssh_ranges = ["35.235.240.0/20"] 
}

module "sa" {
  source             = "${modulePaths['service-accounts']}"
  project_id         = var.project_id
  environment        = "${params.ENVIRONMENT}"
  service_account_id = "capx-${params.ENVIRONMENT}-sa"
}

module "jenkins" {
  source                = "${modulePaths['jenkins-controller']}"
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
  source                = "${modulePaths['monitoring-stack']}"
  project_id            = var.project_id
  naming_prefix         = "capx-${params.ENVIRONMENT}"
  zone                  = "\${var.region}-b"
  network_link          = module.net.vpc_link
  subnetwork_link       = module.net.subnet_link
  jenkins_ip            = module.jenkins.internal_ip
  service_account_email = module.sa.email
}
"""
                            
                            // Show generated file
                            sh '''
                                echo "=== Generated main.tf (first 40 lines) ==="
                                head -40 main.tf
                                echo ""
                                echo "=== Module source paths ==="
                                grep "source =" main.tf
                            '''
                            
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
            // Clean up temporary modules
            sh 'rm -rf ${WORKSPACE}/temp-modules 2>/dev/null || true'
            dir(TF_PATH) {
                sh 'rm -f tfplan 2>/dev/null || true'
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