
pipeline {
  agent any
  stages {
    stage('test') {
      steps {
        print "test"
      }
    }
  }
}