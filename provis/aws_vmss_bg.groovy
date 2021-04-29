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
         ls
         terraform init -input=false
        """
      }
    }
    stage('Terraform plan'){
      steps {
        // Get the VM image ID for the VMSS
        withCredentials([usernamePassword(credentialsId: AWS_ACCOUNT, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD'),
          usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
          sh """

            cd ${workspace}/${TERRAFORM_PATH}
            terraform plan -out=tfplan -input=false \
              -var 'access_key=${USERNAME}' \
              -var 'secret_key=${PASSWORD}' \
              -var 'app_resource_group_name=${RESOURCE_GROUP}' \
              -var 'location=${LOCATION}'

          """
        }
      }
    }

    stage('Terraform apply'){
      steps {
        // Apply the plan
        sh  """
         cd ${workspace}/${TERRAFORM_PATH}
         terraform apply -input=false -auto-approve "tfplan"
        """
      }
    }
  }
  environment {
    // NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'
    NEXUS_CREDENTIALS_ID = 'TINNO_NEXUS_CREDENTIAL'
    // REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    REPOSITORY_API = "http://52.141.3.188:8081/service/rest/v1"
    AWS_ACCOUNT = "AWS_P120230_ACCOUNT"
    PUBLIC_KEY="~/.ssh/inno_id_rsa2.pub"
    RESOURCE_GROUP="vmss-bg-gr"
    LOCATION="ap-northeast-2"
    TERRAFORM_PATH="provis/aws/vmss_bg"
  }
}
