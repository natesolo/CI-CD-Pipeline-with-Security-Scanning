pipeline {
  agent any

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timeout(time: 60, unit: 'MINUTES')
    timestamps()
    ansiColor('xterm')
    skipDefaultCheckout(true)
  }

  parameters {
    choice(name: 'DEPLOY_ENV', choices: ['staging', 'production'], description: 'Target deployment environment')
    booleanParam(name: 'AUTO_DEPLOY', defaultValue: true, description: 'Deploy automatically after security gates pass')
  }

  environment {
    REGISTRY = 'ghcr.io'
    IMAGE_NAME = 'secure-cicd-app'
    IMAGE_REPO = "${REGISTRY}/nathan/${IMAGE_NAME}"
    SONARQUBE_INSTANCE = 'sonarqube-server'
    DEP_CHECK_REPORT_DIR = "${WORKSPACE}/reports/dependency-check"
    TRIVY_REPORT_DIR = "${WORKSPACE}/reports/trivy"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'git rev-parse --short HEAD > .git/short_sha'
      }
    }

    stage('Static Code Analysis (SonarQube)') {
      steps {
        withSonarQubeEnv("${SONARQUBE_INSTANCE}") {
          sh '''#!/usr/bin/env bash
            set -euo pipefail
            sonar-scanner \
              -Dsonar.projectKey=secure-cicd-pipeline \
              -Dsonar.projectName=secure-cicd-pipeline \
              -Dsonar.projectVersion=${BUILD_NUMBER} \
              -Dsonar.sources=. \
              -Dsonar.exclusions=**/.git/**,**/node_modules/**,**/venv/**,**/__pycache__/**,**/*.min.js
          '''
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Dependency Scan (OWASP Dependency-Check)') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          mkdir -p "${DEP_CHECK_REPORT_DIR}"

          docker run --rm \
            -v "${WORKSPACE}":/src \
            -v "${DEP_CHECK_REPORT_DIR}":/report \
            owasp/dependency-check:latest \
            --scan /src \
            --out /report \
            --format HTML \
            --format JSON \
            --failOnCVSS 7
        '''
      }
      post {
        always {
          archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/dependency-check/*'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          env.SHORT_SHA = sh(script: 'cat .git/short_sha', returnStdout: true).trim()
          env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.SHORT_SHA}"
        }

        sh '''#!/usr/bin/env bash
          set -euo pipefail
          docker build --pull --no-cache \
            -t "${IMAGE_REPO}:${IMAGE_TAG}" \
            .
        '''
      }
    }

    stage('Container Scan (Trivy)') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          mkdir -p "${TRIVY_REPORT_DIR}"

          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v "${TRIVY_REPORT_DIR}":/report \
            aquasec/trivy:latest image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --format sarif \
            --output /report/trivy-results.sarif \
            --exit-code 1 \
            "${IMAGE_REPO}:${IMAGE_TAG}"
        '''
      }
      post {
        always {
          archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/trivy/*'
        }
      }
    }

    stage('Push Image') {
      when {
        branch 'main'
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'ghcr-service-account', usernameVariable: 'REGISTRY_USERNAME', passwordVariable: 'REGISTRY_TOKEN')]) {
          sh '''#!/usr/bin/env bash
            set -euo pipefail
            echo "${REGISTRY_TOKEN}" | docker login "${REGISTRY}" -u "${REGISTRY_USERNAME}" --password-stdin
            docker push "${IMAGE_REPO}:${IMAGE_TAG}"
            docker tag "${IMAGE_REPO}:${IMAGE_TAG}" "${IMAGE_REPO}:latest"
            docker push "${IMAGE_REPO}:latest"
            docker logout "${REGISTRY}"
          '''
        }
      }
    }

    stage('Automated Deploy') {
      when {
        allOf {
          branch 'main'
          expression { return params.AUTO_DEPLOY }
        }
      }
      steps {
        withCredentials([file(credentialsId: 'kubeconfig-secure-cluster', variable: 'KUBECONFIG_FILE')]) {
          sh '''#!/usr/bin/env bash
            set -euo pipefail
            export KUBECONFIG="${KUBECONFIG_FILE}"
            export IMAGE_FULL="${IMAGE_REPO}:${IMAGE_TAG}"
            envsubst < k8s/deployment.yaml.tpl > k8s/deployment.yaml
            kubectl apply -f k8s/deployment.yaml
            kubectl -n secure-cicd rollout status deployment/secure-cicd-app --timeout=180s
          '''
        }
      }
    }
  }

  post {
    always {
      sh '''#!/usr/bin/env bash
        docker image rm -f "${IMAGE_REPO}:${IMAGE_TAG}" "${IMAGE_REPO}:latest" 2>/dev/null || true
      '''
      cleanWs()
    }
  }
}
