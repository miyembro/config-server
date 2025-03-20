pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jenkins
    image: arjayfuentes24/miyembro-jenkins:latest
    volumeMounts:
    - name: workspace
      mountPath: /var/jenkins_home
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args: ["--dockerfile=Dockerfile", "--context=dir:///workspace", "--destination=\${env.REPOSITORY_TAG}"]
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    - name: secret-volume
      mountPath: /kaniko/.docker
  volumes:
  - name: workspace
    emptyDir: {}
  - name: secret-volume
    secret:
      secretName: regcred
      items:
      - key: .dockerconfigjson
        path: config.json
"""
        }
    }

    environment {
        SERVICE_NAME = "config-server"
        IMAGE_NAME = "config-server-miyembro"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        REPOSITORY_TAG = "${DOCKERHUB_USERNAME}/${IMAGE_TAG}"
        DOCKER_HUB_CREDS = credentials('miyembro-docker-token')  // Use your Docker Hub credentials ID
    }

    stages {
        stage('Preparation') {
            steps {
                node('any') {
                    cleanWs()
                }
                git credentialsId: 'GitHub', url: "https://github.com/${ORGANIZATION_NAME}/${SERVICE_NAME}", branch: 'main'
                sh 'chmod +x gradlew'  // Ensure Gradle wrapper is executable
            }
        }

        stage('Build') {
            steps {
                sh './gradlew clean build'  // Build the project using Gradle
            }
        }

        stage('Build and Push Image') {
            steps {
                container('kaniko') {
                    script {
                        echo "REPOSITORY_TAG: ${REPOSITORY_TAG}"
                        echo "IMAGE_TAG: ${IMAGE_TAG}"
                        echo "IMAGE_NAME: ${IMAGE_NAME}"

                        // Kaniko builds and pushes the image
                        sh """
                        /kaniko/executor \
                            --dockerfile=Dockerfile \
                            --context=dir:///workspace \
                            --destination=${REPOSITORY_TAG}
                        """
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
           node('any') {
               cleanWs()
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
