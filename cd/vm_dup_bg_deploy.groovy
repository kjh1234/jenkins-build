def publicKey
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
	      publicKey = sh(returnStdout: true, script: "readlink -f $PUBLIC_KEY").trim()
	      lbProbeId = sh(returnStdout: true, script: "az network lb probe show -g ${env.RESOURCE_GROUP} --lb-name ${env.LB_NAME} -n ${newBackend()}-tomcat --query id").trim()
		    
              privateIps = sh(returnStdout: true, script: "az network public-ip show -g ${RESOURCE_GROUP} --name vm-dev-pip --query ipAddress --output tsv")
	      privateIps = sh(returnStdout: true, script: "az network nic list -g ${RESOURCE_GROUP}  --query \"[?contains(name, '${currentBackend}')].ipConfigurations[].privateIpAddress\" -o tsv").split("\n")

	      // for (ip in privateIps) {
              //   sh "echo ${ip}"
              // }
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
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    RESOURCE_GROUP="vm-dup-bg-tf-jenkins"
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
