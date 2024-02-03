pipeline {
    agent any

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKERHUB_CREDENTIALS = credentials('Docker_hub')
        KUBE_CONFIG = credentials('KUBECRED')
        NAMESPACE = ''
       
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
        sh '/usr/local/bin/trivy fs . > trivy_result.txt'
       sh '/usr/local/bin/trivy --exit-code 0 --severity HIGH,CRITICAL --no-progress abimbola1981/webapp:latest'

            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }

        stage('Login to DockerHUB') {
            steps {
                sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                echo 'Login Succeeded'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t abimbola1981/abbyraphee:latest .' 
                echo "Image Build Successfully"
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '/usr/local/bin/trivy image abimbola1981/abbyraphee:latest > trivy_image_result.txt'
                sh 'pwd'
                sh 'ls -l'
            }
        }

        stage('Docker Push') {
            steps {
                sh 'docker push abimbola1981/abbyraphee:latest'
                echo "Push Image to Registry"
            }
        }
        stage('Deployment to Kubernetes') {
            when {
                anyOf {
                    branch 'qa'
                    branch 'prod'
                    branch 'dev'
                }
            }
            steps {
                script {
                    if (BRANCH_NAME == 'qa') {
                        NAMESPACE = 'qa-namespace'
                    } else if (BRANCH_NAME == 'prod') {
                        NAMESPACE = 'prod-namespace'
                    } else if (BRANCH_NAME == 'dev') {
                        NAMESPACE = 'dev-namespace'
                    }

                    // Apply Kubernetes manifests
                    sh "kubectl apply -f k8s/${NAMESPACE}/"
                }
            }
        }
    }
}
