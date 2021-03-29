def publicKey
def currentBackend
def newBackend = { ->
  currentBackend == 'blue' ? 'green' : 'blue'
}

pipeline {
  agent any
  stages {
//    stage('Checkout'){
//      steps {
//        // Get the terraform plan
//        checkout scm
//      }
//    }
//
//    stage('Init') {
//      steps {
//	    withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
//	      sh """
//	        az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
//	      """
//	    }
//	    script {
//	      currentBackend = sh (
//		      script: "az network lb rule show -g ${env.RESOURCE_GROUP} --lb-name ${env.LB_NAME} -n ${env.PROD_VMSS_NAME} --query 'backendAddressPool.id'",
//            returnStdout: true
//          ).trim()
//         	  currentBackend = sh(returnStdout: true, script: "expr ${currentBackend} : '.*/backendAddressPools/\\(.*\\)-'").trim()
//		  sh "echo 'Current VM: ${currentBackend}'"
//		  sh "echo 'New VM: ${newBackend()}'"
//		  publicKey = sh(returnStdout: true, script: "readlink -f $PUBLIC_KEY").trim()
//	  	  lbProbeId = sh(returnStdout: true, script: "az network lb probe show -g${env.RESOURCE_GROUP} --lb-name ${env.LB_NAME} -n ${newBackend()}-tomcat --query id").trim()
//	    }
//
//
//      }
//    }
//
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
//
//        // Get the VM image ID for the VMSS
//        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
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
//              -var 'pool_name=${newBackend()}' \
//              -var 'image_version=${TAG_VERSION}' \
//              -var "public_key=\$(cat ${PUBLIC_KEY})" \
//	      -var "lb_probe_id=${lbProbeId}" \
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
//
//    stage('Test VM') {
//      steps {
//	    script {
//	      ip = sh(returnStdout: true, script: "az network public-ip show --resource-group $RESOURCE_GROUP --name $IP_NAME --query ipAddress --output tsv").trim()
//	      print "Visit http://$ip:$TEST_PORT"
//	    }
//      }
//    }
//
//    stage('Switch') {
//      steps {
//        input("Switch Prod Proceed or Abort?")
//
//        sh """
//	    az network lb rule delete --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $TEST_VMSS_NAME
//            az network lb rule update --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $PROD_VMSS_NAME --backend-pool-name ${newBackend()}-bepool
//	    
//	    az vm delete --ids \$(az vm list -g $RESOURCE_GROUP --query "[?contains(name, '${currentBackend}')].id" -o tsv)
//	    az disk delete --ids \$(az disk list -g $RESOURCE_GROUP --query "[?contains(name, '${currentBackend}')].id" -o tsv)
//	    az network nic delete --ids \$(az network nic list -g $RESOURCE_GROUP  --query "[?contains(name, '${currentBackend}')].id" -o tsv)
//        """
//      }
//    }
//
//    stage('Destroy') {
//      steps {
//	    script {
//          sh """
//          az logout
//          """
//	    }
//      }
//    }

    stage('Switch') {
      steps {
        input("Switch Prod Proceed or Abort?")
	 script {
		currentBackend = "blue"
		// oldVMs = sh(returnStdout: true, script: "az vm list -g $RESOURCE_GROUP --query \"[?contains(name, '$currentBackend')].id\" -o tsv").trim()
		// oldDisks = sh(returnStdout: true, script: "az disk list -g $RESOURCE_GROUP --query \"[?contains(name, '$currentBackend')].id\" -o tsv").trim()
		// oldNICs = sh(returnStdout: true, script: "az network nic list -g $RESOURCE_GROUP  --query \"[?contains(name, '$currentBackend')].id\" -o tsv").trim()
		sh """
		  # az vm delete --yes --ids \$(az vm list -g $RESOURCE_GROUP --query "[?contains(name, '$currentBackend')].id" -o tsv)
		  # az disk delete --yes --ids \$(az disk list -g $RESOURCE_GROUP --query "[?contains(name, '$currentBackend')].id" -o tsv)
		  az network nic delete --ids \$(az network nic list -g $RESOURCE_GROUP  --query "[?contains(name, '$currentBackend')].id" -o tsv)
		"""
	 }
      }
    }
  }
  environment {
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    RESOURCE_GROUP="vm-dup-bg-tf-jenkins-1"
    LB_NAME="vm-lb"
    IP_NAME="vm-pip"
    PUBLIC_KEY="~/.ssh/inno_id_rsa2.pub"
    TERRAFORM_PATH="cd/azure/vm_dup_bg"
    PROD_VMSS_NAME="prod-rule"
    TEST_VMSS_NAME="stage-rule"
    TEST_PORT="8080"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
