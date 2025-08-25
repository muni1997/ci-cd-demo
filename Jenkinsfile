pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "YOUR_DOCKERHUB_USERNAME/ci-demo"
  }
  tools {
    jdk 'jdk17'
    maven 'maven3'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timestamps()
    ansiColor('xterm')
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build & Unit Test') {
      steps {
        sh 'mvn -B -DskipTests=false clean verify'
        junit 'target/surefire-reports/*.xml'
      }
    }
    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv('MySonarQube') {
          sh 'mvn -B sonar:sonar -Dsonar.projectKey=ci-demo -Dsonar.projectName=ci-demo -Dsonar.token=$SONAR_AUTH_TOKEN'
        }
      }
    }
    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
    stage('Docker Build') {
      steps {
        script {
          sh 'echo Building Docker image ${DOCKER_IMAGE}:${BUILD_NUMBER}'
          def app = docker.build("${DOCKER_IMAGE}:${env.BUILD_NUMBER}")
          sh "docker tag ${DOCKER_IMAGE}:${env.BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
        }
      }
    }
    stage('Docker Push') {
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
            sh "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            sh "docker push ${DOCKER_IMAGE}:latest"
          }
        }
      }
    }
  }
  post {
    always {
      archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
    }
  }
}
