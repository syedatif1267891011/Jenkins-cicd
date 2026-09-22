pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Variables') {
            steps {
                script {

                    env.ACCOUNT_ID = sh(
                        script: 'aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()

                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.BACKEND_REPO = "${env.ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/python-backend"
                    env.FRONTEND_REPO = "${env.ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/python-frontend"

                    echo "AWS Account: ${env.ACCOUNT_ID}"
                    echo "Git SHA: ${env.GIT_SHA}"
                }
            }
        }

        stage('Login To ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region ${AWS_REGION} \
                | docker login \
                --username AWS \
                --password-stdin \
                ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                '''
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                docker build -t python-backend:${GIT_SHA} ./backend
                '''
            }
        }

        stage('Tag Backend Image') {
            steps {
                sh '''
                docker tag python-backend:${GIT_SHA} \
                ${BACKEND_REPO}:${GIT_SHA}

                docker tag python-backend:${GIT_SHA} \
                ${BACKEND_REPO}:latest
                '''
            }
        }

        stage('Push Backend Image') {
            steps {
                sh '''
                docker push ${BACKEND_REPO}:${GIT_SHA}
                docker push ${BACKEND_REPO}:latest
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                docker build \
                -t python-frontend:${GIT_SHA} \
                ./frontend
                '''
            }
        }

        stage('Tag Frontend Image') {
            steps {
                sh '''
                docker tag python-frontend:${GIT_SHA} \
                ${FRONTEND_REPO}:${GIT_SHA}

                docker tag python-frontend:${GIT_SHA} \
                ${FRONTEND_REPO}:latest
                '''
            }
        }

        stage('Push Frontend Image') {
            steps {
                sh '''
                docker push ${FRONTEND_REPO}:${GIT_SHA}
                docker push ${FRONTEND_REPO}:latest
                '''
            }
        }
    }

    post {
        success {
            // Trigger the CD pipeline if CI succeeds
            // Ensure your CD job in Jenkins is named 'python-3tier-app-cd' (or update this name)
            build job: 'python-3tier-app-cd', wait: false
        }
        always {
            sh '''
            docker image prune -af || true
            '''
        }
    }
}