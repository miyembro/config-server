pipeline {
    agent {
        kubernetes {
            label 'buildah-agent' // Label the pod
            defaultContainer 'buildah' // Set the Buildah container as the default for commands
            yaml """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-pod
spec:
  containers:
    - name: buildah
      image: quay.io/buildah/stable
      securityContext:
        privileged: true  # Required for Buildah to work
      command: ["sleep", "infinity"]
      volumeMounts:
        - name: containers-storage
          mountPath: /var/lib/containers  # Shared storage for Buildah
  volumes:
    - name: containers-storage
      emptyDir: {}  # Ephemeral storage for Buildah
"""
        }
    }

    environment {
        SERVICE_NAME = "config-server"
        IMAGE_NAME = "config-server-miyembro"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        REPOSITORY_TAG = "quay.io/${DOCKERHUB_USERNAME}/${IMAGE_TAG}"  // Ensure the registry is correct
        DOCKER_HUB_CREDS_USR = "arjayfuentes24"
        DOCKER_HUB_CREDS = credentials('miyembro-docker-token')  // Docker Hub or Quay credentials
    }

    stages {
        stage('Check Buildah') {
            steps {
                script {
                    container('buildah') {
                        sh 'buildah --version'
                        sh 'buildah info'
                    }
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

                    // Run Buildah commands inside the Buildah container
                    container('buildah') {
                        // Build the image using Buildah
                        sh "buildah bud -t ${IMAGE_NAME} ."

                        // Tag the image
                        sh "buildah tag ${IMAGE_NAME} ${REPOSITORY_TAG}"

                        // Authenticate (if needed)
                        sh "buildah login -u ${DOCKER_HUB_CREDS_USR} -p ${DOCKER_HUB_CREDS} quay.io"

                        // Push the image
                        sh "buildah push ${REPOSITORY_TAG}"
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
