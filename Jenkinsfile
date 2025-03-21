pipeline {
    agent {
        kubernetes {
            inheritFrom 'jenkins-agent'  // Use the predefined pod template in Jenkins cloud config
            defaultContainer 'jenkins'  // Use the default container for Jenkins tasks
        }
    }

    environment {
        SERVICE_NAME = "config-server"
        IMAGE_NAME = "config-server-miyembro"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        REPOSITORY_TAG = "docker.io/${DOCKERHUB_USERNAME}/${IMAGE_TAG}"
        DOCKER_HUB_CREDS_USR = "arjayfuentes24"
        DOCKER_HUB_CREDS = credentials('miyembro-docker-token')
    }

    stages {
        stage('Preparation') {
            steps {
                cleanWs()
                git credentialsId: 'GitHub', url: "https://github.com/${ORGANIZATION_NAME}/${SERVICE_NAME}", branch: 'main'
                sh 'chmod +x gradlew'
            }
        }

        stage('Check Buildah') {
            steps {
                container('buildah') {
                    script {
                        sh 'buildah --version'
                        sh 'buildah info'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                sh './gradlew clean build'
            }
        }

        stage('Build and Push Image with Buildah') {
            steps {
                container('buildah') {
                    script {
                        echo "REPOSITORY_TAG: ${REPOSITORY_TAG}"
                        echo "IMAGE_TAG: ${IMAGE_TAG}"
                        echo "IMAGE_NAME: ${IMAGE_NAME}"

                        sh "buildah bud -t ${IMAGE_NAME} ."
                        sh "buildah tag ${IMAGE_NAME} ${REPOSITORY_TAG}"
                        sh "buildah login -u ${DOCKER_HUB_CREDS_USR} -p ${DOCKER_HUB_CREDS} docker.io"
                        sh "buildah push ${REPOSITORY_TAG}"
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
            cleanWs()
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
