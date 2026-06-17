# Agent API — Multi-Agent AI Chat Backend

The primary AI Chat backend for the Open Horizons platform. Provides a 7-agent system powered by Azure OpenAI with SSE streaming, trajectory logging, cost tracking, and shared context store (CA-MCP).

## Architecture

```
Backstage UI → /api/proxy/agent-api/* → FastAPI (port 8008) → Azure OpenAI (GPT-5.1)
```

- **Model**: Azure OpenAI GPT-5.1 via Azure AI Foundry
- **Auth**: API key or Azure AD (DefaultAzureCredential) — supports Workload Identity on AKS
- **Agent Router**: `@mention` → keyword match → orchestrator fallback
- **Middleware**: Trajectory logging (L5), cost tracking (L5), shared context store (L3 CA-MCP)
- **Tools**: Unified tool executor with MCP integration

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check with model and deployment info |
| `GET` | `/api/agents/info` | List all agents with tools and configuration |
| `POST` | `/api/agents/chat` | Multi-agent chat with SSE streaming |
| `GET` | `/api/agents/trajectories` | Trajectory summary for observability dashboard |
| `GET` | `/api/agents/trajectories/{agent}` | Recent trajectories for a specific agent |
| `GET` | `/api/agents/costs` | Cost summary across all agents |
| `GET` | `/api/agents/costs/{agent}` | Cost summary for a specific agent |
| `GET` | `/api/agents/context` | Shared context store summary |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_OPENAI_ENDPOINT` | Yes | — | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_API_KEY` | No | — | API key (omit to use DefaultAzureCredential) |
| `AZURE_OPENAI_API_VERSION` | No | `2025-04-01-preview` | API version |
| `AZURE_OPENAI_DEPLOYMENT` | No | `gpt-5-1` | Deployment name |
| `MODEL_DISPLAY_NAME` | No | `gpt-5.1` | Display name for info endpoints |
| `CORS_ORIGINS` | No | `http://localhost:3000,http://localhost:7007` | Comma-separated allowed origins |
| `HOST` | No | `0.0.0.0` | Server bind address |
| `PORT` | No | `8008` | Server port |
| `LOG_LEVEL` | No | `INFO` | Logging level |

## Local Development

```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your Azure OpenAI credentials

# Run directly
pip install -r requirements.txt
python main.py

# Or via docker-compose (from backstage/server/)
docker compose up agent-api -d
docker compose logs -f agent-api
```

The container binds to `127.0.0.1:8008` and joins the `ohorizons-platform` Docker network.

## Deployment

- **Namespace**: `backstage`
- **Service**: `agent-api` (port 8008)
- **Image**: `acropenhorizonsdev.azurecr.io/ohorizons-agent-api:v7.1.0-demo`
- **Backstage proxy**: `/api/proxy/agent-api` → `http://agent-api:8008`
- **Auth on AKS**: Workload Identity (no API key needed)

## Configuration

- **Agents**: Defined in `agents/` — orchestrator, pipeline, sentinel, compass, guardian, lighthouse, forge
- **Tools**: Registered in `tools/` — GitHub REST API, Backstage catalog, MCP actions
- **Memory**: `memory/context_store.py` — cross-agent shared state (L3 CA-MCP)
- **Middleware**: `middleware/trajectory.py` and `middleware/cost_tracker.py` — L5 observability
- **Conversation**: In-memory store keyed by `conversation_id`
