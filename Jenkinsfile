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

pipeline{
    agent any

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKERHUB_CREDENTIALS = credentials('Docker_hub')
        KUBE_CONFIG = credentials('KUBECRED')
        env.KUBECONFIG = '/root/.kube/config'
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

        stage('Trivy File Scan') {
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

        stage('Kubernetes Deployment') {
            when {
                expression {
                    env.BRANCH_NAME == 'qa' || env.BRANCH_NAME == 'prod' || env.BRANCH_NAME == 'dev'
                }
            }
            steps {
                script {
                    // Determine the Kubernetes namespace
                    if (env.BRANCH_NAME == 'qa') {
                        NAMESPACE = 'qa-namespace'
                    } else if (env.BRANCH_NAME == 'prod') {
                        NAMESPACE = 'prod-namespace'
                    } else if (env.BRANCH_NAME == 'dev') {
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