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
        BRANCH_NAME = "${GIT_BRANCH.split("/")[1]}"
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
                    def imageTag = determineTargetEnvironment()
                    sh 'docker build -t abimbola1981/abbyraphee:latest .'
                    echo "Image Build Successfully"
                }
            }
        }
 
        stage('Trivy Image Scan') {
            steps {
                script {
                    def imageTag = determineTargetEnvironment()
                    sh '/usr/local/bin/trivy image abimbola1981/abbyraphee:latest > trivy_image_result.txt'
                    sh 'pwd'
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    def imageTag = determineTargetEnvironment()
                    sh 'docker push abimbola1981/abbyraphee:latest'
                    echo "Push Image to Registry"
                }
            }
        }

          stage('OWASP Scan') {
            when {
                expression {
                    BRANCH_NAME == 'qa' || BRANCH_NAME == 'prod' || BRANCH_NAME == 'dev'
                }
            }
            steps {
                script {
                    def imageTag = determineTargetEnvironment()
                    
                    // Run OWASP ZAP scan
                    sh "docker run -t --rm -v \$(pwd)/zap:/zap/wrk/:rw -i owasp/zap2docker-stable zap-baseline.py -t https://github.com/Abbyabiola/mentorshippr.git -r zap_report.html"
                    
                    // Archive the OWASP ZAP report
                    archiveArtifacts artifacts: 'zap/zap_report.html', allowEmptyArchive: true
                    
                    echo "OWASP Scan Completed"
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
