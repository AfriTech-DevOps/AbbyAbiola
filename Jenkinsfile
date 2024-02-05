def determineTargetEnvironment() {
    def branchName = env.BRANCH_NAME
    if (branchName == 'qa') {
        return 'qa-namespace'
    } else if (branchName == 'prod') {
        return 'prod-namespace'
    } else if (branchName == 'dev') {
        return 'dev-namespace'
    } else {
        return 'default-namespace'
    }
}

pipeline {
    agent any

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKERHUB_CREDENTIALS = credentials('Docker_hub')
        KUBE_CONFIG = credentials('KUBECRED')
        NAMESPACE = determineTargetEnvironment()
    }

    stages {
        stage('Cleaning up workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/dev'], [name: '*/qa'], [name: '*/prod']],
                    extensions: [],
                    userRemoteConfigs: [[url: 'https://github.com/Abbyabiola/mentorshippr.git']]])
            }
        }

        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh "$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Devproject -Dsonar.projectKey=Devproject"
                }
            }
        }

        stage('Trivy File Scan') {
            steps {
                script {
                    sh '/usr/local/bin/trivy fs . > trivy_result.txt'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-Token'
                }
            }
        }

        stage('Login to DockerHUB') {
            steps {
                script {
                    sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                    echo 'Login Succeeded'
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    sh 'docker build -t abimbola1981/abbyraphee:latest .'
                    echo "Image Build Successfully"
                }
            }
        }
 
        stage('Trivy Image Scan') {
            steps {
                script {
                    sh '/usr/local/bin/trivy image abimbola1981/abbyraphee:latest > trivy_image_result.txt'
                    sh 'pwd'
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    sh 'docker push abimbola1981/abbyraphee:latest'
                    echo "Push Image to Registry"
                }
            }
        }

        stage('Build and Deploy') {
            when {
                expression {
                    BRANCH_NAME == 'qa' || BRANCH_NAME == 'prod' || BRANCH_NAME == 'dev'
                }
            }
            steps {
                script {
                    // Set the Kubernetes namespace based on the branch
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
