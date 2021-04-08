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
//
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
//              -var 'location=${LOCATION}' \
//              -var 'prefix=${PREFIX}' \
//              -var "pool_name=${newBackend()}" \
//              -var 'vm_instances=2' \
//              -var "public_key=\$(cat ${publicKey})" \
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

//    stage('APP Image Pull') {
//      steps {
//        script {
//          withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
//            sh """
//              curl -o ${IMAGE_NAME}-${params.TAG_VERSION}.jar -L -u '${USERNAME}:${PASSWORD}' \\
//                -X GET '${REPOSITORY_API}/search/assets/download?repository=${IMAGE_REPOSITORY}&group=${IMAGE_GROUP}&name=${IMAGE_NAME}&version=${params.TAG_VERSION}&maven.extension=jar'
//              
//              ls -al
//            """
//          }
//        }
//      }
//    }
//
//    stage('APP Deploy') {
//      steps {
//        script {
//          deployIp = sh(returnStdout: true, script: "az network public-ip show -g ${RESOURCE_GROUP} --name vm-dev-pip --query ipAddress --output tsv").trim()
//          privateIps = sh(returnStdout: true, script: "az network nic list -g ${RESOURCE_GROUP}  --query \"[?contains(name, '${newBackend()}')].ipConfigurations[].privateIpAddress\" -o tsv").split("\n")
//
//          print "deployIp : ${deployIp}"
//          print "privateIps : ${privateIps}"
//		
//          withCredentials([sshUserPrivateKey(credentialsId: VM_PRIBATE_KEY, keyFileVariable: 'identity', usernameVariable: 'userName')]) {
//            sh """
//	      rm -f ~/.ssh/known_hosts
//	      chmod 600 ${identity}
//	    """
//            sleep 3
//            input("Switch Prod Proceed or Abort?")
//            // sh "scp -i '${identity}' -o 'StrictHostKeyChecking=no' ${IMAGE_NAME}-${params.TAG_VERSION}.jar azureuser@${deployIp}:~/"
//            for (privateIp in privateIps) {
//              sh """
//                # app push
//                scp -i '${identity}' -r -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i '${identity}' -o StrictHostKeyChecking=no -W %h:%p azureuser@${deployIp}" \\
//		  ${IMAGE_NAME}-${params.TAG_VERSION}.jar azureuser@${privateIp}:~/
//                # app run
//                ssh -i '${identity}' -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i '${identity}' -o StrictHostKeyChecking=no azureuser@${deployIp} nc ${privateIp} 22" \\
//		  azureuser@${privateIp} "java -jar ${IMAGE_NAME}-${params.TAG_VERSION}.jar &>/dev/null &"
//              """
//          // echo ${ip}"
//            }
//          }
//	}
//      }
//    }
//
//    stage('Test VMSS') {
//      steps {
//        script {
//          ip = sh(returnStdout: true, script: "az network public-ip show --resource-group $RESOURCE_GROUP --name $IP_NAME --query ipAddress --output tsv").trim()
//          print "Visit http://$ip:$TEST_PORT"
//        }
//      }
//    }
//
//    stage('Switch') {
//      steps {
//        input("Switch Prod Proceed or Abort?")
//				  
//        sh """
//	  az network lb rule delete --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $TEST_VMSS_NAME
//          az network lb rule update --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $PROD_VMSS_NAME --backend-pool-name ${newBackend()}-bepool
//        """
//      }
//    }

    stage('Delete Old VM') {
      steps {
        sh """
	  # Old VM
	  # az vm delete --yes --ids \$(az vm list -g $RESOURCE_GROUP --query "[?contains(name, '${currentBackend}')].id" -o tsv)
	  # az disk delete --yes --ids \$(az disk list -g $RESOURCE_GROUP --query "[?contains(name, '${currentBackend}')].id" -o tsv)
	  # az network nic delete --ids \$(az network nic list -g $RESOURCE_GROUP  --query "[?contains(name, '${currentBackend}')].id" -o tsv)'
	  az vm delete --yes --ids \$(az vm list -g $RESOURCE_GROUP --query "[?contains(name, 'blue')].id" -o tsv)
	  az disk delete --yes --ids \$(az disk list -g $RESOURCE_GROUP --query "[?contains(name, 'blue')].id" -o tsv)
	  az network nic delete --ids \$(az network nic list -g $RESOURCE_GROUP  --query "[?contains(name, 'blue')].id" -o tsv)'
	  
	  # Jump VM
	  az vm delete --yes --ids \$(az vm list -g $RESOURCE_GROUP --query "[?contains(name, 'dev')].id" -o tsv)
	  az disk delete --yes --ids \$(az disk list -g $RESOURCE_GROUP --query "[?contains(name, 'dev')].id" -o tsv)
	  az network nic delete --ids \$(az network nic list -g $RESOURCE_GROUP  --query "[?contains(name, 'dev')].id" -o tsv)'
	  
        """
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
    // Credentials
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    // NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'
    NEXUS_CREDENTIALS_ID = 'TEST_NEXUS_CREDENTIALS_ID'
    VM_PRIBATE_KEY = 'VM_PRIBATE_KEY'

    // Terraform & Namespace
    RESOURCE_GROUP="vm-dup-bg-tf-jenkins"
    LOCATION="koreacentral"
    TERRAFORM_PATH="cd/azure/vm_dup_bg"
    PREFIX="vm"
    PUBLIC_KEY="~/.ssh/inno_id_rsa2.pub"
    LB_NAME="vm-lb"
    IP_NAME="vm-pip"
    PROD_VMSS_NAME="prod-rule"
    TEST_VMSS_NAME="stage-rule"
    TEST_PORT="8080"
    
    // REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    REPOSITORY_API = "http://52.141.3.188:8081/service/rest/v1"
    // IMAGE_REPOSITORY = "sk-maven-hosted"
    IMAGE_REPOSITORY = "maven-releases"
    IMAGE_GROUP = "com.microsoft.azure.sample"
    IMAGE_NAME = "todo-app-java-on-azure"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
