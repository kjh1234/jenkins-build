pipeline {
  agent any
  stages {

//    stage('SCM') {
//      steps {
//        echo ' The SCM'
//        script {          
//          if (params.TAG_VERSION == '') {
//            error "TAG_VERSION is required"
//          }
//          
//          echo params.TAG_VERSION
//          
//          checkout([
//              $class: 'GitSCM', 
//              branches: [[name: "refs/tags/${params.TAG_VERSION}"]],
//              doGenerateSubmoduleConfigurations: false, 
//              extensions: [[
//                  $class: 'SubmoduleOption', 
//                  disableSubmodules: false, 
//                  parentCredentials: false, 
//                  recursiveSubmodules: false, 
//                  reference: '', 
//                  trackingSubmodules: false
//              ]], 
//              submoduleCfg: [], 
//              userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/azure-functions-samples-java.git"]]
//          ])
//        }
//
//      }
//    }
//
//    stage('Function Build/Deploy') {
//      steps {
//        // check the current active environment to determine the inactive one that will be deployed to
//
//        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
//            // fetch the current service configuration
//            sh """
//              az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
//              az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
//              
//	      chmod 764 ./mvnw
//              ./mvnw clean package azure-functions:deploy
//            """
//        }
//      }
//    }

    stage('SCM') {
      steps {
        checkout scm
      }
    }
	  
    stage('Image Download') {
      steps {
        withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh """
	    curl -o ${IMAGE_NAME}-${params.TAG_VERSION}.zip -L -u '${USERNAME}:${PASSWORD}' \ 
	      -X GET '${REPOSITORY_API}/search/assets/download?repository=${IMAGE_REPOSITORY}&group=${IMAGE_GROUP}&name=${IMAGE_NAME}&version=${params.TAG_VERSION}&maven.extension=zip'
	    
	    ls -al
	  """
        }
      }
    }
	  
//     stage('Destroy') {
//       steps {
// 	    script {
//           sh """
//           az logout
//           """
// 	    }
//       }
//     }
  }
  
  environment {
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    INNO_AZURE_CREDENTIALS = "INNO_AZURE_CREDENTIALS"
    GIT_CREDENTIALS_ID = credentials('GIT_CREDENTIALS_ID')
    NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'
    REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    IMAGE_REPOSITORY = "sk-maven-hosted"
    IMAGE_GROUP = "com.functions"
    IMAGE_NAME = "azure-functions-samples"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
