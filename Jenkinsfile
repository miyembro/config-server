pipeline {
    agent any

    environment {
        // You must set the following environment variables
        // ORGANIZATION_NAME
        // DOCKERHUB_USERNAME (it doesn't matter if you don't have one)
        SERVICE_NAME = "config-server"
        IMAGE_NAME = "config-server-miyembro"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        REPOSITORY_TAG = "${DOCKERHUB_USERNAME}/${IMAGE_TAG}"
        DOCKER_HUB_CREDS = credentials('miyembro-docker-token')  // Use the ID of your Docker Hub credentials
    }

    stages {
        stage('Preparation') {
            steps {
                cleanWs()  // Clean the workspace
                git credentialsId: 'GitHub', url: "https://github.com/${ORGANIZATION_NAME}/${SERVICE_NAME}", branch: 'main'  // Clone the repository
                sh 'chmod +x gradlew'  // Add execute permission to gradlew
            }
        }

        stage('Debug Workspace') {
            steps {
                sh 'pwd'  // Print current working directory
                sh 'ls -la'  // List files in the workspace
            }
        }

        stage('Build') {
            steps {
                sh './gradlew clean build'  // Build the project using Gradle
            }
        }

        stage('Build and Push Image') {
            steps {
                script {
                    echo "REPOSITORY_TAG: ${REPOSITORY_TAG}"
                    echo "IMAGE_TAG: ${IMAGE_TAG}"
                    echo "IMAGE_NAME: ${IMAGE_NAME}"

                    // Authenticate with Docker Hub using Buildah
                    sh "buildah login -u ${DOCKER_HUB_CREDS_USR} -p ${DOCKER_HUB_CREDS_PSW} docker.io"

                    // Build the container image using Buildah
                    sh "buildah bud -t ${IMAGE_NAME} ."

                    // Tag the container image for the repository
                    sh "buildah tag ${IMAGE_NAME} ${REPOSITORY_TAG}"

                    // Tag the image as 'latest'
                    sh "buildah tag ${IMAGE_NAME} ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"

                    // Push the container image to Docker Hub
                    sh "buildah push ${REPOSITORY_TAG}"

                    // Push the latest tag as well
                    sh "buildah push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"

                }
            }
        }

        stage('Deploy to Cluster') {
            steps {
                sh 'envsubst < ${WORKSPACE}/deploy.yaml | kubectl apply -f -'  // Deploy to Kubernetes
            }
        }
    }

    post {
        always {
            cleanWs()  // Clean the workspace
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
