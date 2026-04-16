pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'harshshahu/basic-web-application'
        DOCKER_HUB_CREDENTIALS = 'dockerhub-credentials'
        GIT_REPO = 'https://github.com/harshshahu/GitHub-Docker-Jenkins-Node.js-Project.git'
        IMAGE_TAG = "${BUILD_NUMBER}"
        TEST_CONTAINER = "test-container-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    dockerImage = docker.build("${DOCKER_HUB_REPO}:${IMAGE_TAG}")
                    dockerImage.tag("latest")  
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo 'Running container for testing...'
                    try {
                        sh """
                            docker run -d --name ${TEST_CONTAINER} -p 3001:3000 ${DOCKER_HUB_REPO}:${IMAGE_TAG}

                            for i in {1..10}; do
                                echo "Waiting for application to be ready... Attempt $i"
                                curl -f http://localhost:3001/api/hello && break
                                sleep 3
                            done

                            curl -f http://localhost:3001/api/hello
                        """
                    } finally {
                        sh """
                            docker stop ${TEST_CONTAINER} || true
                            docker rm ${TEST_CONTAINER} || true
                        """
                    }
                }
            }
        }

        stage('Push Image') {
            steps {
                script {
                    echo 'Pushing image to Docker Hub...'
                    docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_HUB_CREDENTIALS}") {
                        dockerImage.push("${IMAGE_TAG}")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying application...'
                    sh """
                        docker stop basic-webapp || true
                        docker rm basic-webapp || true
                        docker run -d --name basic-webapp -p 3000:3000 ${DOCKER_HUB_REPO}:latest
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    echo 'Checking application health...'
                    sh """
                        for i in {1..10}; do
                            curl -f http://localhost:3000/api/hello && exit 0
                            sleep 3
                        done
                        echo "Health check failed!"
                        exit 1
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker...'
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}