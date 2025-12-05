pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Select target environment')
        booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Skip manual approval')
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'Destroy infrastructure')
    }

    environment {
        GIT_CREDENTIALS_ID = 'github-credentials'
        TF_WORKING_DIR = "jenkins-infrastructure/environments/${params.ENVIRONMENT}"
    }

    stages {
        stage('Checkout Code') { steps { checkout scm } }

        stage('Terraform Init') {
            steps {
                script {
                    dir(TF_WORKING_DIR) { sh 'terraform init' }
                }
            }
        }

        // NEW STAGE: Refresh State to fix msgpack/encoding errors
        stage('Terraform Refresh') {
            steps {
                script {
                    dir(TF_WORKING_DIR) {
                        echo "í´„ Refreshing state to prevent encoding errors..."
                        def varFile = "${params.ENVIRONMENT}.auto.tfvars"
                        sh "terraform refresh -var-file=\"${varFile}\""
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    dir(TF_WORKING_DIR) {
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
            when { expression { return !params.AUTO_APPROVE } }
            steps {
                script {
                    input message: "Approve ${params.ENVIRONMENT} deployment?", ok: "Yes"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    dir(TF_WORKING_DIR) {
                        def cmd = params.DESTROY ? "apply -destroy" : "apply"
                        sh "terraform ${cmd} -auto-approve tfplan"
                    }
                }
            }
        }
    }
}
