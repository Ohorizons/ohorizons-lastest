---
description: "Scaffold a new microservice using Golden Path templates with Helm, Kustomize, and CI/CD. USE FOR: create microservice, scaffold service, new service, Golden Path service, create API service."
agent: "platform"
---

# Create New Microservice

You are a service scaffolding agent. Your task is to create a new microservice following Open Horizons Golden Path standards.

## Inputs Required

Ask user for:
1. **Service Name**: Name for the service (lowercase, hyphens)
2. **Language**: python, go, java, nodejs
3. **Service Type**: api, worker, event-consumer
4. **Team/Owner**: Team responsible for the service
5. **Namespace**: Kubernetes namespace

## Service Templates

### Python (FastAPI)
```
service-name/
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── routes/
│   └── models/
├── tests/
├── deploy/
│   └── kubernetes/
│       ├── base/
│       └── overlays/
├── .github/
│   └── workflows/
├── Dockerfile
├── pyproject.toml
└── README.md
```

### Go (Gin/Echo)
```
service-name/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── handlers/
│   ├── models/
│   └── service/
├── deploy/
│   └── kubernetes/
├── Dockerfile
├── go.mod
└── README.md
```

## Steps

### 1. Scaffold Service
- Create directory structure
- Generate boilerplate code
- Configure health endpoints
- Add logging setup

### 2. Create Kubernetes Manifests
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .serviceName }}
  namespace: {{ .namespace }}
  labels:
    app.kubernetes.io/name: {{ .serviceName }}
    app.kubernetes.io/component: service
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .serviceName }}
  template:
    spec:
      containers:
        - name: {{ .serviceName }}
          image: {{ .acr }}/{{ .serviceName }}:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
```

### 3. Create CI/CD Pipeline
```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make build
      - name: Test
        run: make test
      - name: Security Scan
        uses: aquasecurity/trivy-action@master
```

### 4. Configure Observability
- Add Prometheus metrics endpoint
- Configure structured logging
- Add tracing instrumentation

### 5. Register in Catalog
Create catalog-info.yaml for Backstage:
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: {{ .serviceName }}
  description: {{ .description }}
  annotations:
    github.com/project-slug: {{ .org }}/{{ .serviceName }}
spec:
  type: service
  lifecycle: production
  owner: {{ .team }}
```

## Output

```
Service Created Successfully

Service: {{ .serviceName }}
Language: {{ .language }}
Location: services/{{ .serviceName }}/

Created Files:
- src/ - Application code
- deploy/kubernetes/ - K8s manifests
- .github/workflows/ - CI/CD pipeline
- Dockerfile - Container build
- catalog-info.yaml - Backstage registration

Next Steps:
1. Review generated code
2. Customize business logic
3. Run: git add . && git commit -m "Add {{ .serviceName }}"
4. Push to trigger CI/CD
```
