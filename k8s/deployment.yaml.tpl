apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-cicd-app
  namespace: ${K8S_NAMESPACE}
  labels:
    app: secure-cicd-app
spec:
  replicas: 2
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: secure-cicd-app
  template:
    metadata:
      labels:
        app: secure-cicd-app
    spec:
      automountServiceAccountToken: false
      containers:
      - name: secure-cicd-app
        image: ${IMAGE_FULL}
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
          runAsGroup: 10001
          capabilities:
            drop:
            - ALL
      securityContext:
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
---
apiVersion: v1
kind: Service
metadata:
  name: secure-cicd-app
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: secure-cicd-app
  ports:
  - port: 80
    targetPort: 8080
