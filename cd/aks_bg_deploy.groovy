def isHook = params.IS_HOOK
def tagVersion = ''

def servicePrincipalId = 'INNO_AZURE_CREDENTIALS'

def resourceGroup = 'aks-bg-tf-jenkins-1'
def aks = 'aks-bg-cluster'

def dockerRegistry = '52.141.3.188:5000'
def dockerRegistryUrl = 'http://52.141.3.188:5000'
def imageName = "todo-app"

def currentEnvironment = 'blue'
def newEnvironment = { ->
    currentEnvironment == 'blue' ? 'green' : 'blue'
}

def verifyEnvironment = { service ->
    sh """
      endpoint_ip="\$(kubectl --kubeconfig=kubeconfig get services '${service}' --output jsonpath='{.status.loadBalancer.ingress[0].ip}')"
      count=0
      while true; do
          count=\$(expr \$count + 1)
          if curl -m 10 "http://\$endpoint_ip"; then
              break;
          fi
          if [ "\$count" -gt 30 ]; then
              echo 'Timeout while waiting for the ${service} endpoint to be ready'
              exit 1
          fi
          echo "${service} endpoint is not ready, wait 10 seconds..."
          sleep 10
      done
    """
}

pipeline {
  agent any
  stages {
    stage('INIT_PIPILINE') {
      steps {
        script {
          if (params.ALL_STEPS == true) {
            isHook = true
          }
          echo "isHook : " + isHook
          env.IMAGE_TAG = "http://${dockerRegistry}/${imageName}:${params.TAG_VERSION}"
        }

      }
    }

    stage('SCM') {
      when {
        expression {
          return isHook == true
        }

      }
      steps {
        echo ' The SCM'
        script {
          checkout([
              $class: 'GitSCM', 
              branches: [[name: "master"]],
              doGenerateSubmoduleConfigurations: false, 
              extensions: [[
                  $class: 'SubmoduleOption', 
                  disableSubmodules: false, 
                  parentCredentials: false, 
                  recursiveSubmodules: false, 
                  reference: '', 
                  trackingSubmodules: false
              ]], 
              submoduleCfg: [], 
              userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/todo-app-java-on-azure.git"]]
          ])
          
          if (params.ALL_STEPS == false && isHook == true ) {
            echo 'Tag return github'
            tagVersion = sh(returnStdout: true, script: "git describe --tags --abbrev=0 | tail -1").trim()
          } else {
            tagVersion = params.TAG_VERSION
          }
          
          
          if (params.TAG_VERSION == '') {
            error "TAG_VERSION is required"
          }
          
          echo tagVersion
          
          checkout([
              $class: 'GitSCM', 
              branches: [[name: "refs/tags/${tagVersion}"]],
              doGenerateSubmoduleConfigurations: false, 
              extensions: [[
                  $class: 'SubmoduleOption', 
                  disableSubmodules: false, 
                  parentCredentials: false, 
                  recursiveSubmodules: false, 
                  reference: '', 
                  trackingSubmodules: false
              ]], 
              submoduleCfg: [], 
              userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/todo-app-java-on-azure.git"]]
          ])
          env.IMAGE_TAG = "http://${dockerRegistry}/${imageName}:${tagVersion}"
        }

      }
    }

    stage('BUILD') {
      when {
        expression {
          return params.ALL_STEPS == true || isHook == true
        }

      }
      steps {
        sh """
            sh ./mvnw clean package -Dmaven.test.skip=true
        """
      }
    }

    stage('Create Docker Image') {
      when {
        expression {
          return params.ALL_STEPS == true || isHook == true
        }

      }
      steps {
        withDockerRegistry([credentialsId: DOCKER_CREDENTIALS_ID, url: dockerRegistryUrl]) {
            sh """
                docker build -t "${env.IMAGE_TAG}" .
                docker push "${env.IMAGE_TAG}"
            """
        }
      }
    }

    stage('Check Env') {
      when {
        expression {
          return params.ALL_STEPS == true || isHook == false
        }

      }
      steps {
        // check the current active environment to determine the inactive one that will be deployed to

        withCredentials([azureServicePrincipal(servicePrincipalId)]) {
            // fetch the current service configuration
            sh """
              az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
              az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
              az aks get-credentials --resource-group "${resourceGroup}" --name "${aks}" --admin --file kubeconfig
              az logout
              current_role="\$(kubectl --kubeconfig kubeconfig get services todoapp-service --output jsonpath='{.spec.selector.role}')"
              if [ "\$current_role" = null ]; then
                  current_role = "blue"
                  #echo "Unable to determine current environment"
                  #exit 1
              fi
              echo "\$current_role" >current-environment
            """
        }

        script {
            // parse the current active backend
            currentEnvironment = readFile('current-environment').trim()

            // set the build name
            echo "***************************  CURRENT: $currentEnvironment     NEW: ${newEnvironment()}  *****************************"
            currentBuild.displayName = newEnvironment().toUpperCase() + ' ' + imageName

            env.TARGET_ROLE = newEnvironment()
        }
        // clean the inactive environment
        sh """
        isDeployment="\$(kubectl --kubeconfig kubeconfig get deployments todoapp-deployment-\$TARGET_ROLE | wc -l)"
        if [ \$isDeployment -gt 0 ]; then
            kubectl --kubeconfig=kubeconfig delete deployment "todoapp-deployment-\$TARGET_ROLE"
        fi
        """
      }
    }

    stage('DEPLOY Staged') {
      when {
        expression {
          return params.ALL_STEPS == true || isHook == false
        }

      }
      steps {
        script {
        // Apply the deployments to AKS.
        // With enableConfigSubstitution set to true, the variables ${TARGET_ROLE}, ${IMAGE_TAG}, ${KUBERNETES_SECRET_NAME}
        // will be replaced with environment variable values
            acsDeploy azureCredentialsId: servicePrincipalId,
                      resourceGroupName: resourceGroup,
                      containerService: "${aks} | AKS",
                      configFilePaths: 'deploy/aks/deployment.yml',
                      enableConfigSubstitution: true,
                      secretName: "localhost",
                      containerRegistryCredentials: [[credentialsId: DOCKER_CREDENTIALS_ID, url: dockerRegistryUrl]]
        }
      }
    }

    stage('Verify Staged') {
      when {
        expression {
          return params.ALL_STEPS == true || isHook == false
        }

      }
      steps {
        // verify the production environment is working properly
        script {
            verifyEnvironment("todoapp-test-${newEnvironment()}")
        }
      }
    }

    stage('Prod Switch') {
      when {
        expression {
          return params.ALL_STEPS == true || isHook == false
        }

      }
      steps {
        input("Switch Prod Proceed or Abort?")
        script {
        // Update the production service endpoint to route to the new environment.
        // With enableConfigSubstitution set to true, the variables ${TARGET_ROLE}
        // will be replaced with environment variable values
            acsDeploy azureCredentialsId: servicePrincipalId,
                      resourceGroupName: resourceGroup,
                      containerService: "${aks} | AKS",
                      configFilePaths: 'deploy/aks/service.yml',
                      enableConfigSubstitution: true
        }
      }
    }

    stage('Verify Prod') {
      when {
        expression {
          return params.ALL_STEPS == true || isHook == false
        }

      }
      steps {
        script { 
            // verify the production environment is working properly
            verifyEnvironment('todoapp-service')
        }
      }
    }

    stage('Post-clean') {
      steps {
        sh '''
          rm -f kubeconfig
        '''
      }
    }

  }
  environment {
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    GIT_CREDENTIALS_ID = credentials('GIT_CREDENTIALS_ID')
    DOCKER_CREDENTIALS_ID = 'TEST_DOCKER_CREDENTIALS_ID'
    
    KUBERNETES_SECRET_NAME = 'todoapp' 
  }
  parameters {
    booleanParam(name: 'ALL_STEPS', defaultValue: false, description: '')
    booleanParam(name: 'IS_HOOK', defaultValue: false, description: '')
    string(name: 'TAG_VERSION', defaultValue: '', description: '')
  }
}
