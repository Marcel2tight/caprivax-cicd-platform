pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Select environment')
        booleanParam(name: 'DRY_RUN', defaultValue: true, description: 'Checked = Plan only.')
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'WARNING: Destroys infrastructure.')
    }

    environment {
        TF_PATH = "jenkins-infrastructure/environments/${params.ENVIRONMENT}"
        // Matches the ID you created in the Jenkins UI
        GIT_CREDENTIALS_ID = 'github-deploy-key' 
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Initialize') {
            steps {
                withCredentials([file(credentialsId: 'gcp-dev-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        dir(TF_PATH) {
                            echo "--- 🛠️ Initializing ${params.ENVIRONMENT} Backend ---"
                            // Simplified: Just point to the file you already have!
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
                            echo "--- 🔍 Running Terraform ${cmd.toUpperCase()} ---"
                            sh """
                            terraform ${cmd} -var-file=${varFile} -out=tfplan
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy') {
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
    // ... post block remains the same ...
}