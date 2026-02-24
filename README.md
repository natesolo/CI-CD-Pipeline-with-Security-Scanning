# Secure CI/CD Pipeline (Jenkins)

What This Project does?
This project automatically checks your code for security problems, builds your app into a Docker image, scans that image for vulnerabilities, and only deploys if everything is safe.

This repository contains a security-focused Jenkins pipeline with:

- SonarQube static analysis + quality gate enforcement
- OWASP Dependency-Check (fails build on CVSS >= 7)
- Trivy container image scanning (fails on HIGH/CRITICAL)
- Docker image build and push to GHCR
- Automated Kubernetes deployment after all gates pass

## Files

- `Jenkinsfile`: Main pipeline definition with security gates
- `sonar-project.properties`: SonarQube scanner defaults
- `k8s/deployment.yaml.tpl`: Kubernetes deployment template (hardened securityContext)
- `Dockerfile`, `nginx.conf`, `index.html`: Example secure containerized app

## Jenkins Prerequisites

1. Install tools/plugins:
- SonarQube Scanner
- SonarQube Jenkins plugin
- Pipeline Utility Steps
- Credentials Binding

2. Ensure Docker is available on Jenkins agent.

3. Configure Jenkins credentials:
- `ghcr-service-account` (Username with token/password)
- `kubeconfig-secure-cluster` (Secret file)

4. Configure SonarQube server in Jenkins:
- Name must match `sonarqube-server`

## Security Controls Included

- No hardcoded secrets; all auth pulled from Jenkins credentials
- Quality and vulnerability gates block deployment on failure
- Container image scanned before push/deploy
- Kubernetes manifest enforces:
- non-root container user
- read-only root filesystem
- dropped Linux capabilities
- seccomp `RuntimeDefault`
- Build retention and workspace cleanup enabled

## Running

- Push repository to GitHub and connect Jenkins job to the repository.
- Configure branch strategy so deploys occur only from `main`.

