pipeline {
  agent { label 'master' } 
  stages {
    stage('SCM') {
      steps {
        script {
          if (params.TAG_VERSION == '') {
            error "TAG_VERSION is required"
          }
          
          pwd

          echo params.TAG_VERSION

          checkout([
              $class: 'GitSCM',
              branches: [[name: "refs/tags/${params.TAG_VERSION}"]],
              doGenerateSubmoduleConfigurations: false,
              extensions: [[
                  $class: 'SubmoduleOption',
                  disableSubmodules: false,
                  parentCredentials: false,
                  recursiveSubmodules: false,
                  reference: '',
                  trackingSubmodules: false
              ],[
                $class: 'RelativeTargetDirectory',
              relativeTargetDir: "${workspace}/tmp_source"
              ]],
              submoduleCfg: [],
              userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/ejb486/spring-mvc-tutorial.git"]]
          ])
        }

      }
    }

    stage('Maven Build') {
      steps {
        withCredentials(bindings: [azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh """
            cd ${workspace}/tmp_source/springmvc5-helloworld-exmaple
            mvn clean install
          """
        }

      }
    }

    stage('Image Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh """
            curl -v -u '${USERNAME}:${PASSWORD}' POST '${REPOSITORY_API}/components?repository=${IMAGE_REPOSITORY}' \
              -F maven2.groupId=${IMAGE_GROUP} \
              -F maven2.artifactId=${IMAGE_NAME} \
              -F maven2.version=${params.APP_VERSION} \
              -F maven2.asset1=@${workspace}/tmp_source/springmvc5-helloworld-exmaple/target/${IMAGE_NAME}-${params.APP_VERSION}.war \
              -F maven2.asset1.extension=war \
              -F maven2.generate-pom=true
          """
        }
      }
    }
    
    stage('Packer Image') {
      steps {
       withCredentials(bindings: [azureServicePrincipal(INNO_AZURE_CREDENTIALS), usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) { 
         sh """
         
          cd ${workspace}/ci/packer/azure/vmss
          
          pwd 
           
          packer build -force -var 'IMAGE_VERSION=${params.IMAGE_VERSION}' \
          -var 'AZURE_CLIENT_ID=${AZURE_CLIENT_ID}' \
          -var 'AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}' \
          -var 'AZURE_TENANT_ID=${AZURE_TENANT_ID}' \
          -var 'AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}' \
          -var 'NEXUS_USER=${USERNAME}' \
          -var 'NEXUS_PASS=${PASSWORD}' \
          -var 'APP_VERSION=${params.APP_VERSION}' \
          azcentos79sktbase.json
           
          """        
        }
      }
    }


    stage('Destroy') {
      steps {
          sh """
            echo 'end of ci'
          """
      }
    }

  }
  environment {
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    GIT_CREDENTIALS_ID = credentials('GIT_CREDENTIALS_ID')
    NEXUS_CREDENTIALS_ID = 'TINNO_NEXUS_CREDENTIAL'


    REPOSITORY_API = "http://20.194.45.183/service/rest/v1"
    IMAGE_REPOSITORY = "maven-releases"
    IMAGE_GROUP = "net.javaguides.springmvc"
    IMAGE_NAME = "springmvc5-helloworld-example"
    
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')

    string(name: 'IMAGE_VERSION', defaultValue: '1.0.0', description: 'azure shared image version number' )

    string(name: 'APP_VERSION', defaultValue: '1.0.0', description: 'application version number' )
  }
}

