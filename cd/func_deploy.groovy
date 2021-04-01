pipeline {
  agent any
  stages {

    stage('SCM') {
      steps {
        checkout scm
      }
    }
	  
    stage('Image Download') {
      steps {
        withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh """
	    curl -o ${IMAGE_NAME}-${params.TAG_VERSION}.zip -L -u '${USERNAME}:${PASSWORD}' \\
	      -X GET '${REPOSITORY_API}/search/assets/download?repository=${IMAGE_REPOSITORY}&group=${IMAGE_GROUP}&name=${IMAGE_NAME}&version=${params.TAG_VERSION}&maven.extension=zip'
	    
	    ls -al
	  """
        }
      }
    }

    stage('function stage Deploy') {
      steps {
        withCredentials(bindings: [azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh """
            az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
            az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
	    
            az functionapp deployment slot create -g ${RESOURCE_GROUP} -n ${FUNC_NAME} --slot stage
            az functionapp deployment source config-zip -g ${RESOURCE_GROUP} -n ${FUNC_NAME} --slot stage --src ./${IMAGE_NAME}-${params.TAG_VERSION}.zip
          """
        }
      }
    }

    stage('Switch') {
      steps {
        input("Switch Prod Proceed or Abort?")

        sh "az functionapp deployment slot swap -g func-tf-jenkins -n inno-tf-func-app --slot stage --target-slot production"
      }
    }

    stage('Delete Stage') {
      steps {
        script {
          result = input(message: 'Delete Stage-Slot?', ok: 'Proceed', parameters: [booleanParam(defaultValue: true, name: 'Yes?')])
          if (result == true) {
            sh "az functionapp deployment slot delete -g ${RESOURCE_GROUP} -n ${FUNC_NAME} --slot stage"
          }
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
    INNO_AZURE_CREDENTIALS = "INNO_AZURE_CREDENTIALS"
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
