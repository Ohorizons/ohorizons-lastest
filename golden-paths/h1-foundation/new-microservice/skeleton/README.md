# ${{values.name}}

${{values.description}}

## Overview

This microservice was created using the Open Horizons Platform - H1 Foundation template.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Language | ${{values.language}} |

## Getting Started

### Prerequisites

- Node.js 20+
- Docker
- kubectl configured for your cluster

### Local Development

```bash
# Install dependencies
npm install

# Run locally
npm run dev

# Run tests
npm test

# Build Docker image
docker build -t ${{values.name}}:local .
```

### Deployment

This service is deployed via ArgoCD. Changes to the `main` branch automatically trigger deployment to the development environment.

```bash
# Manual deployment (if needed)
kubectl apply -k deploy/overlays/dev
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| GET | /ready | Readiness probe |
| GET | /metrics | Prometheus metrics |

## Architecture

```
src/
├── index.js          # Application entry point
├── routes/           # API routes
├── services/         # Business logic
├── middleware/       # Express middleware
└── config/           # Configuration
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 3000 |
| LOG_LEVEL | Logging level | info |
| NODE_ENV | Environment | development |

## Monitoring

- Metrics: Available at `/metrics` in Prometheus format
- Logs: Structured JSON logs to stdout
- Traces: OpenTelemetry integration (if enabled)

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `npm test`
4. Create a pull request

## Links

- [Open Horizons Documentation](https://github.com/${{values.repoUrl | parseRepoUrl | pick('owner') }}/agentic-devops-platform)
- [ArgoCD Dashboard](https://argocd.example.com)
- [Grafana Dashboard](https://grafana.example.com)
