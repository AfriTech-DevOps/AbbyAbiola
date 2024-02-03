pipeline {
    agent any
    environment{
        SCANNER_HOME=tool 'sonar-scanner'
        DOCKERHUB_CREDENTIALS=credential('dockerhub')
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
    
}