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
        stage('Checkout') { steps { checkout scm } }
        stage('Init') { steps { script { dir(TF_WORKING_DIR) { sh 'terraform init' } } } }
        stage('Plan') { steps { script { dir(TF_WORKING_DIR) { sh "terraform plan -var-file=\"${params.ENVIRONMENT}.auto.tfvars\" -out=tfplan" } } } }
        stage('Apply') {
            when { expression { return !params.AUTO_APPROVE } }
            steps { input message: "Deploy to ${params.ENVIRONMENT}?", ok: "Yes" }
        }
        stage('Deploy') { steps { script { dir(TF_WORKING_DIR) { sh "terraform apply -auto-approve tfplan" } } } }
    }
}
