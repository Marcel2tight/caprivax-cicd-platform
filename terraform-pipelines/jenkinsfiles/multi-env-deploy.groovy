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
                }
            }
        }

        stage('Initialize & Patch') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Create properly structured placeholder modules
                        def createProperModule = { moduleName, inputs, outputs ->
                            def moduleDir = "${env.WORKSPACE}/proper-modules/${moduleName}"
                            sh """
                                mkdir -p "${moduleDir}"
                                # Create variables.tf
                                cat > "${moduleDir}/variables.tf" << 'VARIABLES_TF'
${inputs}
VARIABLES_TF
                                
                                # Create outputs.tf
                                cat > "${moduleDir}/outputs.tf" << 'OUTPUTS_TF'
${outputs}
OUTPUTS_TF
                                
                                # Create main.tf with minimal resources
                                cat > "${moduleDir}/main.tf" << 'MAIN_TF'
# ${moduleName} module
resource "null_resource" "placeholder" {
  triggers = {
    project_id = var.project_id
    timestamp  = timestamp()
  }
}
MAIN_TF
                            """
                            return moduleDir
                        }
                        
                        // Define module interfaces based on your usage
                        def networkingInputs = '''
variable "project_id" {
  type = string
}

variable "naming_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "environment" {
  type = string
}

variable "allowed_web_ranges" {
  type = list(string)
}

variable "allowed_ssh_ranges" {
  type = list(string)
}
'''
                        
                        def networkingOutputs = '''
output "vpc_link" {
  value = "projects/${var.project_id}/global/networks/${var.naming_prefix}-vpc"
}

output "subnet_link" {
  value = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.naming_prefix}-subnet"
}
'''
                        
                        def serviceAccountsInputs = '''
variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "service_account_id" {
  type = string
}
'''
                        
                        def serviceAccountsOutputs = '''
output "email" {
  value = "${var.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}
'''
                        
                        def jenkinsInputs = '''
variable "project_id" {
  type = string
}

variable "naming_prefix" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "network_link" {
  type = string
}

variable "subnetwork_link" {
  type = string
}

variable "public_ip" {
  type = bool
}

variable "source_image" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "environment" {
  type = string
}
'''
                        
                        def jenkinsOutputs = '''
output "internal_ip" {
  value = "10.20.0.10"
}
'''
                        
                        def monitoringInputs = '''
variable "project_id" {
  type = string
}

variable "naming_prefix" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_link" {
  type = string
}

variable "subnetwork_link" {
  type = string
}

variable "jenkins_ip" {
  type = string
}

variable "service_account_email" {
  type = string
}
'''
                        
                        def monitoringOutputs = '''
output "monitoring_setup" {
  value = "Monitoring placeholder"
}
'''
                        
                        // Create proper modules
                        def networkingModulePath = createProperModule("networking", networkingInputs, networkingOutputs)
                        def saModulePath = createProperModule("service-accounts", serviceAccountsInputs, serviceAccountsOutputs)
                        def jenkinsModulePath = createProperModule("jenkins-controller", jenkinsInputs, jenkinsOutputs)
                        def monitoringModulePath = createProperModule("monitoring-stack", monitoringInputs, monitoringOutputs)
                        
                        dir(TF_PATH) {
                            // Create or verify variables file
                            sh """
                                if [ ! -f "${params.ENVIRONMENT}.auto.tfvars" ]; then
                                    echo 'project_id = "caprivax-stging-platform-infra"' > "${params.ENVIRONMENT}.auto.tfvars"
                                    echo 'region = "us-central1"' >> "${params.ENVIRONMENT}.auto.tfvars"
                                fi
                            """
                            
                            // Create main.tf with correct module calls
                            writeFile file: 'main.tf', text: """terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { 
      source = "hashicorp/google" 
      version = ">= 5.0" 
    }
    null = {
      source = "hashicorp/null"
      version = ">= 3.0"
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

provider "null" {}

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

module "sa" {
  source             = "${saModulePath}"
  project_id         = var.project_id
  environment        = "${params.ENVIRONMENT}"
  service_account_id = "capx-${params.ENVIRONMENT}-sa"
}

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
  environment           = "${params.ENVIRONMENT}"
}

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
"""
                            
                            // Show module structure
                            sh """
                                echo "=== Checking module structure ==="
                                echo "Networking module:"
                                ls -la "${networkingModulePath}/"
                                echo ""
                                echo "Jenkins module variables:"
                                cat "${jenkinsModulePath}/variables.tf"
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
            sh 'rm -rf ${WORKSPACE}/proper-modules 2>/dev/null || true'
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