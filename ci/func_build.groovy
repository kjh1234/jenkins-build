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
            extensions: [
              [
                $class: 'SubmoduleOption',
                disableSubmodules: false,
                parentCredentials: false,
                recursiveSubmodules: false,
                reference: '',
                trackingSubmodules: false
              ]
            ],
            submoduleCfg: [],
            userRemoteConfigs: [
              [credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/azure-functions-samples-java.git"]]
            // userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/hello-spring-function-azure.git"]]
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

            cd ${workspace}/target/azure-functions/inno-func-app && zip -r ../../../azure-functions-samples-${params.TAG_VERSION}.zip ./* && cd -
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
              -F maven2.artifactId=azure-${IMAGE_NAME} \
              -F maven2.version=${params.TAG_VERSION} \
              -F maven2.asset1=@${workspace}/azure-functions-samples-${params.TAG_VERSION}.zip \
              -F maven2.asset1.extension=zip \
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
    NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'
    RESOURCE_GROUP = 'func-tf-jenkins'
    FUNC_NAME = 'inno-tf-func-app'
    REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    IMAGE_REPOSITORY = "sk-maven-hosted"
    IMAGE_GROUP = "com.functions"
    IMAGE_NAME = "azure-functions-samples"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
