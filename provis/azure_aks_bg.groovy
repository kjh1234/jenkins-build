pipeline {
  agent any
  stages {
    stage('Checkout'){
      steps {
        // Get the terraform plan
        checkout scm
      }
    }
    /*
    stage('Terraform init'){
      steps {
        // Initialize the plan
        sh  """
         cd ${workspace}/provis/azure/aks_bg
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
            
            cd ${workspace}/provis/azure/aks_bg
            terraform plan -out=tfplan -input=false \
              -var 'app_resource_group_name=${RESOURCE_GROUP}' \
              -var 'location=${LOCATIONS}' \
              -var 'cluster_name=${AKS_NAME}' \
              -var 'public_key=${PUBLIC_KEY}' \
              -var 'client_id=${AZURE_CLIENT_ID}' \
              -var 'client_secret=${AZURE_CLIENT_SECRET}' \
              -var 'tenant_id=${AZURE_TENANT_ID}' \
              -var 'subscription_id=${AZURE_SUBSCRIPTION_ID}'
            
            # sh (script:"cd ${workspace}/provis/azure/vmss_bg && terraform plan -out=tfplan -input=false -var 'app_resource_group_name=vmss-tf-jenkins'")
          """
        }

        // image_id = sh (
        //     script: "az image show -g $vm_images_rg -n $image_name --query '{VMName:id}' --out tsv",
        //    returnStdout: true).trim()

        // sh (script:"cd ${workspace}/provis/azure/vmss_bg && terraform plan -out=tfplan -input=false -var 'terraform_resource_group='$vmss_rg -var 'terraform_vmss_name='$vmss_name -var 'terraform_azure_region='$location -var 'terraform_image_id='$image_id")
        
      }
    }

    stage('Terraform apply'){
      steps {
        // Apply the plan
        withCredentials([azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh  """
           cd ${workspace}/provis/azure/aks_bg
           terraform apply -input=false -auto-approve "tfplan"
          """
        }
      }
    }
    */

    stage('K8s Create Service'){
      steps {
        // Apply the plan
        sh """
        #!/bin/bash
        
        companion_rg="MC_${RESOURCE_GROUP}_${AKS_NAME}_${LOCATIONS}"
        echo "companion resource group '$companion_rg'" 
        """
        /*
        sh  """
          companion_rg="MC_${RESOURCE_GROUP}_${AKS_NAME}_${LOCATIONS}"
          kubeconfig="$(mktemp)"
          
          echo "Fetch AKS credentials to $kubeconfig"
          az aks get-credentials -g "${RESOURCE_GROUP}" -n "${AKS_NAME}" --admin --file "$kubeconfig"
          
          echo "Apply Service"
          kubectl apply -f "${workspace}/provis/azure/aks_bg/service-green.yml" --kubeconfig "$kubeconfig"
          kubectl apply -f "${workspace}/provis/azure/aks_bg/test-endpoint-blue.yml" --kubeconfig "$kubeconfig"
          kubectl apply -f "${workspace}/provis/azure/aks_bg/test-endpoint-green.yml" --kubeconfig "$kubeconfig"
          
          
          function assign_dns {
            service="$1"
            dns_name="$2"
            IP=
            while true; do
                echo "Waiting external IP for $service..."
                IP="$(kubectl get service "$service" --kubeconfig "$kubeconfig" | tail -n +2 | awk '{print $4}' | grep -v '<')"
                if [[ "$?" == 0 && -n "$IP" ]]; then
                    echo "Service $service public IP: $IP"
                    break
                fi
                sleep 10
            done

            public_ip="$(az network public-ip list -g "$companion_rg" --query "[?ipAddress==\`$IP\`] | [0].id" -o tsv)"
            if [[ -z "$public_ip" ]]; then
                echo "Cannot find public IP resource ID for '$service' in companion resource group '$companion_rg'" >&2
                exit 1
            fi

            echo "Assign DNS name '$dns_name' for '$service'"
            az network public-ip update --dns-name "$dns_name" --ids "$public_ip"
            [[ $? != 0 ]] && exit 1
        }

        assign_dns todoapp-service "aks-todoapp-dns"
        assign_dns todoapp-test-blue "aks-todoapp-blue-dns"
        assign_dns todoapp-test-green "aks-todoapp-green-dns"
        """
        */
      }
    }

    stage('Post-clean') {
      steps {
        sh '''
          az logout
          rm -f kubeconfig
        '''
      }
    }
  }
  environment {
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    PUBLIC_KEY="~/.ssh/inno_id_rsa.pub"
    RESOURCE_GROUP="aks-bg-tf-jenkins"
    AKS_NAME="aks-bg-cluster"
    LOCATIONS="koreacentral"
    
  }
}
