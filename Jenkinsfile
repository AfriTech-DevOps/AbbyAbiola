pipeline {
    agent any

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKERHUB_CREDENTIALS = credentials('Docker_hub')
        KUBE_CONFIG = credentials('KUBECRED')
        NAMESPACE = determineTargetEnvironment()
    }

    stages {
        stage('Checkout from Git') {
            steps {
                cleanWs() // Clean workspace before checking out code
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/dev'], [name: '*/qa'], [name: '*/prod']],
                    extensions: [],
                    userRemoteConfigs: [[url: 'https://github.com/Abbyabiola/mentorshippr.git']]])
            }
        }

        stage('Code Analysis') {
            steps {
                script {
                    // Run SonarQube analysis
                    withSonarQubeEnv('sonar-server') {
                        sh "$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Devproject -Dsonar.projectKey=Devproject"
                    }
                }
            }
        }

        stage('Static Code Security Scan') {
            steps {
                script {
                    // Run Trivy security scan on code files
                    sh '/usr/local/bin/trivy fs . > trivy_result.txt'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    // Wait for SonarQube Quality Gate to pass
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-Token'
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                script {
                    // Build Docker image and push to Docker Hub
                    sh 'docker build -t abimbola1981/abbyraphee:latest .'
                    sh 'docker login -u $DOCKERHUB_CREDENTIALS_USR -p $DOCKERHUB_CREDENTIALS_PSW'
                    sh 'docker push abimbola1981/abbyraphee:latest'
                    echo "Image Build and Pushed Successfully"
                }
            }
        }

        stage('Kubernetes Deployment') {
            when {
                expression {
                    BRANCH_NAME == 'qa' || BRANCH_NAME == 'prod' || BRANCH_NAME == 'dev'
                }
            }
            steps {
                script {
                    // Determine the Kubernetes namespace
                    if (BRANCH_NAME == 'qa') {
                        NAMESPACE = 'qa-namespace'
                    } else if (BRANCH_NAME == 'prod') {
                        NAMESPACE = 'prod-namespace'
                    } else if (BRANCH_NAME == 'dev') {
                        NAMESPACE = 'dev-namespace'
                    }

                    // Apply Kubernetes manifests
                    sh "kubectl apply -f k8s/${NAMESPACE}/"
                    echo "Deployment to ${NAMESPACE} Namespace Successful"
                }
            }
        }
    }
}
