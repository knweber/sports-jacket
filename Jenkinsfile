pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building..'
                docker pull busybox
                docker-compose build
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                docker run --rm busybox echo "hello from docker!"
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
        stage('Cleanup') {
            steps {
                echo 'Cleaning up...'
            }
        }
    }
}
