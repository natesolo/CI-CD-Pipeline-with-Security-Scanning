apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-cicd-app
  namespace: secure-cicd
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
          capabilities:
            drop:
            - ALL
      securityContext:
        seccompProfile:
          type: RuntimeDefault
---
apiVersion: v1
kind: Service
metadata:
  name: secure-cicd-app
  namespace: secure-cicd
spec:
  selector:
    app: secure-cicd-app
  ports:
  - port: 80
    targetPort: 8080
