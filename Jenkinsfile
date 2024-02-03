pipeline {
    agent any

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKERHUB_CREDENTIALS = credentials('Docker_hub')
        KUBE_CONFIG = credentials('KUBECRED')
       
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
        archiveArtifacts artifacts: 'trivy_result.txt', onlyIfSuccessful: true
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
                sh 'trivy image --exit-code 0 --severity HIGH,CRITICAL --no-progress abimbola1981/abbyraphee:latest'
            }
        }

        stage('Docker Push') {
            steps {
                sh 'docker push abimbola1981/abbyraphee:latest'
                echo "Push Image to Registry"
            }
        }
    }
}
