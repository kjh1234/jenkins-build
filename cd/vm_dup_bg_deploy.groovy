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
		    
              deployIp = sh(returnStdout: true, script: "az network public-ip show -g ${RESOURCE_GROUP} --name vm-dev-pip --query ipAddress --output tsv")
	      privateIps = sh(returnStdout: true, script: "az network nic list -g ${RESOURCE_GROUP}  --query \"[?contains(name, '${currentBackend}')].ipConfigurations[].privateIpAddress\" -o tsv").split("\n")

	      print "deployIp : ${deployIp}"
	      print "privateIps : ${privateIps}"
	      // for (ip in privateIps) {
              //   sh "echo ${ip}"
              // }
		    
              
              withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                sh """
	          curl -o ${IMAGE_NAME}-${params.TAG_VERSION}.zip -L -u '${USERNAME}:${PASSWORD}' \\
	            -X GET '${REPOSITORY_API}/search/assets/download?repository=${IMAGE_REPOSITORY}&group=${IMAGE_GROUP}&name=${IMAGE_NAME}&version=${params.TAG_VERSION}&maven.extension=zip'
	          
	          ls -al
	        """
              }
	      
	      withCredentials([sshUserPrivateKey(credentialsId: VM_PRIBATE_KEY, keyFileVariable: 'identity', usernameVariable: 'userName')]) {
	        // def remote = [:] 
		// remote.name = "tomcat-vm-dev" 
		// remote.host = "${deployIp}" 
		// remote.allowAnyHosts = true 
		// remote.user = userName 
		// remote.identityFile = identity
		// sshPut remote: remote, from: "${IMAGE_NAME}-${params.TAG_VERSION}.zip", into: "~/"
                
		temp_key = sh(returnStdout: true, script: "echo '${identity}' | { tf=\$(mktemp); cat >'\$tf'; }")
	        sh """
		  echo "${temp_key}"
	          scp -i ${temp_key} ${IMAGE_NAME}-${params.TAG_VERSION}.zip azureuser@${deployIp}:~/
	        """
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
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    // NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'
    NEXUS_CREDENTIALS_ID = 'TEST_NEXUS_CREDENTIALS_ID'
    VM_PRIBATE_KEY = 'VM_PRIBATE_KEY'
	  
    RESOURCE_GROUP="vm-dup-bg-tf-jenkins"
    LB_NAME="vm-lb"
    IP_NAME="vm-pip"
    PUBLIC_KEY="~/.ssh/inno_id_rsa2.pub"
    TERRAFORM_PATH="cd/azure/vm_dup_bg"
    PROD_VMSS_NAME="prod-rule"
    TEST_VMSS_NAME="stage-rule"
    TEST_PORT="8080"
    
    // REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    REPOSITORY_API = "http://52.141.3.188:8081/service/rest/v1"
    // IMAGE_REPOSITORY = "sk-maven-hosted"
    IMAGE_REPOSITORY = "maven-releases"
    IMAGE_GROUP = "com.functions"
    IMAGE_NAME = "azure-functions-samples"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
