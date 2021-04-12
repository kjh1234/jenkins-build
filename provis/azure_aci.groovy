pipeline {
  agent any
  stages {
    stage('Checkout'){
      steps {
        // Get the terraform plan
        checkout scm
      }
    }

    stage('Terraform init'){
      steps {
        // Initialize the plan
        sh  """
         cd ${workspace}/${TERRAFORM_PATH}
         terraform init -input=false
        """
      }
    }
    stage('Terraform plan'){
      steps {
        // Get the VM image ID for the VMSS
        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS), 
                         usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'REGISTORY_USERNAME', passwordVariable: 'REGISTORY_PASSWORD')]) {
          sh """
            az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
            az account set --subscription $AZURE_SUBSCRIPTION_ID

            export ARM_CLIENT_ID="${AZURE_CLIENT_ID}"
            export ARM_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
            export ARM_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
            export ARM_TENANT_ID="${AZURE_TENANT_ID}"

            cd ${workspace}/${TERRAFORM_PATH}
            terraform plan -out=tfplan -input=false \
              -var 'app_resource_group_name=${RESOURCE_GROUP}' \
              -var 'location=${LOCATIONS}' \
              -var 'prefix=${PREFIX}' \
              -var 'registory_url=${DOCKER_URL}' \
              -var 'registory_username=${REGISTORY_USERNAME}' \
              -var 'registory_password=${REGISTORY_PASSWORD}' \
              -var 'client_id=${AZURE_CLIENT_ID}' \
              -var 'client_secret=${AZURE_CLIENT_SECRET}' \
              -var 'tenant_id=${AZURE_TENANT_ID}' \
              -var 'subscription_id=${AZURE_SUBSCRIPTION_ID}'

          """
        }

      }
    }

    stage('Terraform apply'){
      steps {
        // Apply the plan
        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh  """
           cd ${workspace}/${TERRAFORM_PATH}
           terraform apply -input=false -auto-approve "tfplan"
          """
        }
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
    
    TERRAFORM_PATH="provis/azure/aci_bg"
    RESOURCE_GROUP="aci-tf-jenkins-1"
    // LOCATIONS="koreacentral"
    LOCATIONS="eastus"
    PREFIX="aci"

  }
}
