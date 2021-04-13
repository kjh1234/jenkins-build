def currentBackend
def newBackend = { ->
  currentBackend == 'blue' ? 'green' : 'blue'
}
pipeline {
  agent any
  stages {
    stage('Checkout'){
      steps {
        // Get the terraform plan
        checkout scm
      }
    }

    stage('Init') {
      steps {
        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh """
            az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
          """
        }
        script {
          currentBackend = sh (
                script: "az network lb rule show -g ${env.RESOURCE_GROUP} --lb-name ${env.LB_NAME} -n ${env.PROD_VMSS_NAME} --query 'backendAddressPool.id'",
            returnStdout: true
          ).trim()
          currentBackend = sh(returnStdout: true, script: "expr ${currentBackend} : '.*/backendAddressPools/\\(.*\\)-'").trim()
          sh "echo 'Current VM: ${currentBackend}'"
          sh "echo 'New VM: ${newBackend()}'"

        }

      }
    }

//    stage('Terraform init'){
//      steps {
//        // Initialize the plan
//        sh  """
//         cd ${workspace}/${TERRAFORM_PATH}
//         terraform init -input=false
//        """
//      }
//    }
//    stage('Terraform plan'){
//      steps {
//        // Get the VM image ID for the VMSS
//        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS),
//                         usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'REGISTORY_USERNAME', passwordVariable: 'REGISTORY_PASSWORD')]) {
//          sh """
//            az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
//            az account set --subscription $AZURE_SUBSCRIPTION_ID
//
//            export ARM_CLIENT_ID="${AZURE_CLIENT_ID}"
//            export ARM_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
//            export ARM_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
//            export ARM_TENANT_ID="${AZURE_TENANT_ID}"
//
//            cd ${workspace}/${TERRAFORM_PATH}
//            terraform plan -out=tfplan -input=false \
//              -var 'app_resource_group_name=${RESOURCE_GROUP}' \
//              -var 'location=${LOCATIONS}' \
//              -var 'prefix=${PREFIX}' \
//              -var 'pool_name=${newBackend()}' \
//              -var 'tag_version=${TAG_VERSION}' \
//              -var 'registory_url=${DOCKER_URL}' \
//              -var 'registory_username=${REGISTORY_USERNAME}' \
//              -var 'registory_password=${REGISTORY_PASSWORD}' \
//              -var 'client_id=${AZURE_CLIENT_ID}' \
//              -var 'client_secret=${AZURE_CLIENT_SECRET}' \
//              -var 'tenant_id=${AZURE_TENANT_ID}' \
//              -var 'subscription_id=${AZURE_SUBSCRIPTION_ID}'
//
//          """
//        }
//
//      }
//    }
//
//    stage('Terraform apply'){
//      steps {
//        // Apply the plan
//        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
//          sh  """
//           cd ${workspace}/${TERRAFORM_PATH}
//           terraform apply -input=false -auto-approve "tfplan"
//          """
//        }
//      }
//    }

    stage('Test ACI') {
      steps {
        script {
          ip = sh(returnStdout: true, script: "az network public-ip show --resource-group $RESOURCE_GROUP --name $IP_NAME --query ipAddress --output tsv").trim()
          print "Visit http://$ip:$TEST_PORT"
        }
      }
    }

    stage('Switch') {
      steps {
        input("Switch Prod Proceed or Abort?")
				  
        sh """
	        az network lb rule delete --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $TEST_VMSS_NAME
          az network lb rule update --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $PROD_VMSS_NAME --backend-pool-name ${newBackend()}-bepool
        """
      }
    }

    stage('Post-clean') {
      steps {
        sh '''
          az logout
        '''
      }
    }
  }
  environment {
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    DOCKER_CREDENTIALS_ID = 'DOCKER_CREDENTIALS_ID'
    DOCKER_URL = "innoregi.azurecr.io"
    
    IP_NAME="aci-pip"
    LB_NAME="aci-lb"
    PROD_VMSS_NAME="prod-rule"
    TEST_VMSS_NAME="stage-rule"
    TEST_PORT="8080"

    TERRAFORM_PATH="cd/azure/aci_bg"
    RESOURCE_GROUP="aci-tf-jenkins"
    // LOCATIONS="koreacentral"
    LOCATIONS="eastus"
    PREFIX="aci"

  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
