# Agent API SK — Multi-Agent Chat (Semantic Kernel)

Drop-in replacement for the primary Agent API, powered by Microsoft Semantic Kernel. Same API contract, same SSE format, same frontend — different runtime engine. Uses SK plugins with `@kernel_function` decorators instead of raw tool definitions.

## Architecture

```
Backstage UI → /api/proxy/agent-api/* → FastAPI (port 8009) → Azure OpenAI via SK AzureChatCompletion
```

- **Engine**: Semantic Kernel (`Kernel` + `AzureChatCompletion`)
- **Model**: Azure OpenAI GPT-5.1 via Azure AI Foundry
- **Plugin system**: Each agent gets a scoped `Kernel` with only the plugins it needs
- **Key difference**: `@kernel_function` decorator; Kernel-managed plugin registry; per-agent kernel isolation

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check with model and engine info |
| `GET` | `/api/agents/info` | List all agents with plugins and configuration |
| `POST` | `/api/agents/chat` | Multi-agent chat with SSE streaming |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_OPENAI_API_KEY` | Yes | — | Azure OpenAI API key |
| `AZURE_OPENAI_ENDPOINT` | Yes | — | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_DEPLOYMENT` | No | `gpt-5-1` | Deployment name |
| `GITHUB_TOKEN` | Yes | — | GitHub PAT for plugin API calls |
| `GITHUB_OWNER` | No | `Ohorizons` | GitHub organization |
| `MCP_ENDPOINT` | No | `http://localhost:7007/api/mcp-actions/v1` | Backstage MCP endpoint |
| `MCP_ECOSYSTEM_URL` | No | `http://localhost:3100` | MCP Ecosystem server URL |
| `CORS_ORIGINS` | No | `http://localhost:3000,http://localhost:7007` | Comma-separated allowed origins |
| `HOST` | No | `0.0.0.0` | Server bind address |
| `PORT` | No | `8009` | Server port |
| `LOG_LEVEL` | No | `INFO` | Logging level |

## Local Development

```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your Azure OpenAI and GitHub credentials

# Run directly
pip install -r requirements.txt
python main.py

# Or via docker-compose (from backstage/server/)
docker compose up agent-api-sk -d
docker compose logs -f agent-api-sk
```

The container binds to `127.0.0.1:8009` and joins the `ohorizons-platform` Docker network.

## Deployment

- **Namespace**: `backstage`
- **Service**: `agent-api-sk` (port 8009)
- **Image**: `acropenhorizonsdev.azurecr.io/ohorizons-agent-api:v7.1.0-demo` (SK variant)
- **Backstage proxy**: `/api/proxy/agent-api` → `http://agent-api-sk:8009`

## Configuration

- **Agents**: Defined in `agents/` — same 7-agent topology as the primary API
- **Plugins**: `plugins/` — modular SK plugins scoped per agent:
  - `GitHubPlugin` — workflow runs, check runs, PRs, issues
  - `BackstagePlugin` — catalog search, template listing
  - `EcosystemPlugin` — MCP ecosystem integration
  - `SecurityPlugin` — Dependabot, code scanning, secret scanning
  - `ObservabilityPlugin` — Prometheus queries, alerts, Grafana dashboards
  - `InfraPlugin` — Kubernetes namespaces, pods, deployments, events
- **Agent routing**: `agents/router.py` — `@mention` → keyword match → orchestrator fallback
- **Kernel isolation**: Each agent gets its own `Kernel` instance with only its required plugins
