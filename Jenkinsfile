pipeline {
    agent any
    
    triggers {
        githubPush()
    }
    
    stages {
        stage('Check Tools') {
            steps {
                echo '🔧 Checking installed tools...'
                
                script {
                    // Check each tool and continue even if missing
                    def tools = ['terraform', 'docker', 'gcloud', 'git', 'java']
                    
                    tools.each { tool ->
                        try {
                            sh "${tool} --version"
                            echo "✅ ${tool.capitalize()} is installed"
                        } catch (Exception e) {
                            echo "⚠️  ${tool.capitalize()} is NOT installed"
                        }
                    }
                }
            }
        }
        
        stage('Hello CI/CD') {
            steps {
                echo '🚀 Caprivax CI/CD Platform Pipeline'
                echo "Repository: ${env.GIT_URL}"
                echo "Branch: ${env.GIT_BRANCH}"
                
                // Use which to check if installed
                sh '''
                    echo "=== Tool Locations ==="
                    which terraform || echo "terraform: Not installed"
                    which docker || echo "docker: Not installed" 
                    which gcloud || echo "gcloud: Not installed"
                    which java || echo "java: Not installed"
                    which git || echo "git: Not installed"
                '''
            }
        }
        
        stage('Check Project Structure') {
            steps {
                sh '''
                    echo "=== Project Structure ==="
                    pwd
                    ls -la
                    echo ""
                    echo "=== Jenkins Infrastructure Files ==="
                    find jenkins-infrastructure -type f -name "*.tf" | head -10 || echo "No .tf files found"
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline succeeded! Ready for CI/CD workflows.'
        }
        failure {
            echo '❌ Pipeline failed. Check logs.'
        }
        always {
            echo '📊 Pipeline execution completed.'
        }
    }
}