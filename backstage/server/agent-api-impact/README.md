# Agent API Impact — AI Impact Analysis Backend

Measures the real impact of AI and Agentic DevOps on the SDLC. Collects Copilot billing, developer velocity, DORA metrics, and security posture from GitHub APIs, then generates executive-grade analyses using Azure OpenAI with ChromaDB RAG for historical insights.

## Architecture

```
Backstage UI → /api/proxy/agent-api-impact/* → FastAPI (port 8011) → GitHub APIs + Azure OpenAI
```

- **Model**: Azure OpenAI GPT-5.1 via Azure AI Foundry (for LLM analysis)
- **Auth**: Azure AD (DefaultAzureCredential) for OpenAI; GitHub PAT for API calls
- **Data**: Collectors fetch live metrics from GitHub REST API; snapshots cached in SQLite
- **RAG**: ChromaDB stores analysis insights for historical context retrieval
- **Persistent volume**: `/app/data` mounted for SQLite and ChromaDB storage

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check with org name and insight count |
| `GET` | `/api/impact/summary` | Consolidated AI Impact KPIs (cached or fresh) |
| `GET` | `/api/impact/copilot` | Copilot billing and usage metrics |
| `GET` | `/api/impact/velocity` | Developer velocity and org activity |
| `GET` | `/api/impact/quality` | DORA metrics and security posture |
| `GET` | `/api/impact/adoption` | AI adoption rates and seat utilization |
| `POST` | `/api/impact/analyze` | On-demand LLM analysis with RAG context |
| `GET` | `/api/impact/insights` | All stored RAG insights |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_OPENAI_ENDPOINT` | Yes | — | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_API_KEY` | No | — | API key (omit to use DefaultAzureCredential) |
| `AZURE_OPENAI_API_VERSION` | No | `2025-04-01-preview` | API version |
| `AZURE_OPENAI_DEPLOYMENT` | No | `gpt-5-1` | Deployment name |
| `GITHUB_TOKEN` | Yes | — | GitHub PAT for API access |
| `GITHUB_ORG` | No | `Ohorizons` | GitHub organization |
| `GITHUB_REPO` | No | `open-horizons-platform` | Target repository |
| `CORS_ORIGINS` | No | `http://localhost:3000,http://localhost:7007` | Comma-separated allowed origins |
| `HOST` | No | `0.0.0.0` | Server bind address |
| `PORT` | No | `8011` | Server port |
| `LOG_LEVEL` | No | `INFO` | Logging level |

## Local Development

```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your Azure OpenAI credentials and GitHub token

# Run directly
pip install -r requirements.txt
python main.py

# Or via docker-compose (from backstage/server/)
docker compose up agent-api-impact -d
docker compose logs -f agent-api-impact
```

The container binds to `127.0.0.1:8011` with a persistent `impact-data` volume for SQLite and ChromaDB.

## Deployment

- **Namespace**: `backstage`
- **Service**: `agent-api-impact` (port 8011)
- **Image**: `acropenhorizonsdev.azurecr.io/ohorizons-agent-api-impact:v7.1.0-demo`
- **Backstage proxy**: `/api/proxy/agent-api-impact` → `http://agent-api-impact:8011`
- **Auth on AKS**: Workload Identity for Azure OpenAI; GitHub token via Key Vault

## Configuration

- **Collectors**: `collectors/` — `copilot.py` (billing/usage), `developer.py` (org activity), `pipelines.py` (DORA), `security.py` (posture)
- **Analyzers**: `analyzers/kpi_engine.py` — calculates composite AI Impact Score
- **Memory**: `memory/metrics_store.py` (SQLite snapshots), `memory/knowledge_base.py` (ChromaDB RAG)
- **Analysis prompt**: Structured 6-section executive format with minimum 700-word output
- **Analysis output**: Stored as RAG insights for future context retrieval
