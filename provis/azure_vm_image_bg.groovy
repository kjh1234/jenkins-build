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
         cd ${workspace}/provis/azure/vm_image_bg
         terraform init -input=false
        """
      }
    }
    stage('Terraform plan'){
      steps {

        // Get the VM image ID for the VMSS
        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh """
            az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
            az account set --subscription $AZURE_SUBSCRIPTION_ID
           
            export ARM_CLIENT_ID="${AZURE_CLIENT_ID}"
            export ARM_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
            export ARM_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
            export ARM_TENANT_ID="${AZURE_TENANT_ID}"
            
            cd ${workspace}/provis/azure/vm_image_bg
            terraform plan -out=tfplan -input=false \
              -var 'app_resource_group_name=${RESOURCE_GROUP}' \
              -var "public_key=\$(cat ${PUBLIC_KEY})" \
              -var 'client_id=${AZURE_CLIENT_ID}' \
              -var 'client_secret=${AZURE_CLIENT_SECRET}' \
              -var 'tenant_id=${AZURE_TENANT_ID}' \
              -var 'subscription_id=${AZURE_SUBSCRIPTION_ID}'
            
            # sh (script:"cd ${workspace}/provis/azure/vm_image_bg && terraform plan -out=tfplan -input=false -var 'app_resource_group_name=vmss-tf-jenkins'")
          """
        }
        
      }
    }

    stage('Terraform apply'){
      steps {
        // Apply the plan
        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh  """
           cd ${workspace}/provis/azure/vm_image_bg
           terraform apply -input=false -auto-approve "tfplan"
          """
        }
      }
    }
  }
  environment {
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    PUBLIC_KEY="~/.ssh/inno_id_rsa2.pub"
    RESOURCE_GROUP="vm-image-bg-tf-jenkins-2"
  }
}
