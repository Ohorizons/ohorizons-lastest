# Agent API MAF — Multi-Agent Chat (Microsoft Agent Framework)

Drop-in replacement for the primary Agent API, powered by the Microsoft Agent Framework (MAF). Same API contract, same SSE format, same frontend — different runtime engine. Features native MCP tool integration, including HTTP and Stdio-based MCP servers.

## Architecture

```
Backstage UI → /api/proxy/agent-api/* → FastAPI (port 8010) → Azure OpenAI via MAF AzureOpenAIClient
```

- **Engine**: Microsoft Agent Framework (`agent_framework.Agent` + `AzureOpenAIClient`)
- **Model**: Azure OpenAI GPT-5.1 via Azure AI Foundry
- **MCP Integration**: Native `MCPStreamableHTTPTool` and `MCPStdioTool` for ecosystem services
- **Agent loop**: MAF handles the full agentic tool-calling loop via `agent.run()`
- **Key difference**: `@tool` decorator instead of `@kernel_function`; built-in tool calling loop

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check with model and engine info |
| `GET` | `/api/agents/info` | List all agents with tools and configuration |
| `POST` | `/api/agents/chat` | Multi-agent chat with SSE streaming |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_OPENAI_API_KEY` | Yes | — | Azure OpenAI API key |
| `AZURE_OPENAI_ENDPOINT` | Yes | — | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_DEPLOYMENT` | No | `gpt-5-1` | Deployment name |
| `MAX_TOKENS` | No | `4096` | Max tokens per response |
| `GITHUB_TOKEN` | Yes | — | GitHub PAT for tool API calls |
| `GITHUB_OWNER` | No | `Ohorizons` | GitHub organization |
| `MCP_ECOSYSTEM_URL` | No | `http://host.docker.internal:3100/mcp` | MCP Ecosystem server URL |
| `BACKSTAGE_URL` | No | `http://host.docker.internal:7007` | Backstage instance URL |
| `PROMETHEUS_URL` | No | `http://host.docker.internal:9090` | Prometheus endpoint |
| `GRAFANA_URL` | No | `http://host.docker.internal:3000` | Grafana endpoint |
| `KUBE_API_URL` | No | `http://host.docker.internal:8001` | Kubernetes API proxy URL |
| `CORS_ORIGINS` | No | `http://localhost:3000,http://localhost:7007` | Comma-separated allowed origins |
| `ENABLE_STDIO_MCPS` | No | `false` | Enable npx/docker-based Stdio MCP servers |
| `HOST` | No | `0.0.0.0` | Server bind address |
| `PORT` | No | `8010` | Server port |
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
docker compose up agent-api-maf -d
docker compose logs -f agent-api-maf
```

The container binds to `127.0.0.1:8010`, mounts Docker socket for Stdio MCPs, and uses `host.docker.internal` to reach local services.

## Deployment

- **Namespace**: `backstage`
- **Service**: `agent-api-maf` (port 8010)
- **Image**: `acropenhorizonsdev.azurecr.io/ohorizons-agent-api:v7.1.0-demo` (MAF variant)
- **Backstage proxy**: `/api/proxy/agent-api` → `http://agent-api-maf:8010`
- **Runtime deps**: Node.js 22 LTS and Docker CLI installed in container for MCP Stdio tools

## Configuration

- **Agents**: 7 agents defined inline — orchestrator, pipeline, sentinel, compass, guardian, lighthouse, forge
- **Tools**: `tools/` — `github_tools.py`, `observability_tools.py`, `infra_tools.py`, `backstage_tools.py`
- **MCP HTTP**: MCP Ecosystem, Microsoft Learn, Figma (conditional on `FIGMA_TOKEN`)
- **MCP Stdio**: Azure DevOps, Playwright, Awesome Copilot, Azure MCP (conditional on `ENABLE_STDIO_MCPS`)
- **Agent routing**: Sticky per conversation — detected agent persists until a new `@mention` overrides it
