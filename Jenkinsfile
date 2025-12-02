pipeline {
    agent any

    // 1. Define Build Parameters
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select the environment to deploy to'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Check this to skip manual approval (Use with caution!)'
        )
        booleanParam(
            name: 'DESTROY',
            defaultValue: false,
            description: 'Check this to DESTROY the infrastructure instead of applying'
        )
    }

    environment {
        // Points to the Credentials ID stored in Jenkins
        GIT_CREDENTIALS_ID = 'github-credentials'
        
        // Dynamic directory path based on selection
        TF_WORKING_DIR = "jenkins-infrastructure/environments/${params.ENVIRONMENT}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "🚀 Starting deployment for environment: ${params.ENVIRONMENT}"
                }
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    dir(TF_WORKING_DIR) {
                        // Initialize the specific environment (loads correct backend)
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    dir(TF_WORKING_DIR) {
                        echo "📝 Planning changes for ${params.ENVIRONMENT}..."
                        
                        // Select the correct variables file automatically
                        def varFile = "${params.ENVIRONMENT}.auto.tfvars"
                        
                        if (params.DESTROY) {
                            sh "terraform plan -destroy -var-file=\"${varFile}\" -out=tfplan"
                        } else {
                            sh "terraform plan -var-file=\"${varFile}\" -out=tfplan"
                        }
                    }
                }
            }
        }

        stage('Approval') {
            when {
                expression { return !params.AUTO_APPROVE }
            }
            steps {
                script {
                    def action = params.DESTROY ? "DESTROY" : "APPLY"
                    input message: "Approve ${action} for ${params.ENVIRONMENT}?", ok: "Yes, Proceed"
                }
            }
        }

        stage('Terraform Apply / Destroy') {
            steps {
                script {
                    dir(TF_WORKING_DIR) {
                        if (params.DESTROY) {
                            echo "💣 Destroying ${params.ENVIRONMENT} infrastructure..."
                            sh 'terraform apply -destroy -auto-approve tfplan'
                        } else {
                            echo "🚀 Applying changes to ${params.ENVIRONMENT}..."
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully for ${params.ENVIRONMENT}"
        }
        failure {
            echo "❌ Pipeline failed for ${params.ENVIRONMENT}"
        }
    }
}