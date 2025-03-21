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

                    // Push the container image to Docker Hub
                    sh "buildah push ${REPOSITORY_TAG}"
                }
            }
        }

        stage('Remove Previous Images') {
            steps {
                script {
                    // Get the image ID of the latest config-server-miyembro image based on creation date
                    def latest_image_id = sh(script: "buildah images --format '{{.ID}} {{.Repository}}:{{.Tag}} {{.CreatedAt}}' | grep 'config-server-miyembro' | sort -k3 -r | head -n 1 | awk '{print \$1}'", returnStdout: true).trim()

                    // List all config-server-miyembro image IDs except the latest one
                    def image_ids = sh(script: "buildah images --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep 'config-server-miyembro' | awk '{print \$1}' | grep -v '^${latest_image_id}$'", returnStdout: true).trim()

                    // Remove older images
                    if (image_ids) {
                        sh "echo 'Removing older images: ${image_ids}'"
                        sh "buildah rmi ${image_ids} || true"
                    } else {
                        echo 'No older images to remove.'
                    }
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
