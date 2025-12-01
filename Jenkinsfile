pipeline {
    agent any
    
    triggers {
        githubPush()  // Auto-trigger on push
    }
    
    stages {
        stage('Hello CI/CD') {
            steps {
                echo 'Ì∫Ä Caprivax CI/CD Platform Pipeline'
                echo "Repository: ${env.GIT_URL}"
                echo "Branch: ${env.GIT_BRANCH}"
                sh 'terraform version'
                sh 'gcloud version'
                sh 'docker --version'
            }
        }
        
        stage('Check Project Structure') {
            steps {
                sh '''
                    echo "Project Contents:"
                    ls -la
                    echo ""
                    echo "Jenkins Infrastructure:"
                    find jenkins-infrastructure -type f -name "*.tf" | head -5
                '''
            }
        }
    }
    
    post {
        success {
            echo '‚úÖ Pipeline succeeded! Ready for CI/CD workflows.'
        }
        failure {
            echo '‚ùå Pipeline failed. Check logs.'
        }
    }
}
