pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Select target environment')
        booleanParam(name: 'DRY_RUN', defaultValue: true, description: 'Checked = Plan only. Uncheck to Apply.')
        string(name: 'ROLLBACK_COMMIT', defaultValue: '', description: 'Enter Git Commit Hash to rollback (leave empty for latest).')
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'WARNING: This will destroy the environment.')
    }

    environment {
        TF_PATH = "jenkins-infrastructure/environments/${params.ENVIRONMENT}"
        TF_IN_AUTOMATION = 'true'
        SLACK_CHANNEL = '#deployments' 
    }

    stages {
        stage('Checkout & Rollback Sync') {
            steps {
                script {
                    if (params.ROLLBACK_COMMIT != '') {
                        echo "⚠️ Initiating Rollback to: ${params.ROLLBACK_COMMIT}"
                        sh "git checkout ${params.ROLLBACK_COMMIT}"
                        env.GIT_AUTHOR = "Rollback System"
                        env.GIT_SUBJECT = "Reverting to stable version ${params.ROLLBACK_COMMIT}"
                    } else {
                        env.GIT_AUTHOR = sh(script: "git log -1 --pretty=format:'%an'", returnStdout: true).trim()
                        env.GIT_SUBJECT = sh(script: "git log -1 --pretty=format:'%s'", returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Initialize & Patch') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        dir(TF_PATH) {
                            echo "--- 🛠️ Injecting Dynamic main.tf ---"
                            sh '''
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
                              source             = "../../../modules/networking"
                              project_id         = var.project_id
                              naming_prefix      = "capx-${params.ENVIRONMENT}"
                              region             = var.region
                              subnet_cidr        = "10.20.0.0/24"
                              environment        = "${params.ENVIRONMENT}"
                              allowed_web_ranges = ["0.0.0.0/0"]
                              allowed_ssh_ranges = ["35.235.240.0/20"] 
                            }
                            module "sa" {
                              source             = "../../../modules/service-accounts"
                              project_id         = var.project_id
                              environment        = "${params.ENVIRONMENT}"
                              service_account_id = "capx-${params.ENVIRONMENT}-sa"
                            }
                            module "jenkins" {
                              source                = "../../../modules/jenkins-controller"
                              project_id            = var.project_id
                              naming_prefix         = "capx-${params.ENVIRONMENT}"
                              zone                  = "${var.region}-b"
                              machine_type          = "e2-standard-2"
                              network_link          = module.net.vpc_link
                              subnetwork_link       = module.net.subnet_link
                              public_ip             = true
                              source_image          = "debian-cloud/debian-11"
                              service_account_email = module.sa.email
                            }
                            module "mon" {
                              source                = "../../../modules/monitoring-stack"
                              project_id            = var.project_id
                              naming_prefix         = "capx-${params.ENVIRONMENT}"
                              zone                  = "${var.region}-b"
                              network_link          = module.net.vpc_link
                              subnetwork_link       = module.net.subnet_link
                              jenkins_ip            = module.jenkins.internal_ip
                              service_account_email = module.sa.email
                            }
EOF
                            '''
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
                        script {
                            def cmd = params.DESTROY ? "plan -destroy" : "plan"
                            sh "terraform ${cmd} -var-file=${params.ENVIRONMENT}.auto.tfvars -out=tfplan"
                        }
                    }
                }
            }
        }

        stage('Apply/Rollback') {
            when { expression { !params.DRY_RUN } }
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        if (params.ENVIRONMENT == 'staging' || params.ENVIRONMENT == 'prod') {
                            input message: "Approve deployment to ${params.ENVIRONMENT}?", ok: "Yes, Deploy"
                        }
                        dir(TF_PATH) {
                            def cmd = params.DESTROY ? "apply -destroy" : "apply"
                            sh "terraform ${cmd} -auto-approve tfplan"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            dir(TF_PATH) { sh "rm -f tfplan" }
        }
        success {
            slackSend(channel: env.SLACK_CHANNEL, color: 'good', 
                message: "✅ *Success*: ${params.ENVIRONMENT.toUpperCase()} updated by *${env.GIT_AUTHOR}*.\n*Change*: ${env.GIT_SUBJECT}\n*Build*: ${env.BUILD_URL}")
        }
        failure {
            slackSend(channel: env.SLACK_CHANNEL, color: 'danger', 
                message: "❌ *Failure*: ${params.ENVIRONMENT.toUpperCase()} failed for *${env.GIT_AUTHOR}*.\n*Logs*: ${env.BUILD_URL}console")
        }
    }
}