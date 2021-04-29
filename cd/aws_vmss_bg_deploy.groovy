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
//        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
//          sh """
//            az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
//          """
//        }

        script {
          albArn = sh(script: "aws elbv2 describe-load-balancers --names '${LB_NAME}' --query \"LoadBalancers[].LoadBalancerArn\" --output text", returnStdout: true).trim()
          port = sh(script: "aws elbv2 describe-listeners --load-balancer-arn ${albArn} --query \"Listeners[].{port:Port, targetArn:DefaultActions[0].TargetGroupArn}[?contains(targetArn, 'blue')].port\" --output text", returnStdout: true).trim()
          currentBackend = port == '80' ? 'blue' : 'green'

          sh "echo 'Current VM: ${currentBackend}'"
          sh "echo 'New VM: ${newBackend()}'"

          prodLisner = sh(script: "aws elbv2 describe-listeners --load-balancer-arn ${albArn} --query \"Listeners[].{listenerArn:ListenerArn, targetArn:DefaultActions[0].TargetGroupArn}[?contains(targetArn, '${currentBackend}')].listenerArn\" --output text ", returnStdout: true).trim()

          sh "echo 'prod Lisner: ${prodLisner}'"
        }

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
              -var 'access_key=${USERNAME}' \
              -var 'secret_key=${PASSWORD}' \
              -var 'app_resource_group_name=${RESOURCE_GROUP}' \
              -var 'location=${LOCATION}' \
              -var 'app_version=${TAG_VERSION}' \
              -var 'pool_name=${newBackend()}'
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

    stage('Test VMSS') {
      steps {
        script {
          // ip = sh(returnStdout: true, script: "az network public-ip show --resource-group $RESOURCE_GROUP --name $IP_NAME --query ipAddress --output tsv").trim()
	  ip = sh(script: "aws elbv2 describe-load-balancers  --load-balancer-arn ${albArn} --query \"LoadBalancers[].DNSName\" --output text", returnStdout: true)
          print "Visit http://$ip:$TEST_PORT"
        }
      }
    }

    stage('Switch') {
      steps {
        input("Switch Prod Proceed or Abort?")

        script {
          stageLisner = sh(script: "aws elbv2 describe-listeners --load-balancer-arn ${albArn} --query \"Listeners[].{listenerArn:ListenerArn, targetArn:DefaultActions[0].TargetGroupArn}[?contains(targetArn, '${newBackend()}')].listenerArn\" --output text", returnStdout: true).trim()
          newTargetGroup = sh(script: "aws elbv2 describe-listeners --load-balancer-arn  ${albArn} --query \"Listeners[].{listenerArn:ListenerArn, targetArn:DefaultActions[0].TargetGroupArn}[?contains(targetArn, '${newBackend()}')].targetArn\" --output text", returnStdout: true).trim()
		
          sh """
            aws elbv2 delete-listener --listener-arn ${stageLisner}
            aws elbv2 modify-listener --listener-arn ${prodLisner} --default-actions Type=forward,TargetGroupArn=${newTargetGroup}
          """
        }
        
      }
    }

    stage('Delete Old VM') {
      steps {
        script {
	      oldTargetGroupArn = sh(script: "aws elbv2 describe-target-groups --names vmss-bg-lb-${currentBackend}-target --query \"TargetGroups[].TargetGroupArn\" --output text", returnStdout: true).trim()
          oldInstanceIds = sh(script: "aws autoscaling describe-auto-scaling-groups --query \"AutoScalingGroups[].{scaleName:AutoScalingGroupName, name:Tags[?Key=='Name'].Value}[?name[0] == 'vmss-bg-${currentBackend}'].scaieName\" --output text", returnStdout: true).trim()
	
          sh """
	    # Old VM
	    aws elbv2 delete-target-group  --target-group-arn ${oldTargetGroupArn}
            aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ${oldInstanceIds} --force-delete
      
#	    # Jump VM
#	    az vm delete --yes --ids \$(az vm list -g $RESOURCE_GROUP --query "[?contains(name, 'jumpbox')].id" -o tsv)
#	    az disk delete --yes --ids \$(az disk list -g $RESOURCE_GROUP --query "[?contains(name, 'jumpbox')].id" -o tsv)
#	    az network nic delete --ids \$(az network nic list -g $RESOURCE_GROUP  --query "[?contains(name, 'jumpbox')].id" -o tsv)
  
          """
	  }
      }
    }
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
  }

  environment {
    // Credentials
    AWS_ACCOUNT = "AWS_P120230_ACCOUNT"
    AMI_ID = credentials('AMI_ID')
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
//    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'
    // NEXUS_CREDENTIALS_ID = 'TEST_NEXUS_CREDENTIALS_ID'
    VM_PRIBATE_KEY = 'VM_PRIBATE_KEY'

    // Terraform & Namespace
    RESOURCE_GROUP="vmss-bg-gr"
    LOCATION="ap-northeast-2"
    TERRAFORM_PATH="cd/aws/vmss_bg"
    PREFIX="vm"
    PUBLIC_KEY="~/.ssh/inno_id_rsa2.pub"
    LB_NAME="vmss-bg-alb"
    IP_NAME="vm-pip"
    PROD_VMSS_NAME="prod-rule"
    TEST_VMSS_NAME="stage-rule"
    TEST_PORT="8080"

    REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    // REPOSITORY_API = "http://52.141.3.188:8081/service/rest/v1"
    // IMAGE_REPOSITORY = "sk-maven-hosted"
    IMAGE_REPOSITORY = "maven-releases"
    IMAGE_GROUP = "com.microsoft.azure.sample"
    IMAGE_NAME = "todo-app-java-on-azure"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
