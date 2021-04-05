pipeline {
  agent any
  stages {
    stage('SCM') {
      steps {
        echo ' The SCM'
        script {
          if (params.TAG_VERSION == '') {
            error "TAG_VERSION is required"
          }

          echo params.TAG_VERSION

          checkout([
              $class: 'GitSCM',
              branches: [[name: "refs/tags/${params.TAG_VERSION}"]],
              doGenerateSubmoduleConfigurations: false,
              extensions: [[
                  $class: 'SubmoduleOption',
                  disableSubmodules: false,
                  parentCredentials: false,
                  recursiveSubmodules: false,
                  reference: '',
                  trackingSubmodules: false
              ]],
              submoduleCfg: [],
              userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/todo-app-java-on-azure.git"]]
          ])
        }

      }
    }

    stage('Function Build') {
      steps {
        withCredentials(bindings: [azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh """
            az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
            az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
            chmod 764 ./mvnw
            ./mvnw clean package
          """
        }

      }
    }

    stage('Image Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh """
            curl -v -u '${USERNAME}:${PASSWORD}' POST '${REPOSITORY_API}/components?repository=${IMAGE_REPOSITORY}' \
              -F maven2.groupId=${IMAGE_GROUP} \
              -F maven2.artifactId=${IMAGE_NAME} \
              -F maven2.version=${params.TAG_VERSION} \
              -F maven2.asset1=@${workspace}/target/${IMAGE_NAME}-${params.TAG_VERSION}.jar \
              -F maven2.asset1.extension=jar \
              -F maven2.generate-pom=true
          """
        }
      }
    }

    stage('Destroy') {
      steps {
        script {
          sh """
          az logout
          """
        }

      }
    }

  }
  environment {
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    GIT_CREDENTIALS_ID = credentials('GIT_CREDENTIALS_ID')

    REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    IMAGE_REPOSITORY = "sk-maven-hosted"
    IMAGE_GROUP = "com.microsoft.azure.sample"
    IMAGE_NAME = "todo-app-java-on-azure"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
