pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select the target environment to deploy'
        )
        booleanParam(
            name: 'DRY_RUN',
            defaultValue: true,
            description: 'If checked, only runs Terraform Plan. Uncheck to Apply.'
        )
        booleanParam(
            name: 'DESTROY',
            defaultValue: false,
            description: 'WARNING: Destroys infrastructure if checked.'
        )
    }

    environment {
        // Path to the environment configuration folder
        TF_PATH = "jenkins-infrastructure/environments/${params.ENVIRONMENT}"
        
        // Credential ID configured in Jenkins UI
        GIT_CREDENTIALS_ID = 'github-credentials'
        
        // Ensure Terraform runs in non-interactive mode
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Initialize') {
            steps {
                script {
                    dir(TF_PATH) {
                        echo "--- ÌøóÔ∏è Initializing ${params.ENVIRONMENT} Backend ---"
                        // Updated to use the environment-specific .tfbackend file
                        sh "terraform init -backend-config=${params.ENVIRONMENT}.tfbackend -reconfigure"
                    }
                }
            }
        }

        stage('Plan') {
            steps {
                script {
                    dir(TF_PATH) {
                        def varFile = "${params.ENVIRONMENT}.auto.tfvars"
                        def cmd = params.DESTROY ? "plan -destroy" : "plan"
                        
                        echo "--- Ì≥ã Running Terraform ${cmd.toUpperCase()} ---"
                        
                        // Smart Plan Logic: Workaround for Terraform Msgpack bugs.
                        // If tfplan exists after the command, we consider it a success.
                        sh """
                        set +e
                        terraform ${cmd} -var-file=${varFile} -out=tfplan 2>&1 | tee plan.log
                        if [ -f tfplan ]; then
                            echo "‚úÖ Plan file created successfully."
                            exit 0
                        else
                            echo "‚ùå Plan failed. No plan file created."
                            exit 1
                        fi
                        """
                        
                        // Generate human-readable JSON for logging
                        sh "terraform show -json tfplan > plan.json"
                    }
                }
            }
        }

        stage('Deploy') {
            when { 
                expression { !params.DRY_RUN } 
            }
            steps {
                script {
                    // Manual Approval Gate for Staging and Prod to prevent accidental disasters
                    if (params.ENVIRONMENT == 'staging' || params.ENVIRONMENT == 'prod') {
                        input message: "Approve deployment to ${params.ENVIRONMENT}?", ok: "Yes, Deploy"
                    }
                    
                    dir(TF_PATH) {
                        def cmd = params.DESTROY ? "apply -destroy" : "apply"
                        
                        echo "--- Ì∫Ä Applying Terraform to ${params.ENVIRONMENT} ---"
                        sh "terraform ${cmd} -auto-approve tfplan"
                    }
                }
            }
        }
    }

    post {
        success {
            // Only attempts to send if Slack plugin is configured
            echo "Deployment successful!"
            catchError(buildStepFailure: false, stageFailure: false) {
                slackSend(
                    color: 'good',
                    message: "‚úÖ DEPLOY SUCCESS: ${params.ENVIRONMENT}\nBuild: ${env.BUILD_URL}"
                )
            }
        }
        failure {
            echo "Deployment failed!"
            catchError(buildStepFailure: false, stageFailure: false) {
                slackSend(
                    color: 'danger',
                    message: "‚ùå DEPLOY FAILED: ${params.ENVIRONMENT}\nCheck Logs: ${env.BUILD_URL}"
                )
            }
        }
    }
}
