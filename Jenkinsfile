pipeline {
    agent any

    environment {
        SERVICE_NAME = "config-server"
        IMAGE_NAME = "config-server-miyembro"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        REPOSITORY_TAG = "docker.io/${DOCKERHUB_USERNAME}/${IMAGE_TAG}"  // Docker Hub registry
        DOCKER_HUB_CREDS_USR = "arjayfuentes24"  // Your Docker Hub username
        DOCKER_HUB_CREDS = credentials('miyembro-docker-token')  // Docker Hub credentials stored in Jenkins
    }

    stages {
        stage('Check Buildah') {
            steps {
                script {
                    sh 'buildah --version'
                    sh 'buildah info'
                }
            }
        }

        stage('Preparation') {
            steps {
                cleanWs()  // Clean workspace
                git credentialsId: 'GitHub', url: "https://github.com/${ORGANIZATION_NAME}/${SERVICE_NAME}", branch: 'main'
                sh 'chmod +x gradlew'  // Ensure Gradlew is executable
            }
        }

        stage('Build') {
            steps {
                sh './gradlew clean build'  // Build project using Gradle
            }
        }

        stage('Build and Push Image with Buildah') {
            steps {
                script {
                    echo "REPOSITORY_TAG: ${REPOSITORY_TAG}"
                    echo "IMAGE_TAG: ${IMAGE_TAG}"
                    echo "IMAGE_NAME: ${IMAGE_NAME}"

                    // Build the image using Buildah
                    sh "buildah bud -t ${IMAGE_NAME} ."

                    // Tag the image
                    sh "buildah tag ${IMAGE_NAME} ${REPOSITORY_TAG}"

                    // Authenticate with Docker Hub using credentials
                    sh "buildah login -u ${DOCKER_HUB_CREDS_USR} -p ${DOCKER_HUB_CREDS} docker.io"

                    // Push the image to Docker Hub
                    sh "buildah push ${REPOSITORY_TAG}"
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
