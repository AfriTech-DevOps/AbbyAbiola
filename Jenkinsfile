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
    }
}

