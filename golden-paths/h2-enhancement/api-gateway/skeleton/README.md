# ${{values.name}}

${{values.description}}

## Overview

API Gateway configuration for managing API traffic, authentication, and rate limiting.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Technology | Kong/NGINX |

## Features

- Request routing
- Authentication (JWT, OAuth2)
- Rate limiting
- Request/response transformation
- Logging and monitoring
- SSL termination

## Configuration

### Routes
Define routes in `config/routes.yaml`

### Plugins
- Authentication
- Rate limiting
- CORS
- Request validation

## Deployment

```bash
# Deploy gateway
kubectl apply -k deploy/

# Verify
kubectl get ingress -n ${{values.namespace}}
```

## Monitoring

- Metrics: Prometheus
- Logs: Structured JSON
- Traces: OpenTelemetry

## Links

- [Kong Documentation](https://docs.konghq.com/)
- [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)
