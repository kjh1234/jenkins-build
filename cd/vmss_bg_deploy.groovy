def publicKey
def currentBackend
def newBackend = { ->
  currentBackend == 'blue' ? 'green' : 'blue'
}

pipeline {
  agent any
  stages {

    stage('Init') {
      steps {
	    withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
	      sh """
	        az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
	      """
	    }
	    script {
	      currentBackend = sh (
		      script: 'az network lb rule show -g ${env.RESOURCE_GROUP} --lb-name ${env.LB_NAME} -n ${env.PROD_VMSS_NAME} --query "backendAddressPool.id"',
            returnStdout: true
          ).trim()
          currentBackend = sh(returnStdout: true, script: "expr ${currentBackend} : '.*/backendAddressPools/\\(.*\\)-'").trim()
		  sh "echo 'Current VMSS: ${currentBackend}'"
		  sh "echo 'New VMSS: ${newBackend()}'"
		  publicKey = sh(returnStdout: true, script: 'readlink -f $PUBLIC_KEY_PATH').trim()
	    }
		
		
      }
    }

    stage('Create Test VMSS') {
      steps {
	    script {
	      deployImage = "${IMAGE_RESOURCE_GROUP}tomcat-${TAG_VERSION}"
          sh """
          az vmss create --resource-group "$RESOURCE_GROUP" --name "vmss-${newBackend()}" \
              --image $deployImage \
              --admin-username $ADMIN_USERNAME \
	            --ssh-key-value "${publicKey}" \
              --instance-count 1 \
              --nsg "$NSG_NAME" \
              --vnet-name "$VNET_NAME" \
              --subnet "$SUBNET_NAME" \
              --lb "$LB_NAME" \
              --backend-pool-name "${newBackend()}-bepool" \
              --lb-nat-pool-name "${newBackend()}-natpool"
              
          az network lb rule create \
              --resource-group "$RESOURCE_GROUP" \
              --lb-name "$LB_NAME" \
              --name $TEST_VMSS_NAME \
              --frontend-port "$TEST_PORT" \
              --backend-port 8080 \
              --protocol Tcp \
              --backend-pool-name "${newBackend()}-bepool" \
              --probe-name tomcat

          """
	    }
      }
    }

    stage('Test VMSS') {
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
		az vmss scale --resource-group $RESOURCE_GROUP --name "vmss-${newBackend()}" --new-capacity 3
	    az network lb rule delete --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $TEST_VMSS_NAME
        az network lb rule update --resource-group $RESOURCE_GROUP --lb-name $LB_NAME --name $PROD_VMSS_NAME --backend-pool-name ${newBackend()}-bepool
		az vmss scale --resource-group $RESOURCE_GROUP --name "vmss-${currentBackend}" --new-capacity 1
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
    RESOURCE_GROUP="vmss-bg-tf-jenkins"
    LOCATION="koreacentral"
    LB_NAME="vmssbg-lb"
    IP_NAME="vmssbg-ip"
    DNS_NAME="vmssbgtest"
    VNET_NAME="vmssbg-vnet"
    SUBNET_NAME="vmssbg-subnet"
    NSG_NAME="vmssbg-nsg"
	PROBE_NAME="tomcat"
    ADMIN_USERNAME="azureuser"
    PUBLIC_KEY_PATH="/appdata/.ssh/inno_id_rsa.pub"
    IMAGE_RESOURCE_GROUP="/subscriptions/e9b9730c-d46a-480e-a12e-1dbb7505bb81/resourceGroups/vmss-bg-image-gr/providers/Microsoft.Compute/images/"
    INNO_AZURE_CREDENTIALS="INNO_AZURE_CREDENTIALS"
    PROD_VMSS_NAME="tomcat"
    TEST_VMSS_NAME="tomcat-test"
    TEST_PORT = "8080"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
