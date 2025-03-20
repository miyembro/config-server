pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kaniko-agent
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      command:
        - /kaniko/executor  # Kaniko entry point
      args:
        - --context=dir:///workspace
        - --dockerfile=/workspace/Dockerfile
        - --destination=docker.io/${DOCKERHUB_USERNAME}/config-server:${BUILD_NUMBER}
      tty: true
      volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker/  # Mount Docker credentials
  volumes:
    - name: kaniko-secret
      secret:
        secretName: docker-hub-secret  # Ensure this secret exists and is correct
"""
        }
    }

    environment {
        ORGANIZATION_NAME = "miyembro"
        SERVICE_NAME = "config-server"
        IMAGE_NAME = "config-server-miyembro"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        REPOSITORY_TAG = "${DOCKERHUB_USERNAME}/${IMAGE_TAG}"
        DOCKER_HUB_CREDS = credentials('miyembro-docker-token')  // Docker Hub Credentials
    }

    stages {
        stage('Preparation') {
            steps {
                cleanWs()
                git credentialsId: 'GitHub', url: "https://github.com/${ORGANIZATION_NAME}/${SERVICE_NAME}", branch: 'main'
                sh 'chmod +x gradlew'
            }
        }

        stage('Build') {
            steps {
                sh './gradlew clean build'
            }
        }

        stage('Build and Push Image with Kaniko') {
            steps {
                container('kaniko') {
                    script {
                        // Debugging logs for Kaniko container
                        sh 'echo "Running Kaniko build..."'
                        sh '/kaniko/executor --context=dir:///workspace --dockerfile=/workspace/Dockerfile --destination=docker.io/${DOCKERHUB_USERNAME}/config-server:${BUILD_NUMBER}'
                    }
                }
            }
        }

        stage('Deploy to Cluster') {
            steps {
                sh 'envsubst < ${WORKSPACE}/deploy.yaml | kubectl apply -f -'
            }
        }
    }

    post {
        always {
            script {
                // Ensure cleanWs() is wrapped in a node context
                node {
                    cleanWs()
                }
            }
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
