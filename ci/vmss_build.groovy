pipeline {
  agent any
  stages {
    stage('SCM') {
      steps {
        echo ' The SCM'
        if (params.TAG_VERSION == '') {
          error "TAG_VERSION is required"
        }
        pwd 
        echo params.TAG_VERSION
          
        /* 빌드 대상 GIT을 임시 폴더에 생성함 */
        checkout([
            $class: 'GitSCM',
            branches: [[name: "refs/tags/${TAG_VERSION}"]],
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
            userRemoteConfigs: [[credentialsId: GIT_CREDENTIALS_ID, url: "https://github.com/kjh1234/todo-app-java-on-azure.git"]]
        ])

      }
    }

    stage('Maven Build') {
      steps {
        withCredentials(bindings: [azureServicePrincipal(INNO_AZURE_CREDENTIALS)]) {
          sh """
          cd ${workspace}/tmp_source
          sh ./mvnw clean package -Dmaven.test.skip=true
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
              -F maven2.version=${params.TAG_VERSION} \
              -F maven2.asset1=@${workspace}/target/${IMAGE_NAME}-${params.TAG_VERSION}.jar \
              -F maven2.asset1.extension=jar \
              -F maven2.generate-pom=true
          """
        }
      }
    }

    stage('Packer Image') {
      steps {
        script {
          sh """
          packer build -force -var 'IMAGE_VERSION=${param.IMAGE_VERSION}' \
          -var 'AZURE_CLIENT_ID=${AZURE_CLIENT_ID}' \
          -var 'AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}' \
          -var 'AZURE_TENANT_ID=${AZURE_TENANT_ID}' \
          -var 'AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}' azcentos79sktbase.json
          """
        }
      }
    }

    stage('Destroy') {
      steps {
        script {
          sh """
            echo 'end of ci' 
          """
        }

      }
    }

  }
  environment {
    AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    INNO_AZURE_CREDENTIALS = 'INNO_AZURE_CREDENTIALS'
    GIT_CREDENTIALS_ID = credentials('GIT_CREDENTIALS_ID')
    NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'


    REPOSITORY_API = "https://doss.sktelecom.com/nexus/service/rest/v1"
    IMAGE_REPOSITORY = "doss-sample-java-application"
    IMAGE_GROUP = "com.microsoft.azure.sample"
    IMAGE_NAME = "todo-app-java-on-azure"
  }
  parameters {
    string(name: 'TAG_VERSION', defaultValue: '', description: '')

    string(name: 'IMAGE_VERSION', defaultValue: '1.0.0', description: 'azure shared image version number' )
  }
}
