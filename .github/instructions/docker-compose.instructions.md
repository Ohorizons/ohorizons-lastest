---
applyTo: "**/docker-compose.yml,**/docker-compose.yaml"
description: "Docker Compose standards for local development services like MCP servers."
---

# Docker Compose Standards

## Service Configuration

- Use `restart: unless-stopped` for services that should auto-start on boot
- Use descriptive `container_name` values: `mcp-ecosystem`, not `server1`
- Pin image versions: `node:20-alpine`, never `node:latest`
- Set resource limits with `deploy.resources.limits` for memory and CPU

## Secrets & Environment

- Use `env_file` to load `.env` — never hardcode secrets in the compose file
- Provide an `.env.example` with all variables documented (no real values)
- Use `${VARIABLE:-default}` syntax for optional env vars with sensible defaults

### DO

```yaml
services:
  mcp-server:
    container_name: mcp-ecosystem
    build: .
    restart: unless-stopped
    env_file: .env
    ports:
      - "127.0.0.1:3100:3100"   # Bind to localhost only
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3100/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    volumes:
      - mcp-cache:/app/cache

volumes:
  mcp-cache:
```

### DON'T

```yaml
services:
  server:
    image: node:latest          # Unpinned version
    ports:
      - "3100:3100"             # Exposes on 0.0.0.0, not just localhost
    environment:
      - API_KEY=sk-abc123       # Hardcoded secret
    # No healthcheck, no restart policy, no named volumes
```

## Networking & Ports

- Expose ports only on localhost: `"127.0.0.1:3100:3100"`, not `"3100:3100"`
- Use custom networks for multi-service communication instead of links
- Use `expose` (internal only) vs `ports` (host-accessible) intentionally

## Data & Volumes

- Define named volumes for persistent data (cache, databases)
- Use bind mounts only for development hot-reload scenarios
- Set volume labels for organization: `labels: ["com.project=mcp"]`

## Health & Monitoring

- Include `healthcheck` for every service — no exceptions
- Use `start_period` to give services time to initialize
- Set `interval`, `timeout`, `retries` explicitly (don't rely on defaults)
