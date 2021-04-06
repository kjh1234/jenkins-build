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
		    
              deployIp = sh(returnStdout: true, script: "az network public-ip show -g ${RESOURCE_GROUP} --name vm-dev-pip --query ipAddress --output tsv").trim()
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
	        sh """
	          scp -i '${identity}' ${IMAGE_NAME}-${params.TAG_VERSION}.zip azureuser@${deployIp}:~/
		  scp -o ProxyCommand="ssh $jump_host nc $host 22" $local_path $host:$destination_path
		  scp -i '${identity}' -r -o ProxyCommand="ssh -i '${identity}' -W %h:%p azureuser@${deployIp}" ${IMAGE_NAME}-${params.TAG_VERSION}.zip azureuser@10.0.1.6:~/
	        """
		
	        for (privateIp in privateIps) {
                  sh """
		    # app push
		    scp -i '${identity}' -r -o ProxyCommand="ssh -i '${identity}' -W %h:%p azureuser@${deployIp}" ${IMAGE_NAME}-${params.TAG_VERSION}.zip azureuser@privateIp:~/
		    # app run
		    ssh -i '${identity}' -t -o ProxyCommand="ssh -i '${identity}' azureuser@${deployIp} nc ${privateIp} 22" azureuser@${privateIp} "java -jar ${IMAGE_NAME}-${params.TAG_VERSION}.zip"
		  """
		  // echo ${ip}"
                }
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
