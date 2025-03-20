pipeline {

  agent {
    kubernetes {
      yamlFile 'kaniko-builder.yaml'
    }
  }

  environment {
          // You must set the following environment variables
          // ORGANIZATION_NAME
          // DOCKERHUB_USERNAME (it doesn't matter if you don't have one)
          SERVICE_NAME = "config-server"
          IMAGE_NAME = "config-server-miyembro"
          IMAGE_NAME_AND_USER = "${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
          IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
          REPOSITORY_TAG = "${DOCKERHUB_USERNAME}/${IMAGE_TAG}"
          DOCKER_HUB_CREDS = credentials('miyembro-docker-token')  // Use the ID of your Docker Hub credentials
      }

  stages {

    stage("Cleanup Workspace") {
      steps {
        cleanWs()
      }
    }

    stage("Checkout from SCM"){
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/${ORGANIZATION_NAME}/${SERVICE_NAME}'
            }

        }

    stage('Build & Push with Kaniko') {
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          sh '''#!/busybox/sh

            /kaniko/executor --dockerfile `pwd`/Dockerfile --context `pwd` --destination=${REPOSITORY_TAG} --destination=${IMAGE_NAME_AND_USER}:latest
          '''
        }
      }
    }
  }
}