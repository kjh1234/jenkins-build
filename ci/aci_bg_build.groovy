pipeline {
  agent any
  stages {
    stage('INIT_PIPILINE') {
      steps {
        script {
          env.IMAGE_TAG = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${params.TAG_VERSION}"
        }

      }
    }

    stage('SCM') {
      steps {
          sh """
            if [ ! -d "tmp_source" ];then
              `mkdir tmp_source
            fi
          """
          checkout([
              $class: 'GitSCM',
              branches: [[name: "refs/tags/${TAG_VERSION}"]],
              doGenerateSubmoduleConfigurations: false,
              extensions: [[
                  $class: 'SubmoduleOption',
                  disableSubmodules: false,
                  parentCredentials: false,
                  recursiveSubmodules: false,
                  reference: '',
                  trackingSubmodules: false
                ],[
                  $class: 'RelativeTargetDirectory',
                relativeTargetDir: "${workspace}/tmp_source"
              ]],
              submoduleCfg: [],
              userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/todo-app-java-on-azure.git"]]
          ])
          sh """
            pwd
            ls
          """
      }
    }

    stage('BUILD') {
      steps {
        sh """
          pwd
          sh ./mvnw clean package -Dmaven.test.skip=true
        """
      }
    }

    stage('Create/Push Docker Image') {
      steps {
        withDockerRegistry([credentialsId: DOCKER_CREDENTIALS_ID, url: DOCKER_REGISTRY_URL]) {
            sh """
              pwd
              docker build -t "${env.IMAGE_TAG}" .
              docker push "${env.IMAGE_TAG}"
            """
        }
      }
    }

  }
  environment {
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    GIT_CREDENTIALS_ID = credentials('GIT_CREDENTIALS_ID')
    DOCKER_CREDENTIALS_ID = 'DOCKER_CREDENTIALS_ID'

    DOCKER_REGISTRY = 'innoregi.azurecr.io'
    DOCKER_REGISTRY_URL = "http://innoregi.azurecr.io"
    IMAGE_NAME = "todo-app"

  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
