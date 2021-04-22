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
        withCredentials([usernamePassword(credentialsId: AWS_ACCOUNT, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh """

            cd ${workspace}/${TERRAFORM_PATH}
            terraform plan -out=tfplan -input=false \
              -var 'app_resource_group_name=${RESOURCE_GROUP}' \
              -var "public_key=\$(cat ${PUBLIC_KEY})" \
              -var 'access_key=${USERNAME}' \
              -var 'secret_key=${PASSWORD}' \
              -var 'location=${LOCATION}' \

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
    AWS_ACCOUNT = "AWS_P120230_ACCOUNT"
    PUBLIC_KEY="~/.ssh/inno_id_rsa2.pub"
    RESOURCE_GROUP="test_vm"
    LOCATION="ap-northeast-2"
    TERRAFORM_PATH="provis/aws/vm_sample"
  }
}
