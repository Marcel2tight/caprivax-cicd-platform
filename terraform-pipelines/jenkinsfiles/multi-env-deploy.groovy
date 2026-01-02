pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Select the target environment to deploy')
        booleanParam(name: 'DRY_RUN', defaultValue: true, description: 'Checked = Runs Terraform Plan only. Uncheck to Apply changes.')
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'WARNING: This will destroy all infrastructure in the selected environment.')
    }

    environment {
        // Path to the environment configuration folder
        TF_PATH = "jenkins-infrastructure/environments/${params.ENVIRONMENT}"
        
        // Ensure Terraform runs in non-interactive mode
        TF_IN_AUTOMATION = 'true'
        
        // Matches the ID you created in the Jenkins UI
        GIT_CREDENTIALS_ID = 'github-deploy-key' 
    }

    stages {
        stage('Initialize') {
            steps {
                // Ensure GCP credentials are available for backend initialization
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        dir(TF_PATH) {
                            echo "--- 🏗️ Initializing ${params.ENVIRONMENT} Backend ---"
                            // Added -reconfigure to resolve the "Backend configuration changed" error
                            sh "terraform init -backend-config=${params.ENVIRONMENT}.tfbackend -reconfigure"
                        }
                    }
                }
            }
        }

        stage('Plan') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        dir(TF_PATH) {
                            def varFile = "${params.ENVIRONMENT}.auto.tfvars"
                            def cmd = params.DESTROY ? "plan -destroy" : "plan"
                            
                            echo "--- 🔍 Running Terraform ${cmd.toUpperCase()} for ${params.ENVIRONMENT} ---"
                            sh "terraform ${cmd} -var-file=${varFile} -out=tfplan"
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            when { 
                expression { !params.DRY_RUN } 
            }
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Manual Approval Gate for Staging and Prod
                        if (params.ENVIRONMENT == 'staging' || params.ENVIRONMENT == 'prod') {
                            input message: "Approve deployment to ${params.ENVIRONMENT}?", ok: "Yes, Deploy"
                        }
                        
                        dir(TF_PATH) {
                            def cmd = params.DESTROY ? "apply -destroy" : "apply"
                            echo "--- 🚀 Applying Terraform to ${params.ENVIRONMENT} ---"
                            sh "terraform ${cmd} -auto-approve tfplan"
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment to ${params.ENVIRONMENT} successful!"
        }
        failure {
            echo "❌ Deployment to ${params.ENVIRONMENT} failed. Check the logs above."
        }
    }
}