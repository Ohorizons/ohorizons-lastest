# ${{values.name}}

${{values.description}}

## Overview

Production-ready containerized microservice with observability and GitOps deployment.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Language | ${{values.language}} |

## Features

- Containerized with Docker
- Kubernetes deployment manifests
- Health checks (liveness/readiness)
- Prometheus metrics endpoint
- OpenTelemetry tracing
- Structured logging
- CI/CD pipeline included

## Project Structure

```
src/
├── main.py           # Application entrypoint
├── api/              # API routes
├── services/         # Business logic
├── models/           # Data models
└── utils/            # Utilities
deploy/
├── kustomization.yaml
├── deployment.yaml
├── service.yaml
└── configmap.yaml
```

## Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run the service
python -m src.main

# Run with Docker
docker build -t ${{values.name}} .
docker run -p 8080:8080 ${{values.name}}
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/ready` | GET | Readiness check |
| `/metrics` | GET | Prometheus metrics |
| `/api/v1/...` | * | API routes |

## Configuration

Environment variables:

- `PORT`: Service port (default: 8080)
- `LOG_LEVEL`: Logging level (default: INFO)
- `OTEL_EXPORTER_ENDPOINT`: OpenTelemetry collector
- `DATABASE_URL`: Database connection string

## Deployment

```bash
# Deploy to development
kubectl apply -k deploy/overlays/dev

# Deploy to production
kubectl apply -k deploy/overlays/prod
```

## Monitoring

- Grafana dashboards for service metrics
- Distributed tracing in Jaeger
- Log aggregation in Azure Monitor

## Links

- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/workloads/pods/)
- [12-Factor App](https://12factor.net/)
