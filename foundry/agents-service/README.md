# Open Horizons Foundry Agents Service

OpenAI-compatible HTTP gateway backed by **Azure OpenAI** (Foundry resource), with
a set of specialised agents for the Open Horizons Agentic DevOps Platform.

## Why this exists

- Backstage plugins (`ai-chat`, agent backends) speak the OpenAI Chat
  Completions protocol. Azure OpenAI uses a different URL scheme
  (`/openai/deployments/{name}/chat/completions?api-version=...`) and an
  `api-key` header instead of `Authorization: Bearer`.
- This service translates between them, so any OpenAI-compatible client can
  talk to Azure OpenAI by pointing at `http://open-horizons-foundry-agents:8080/v1`.
- It also exposes per-agent endpoints (`architect`, `devops`, `sre`, `platform`)
  that auto-inject the agent's system prompt and recommended temperature.

## Endpoints

| Method | Path                              | Purpose                                  |
|--------|-----------------------------------|------------------------------------------|
| GET    | `/healthz`                        | Liveness probe                           |
| GET    | `/readyz`                         | Readiness probe                          |
| GET    | `/v1/models`                      | OpenAI-compatible model list             |
| GET    | `/v1/agents`                      | List specialized agents                  |
| POST   | `/v1/chat/completions`            | OpenAI-compatible chat (raw)             |
| POST   | `/v1/agents/{agent_id}/chat`      | Same payload but with agent system prompt|

Streaming (`stream: true`) is supported and forwarded as SSE.

## Environment variables

| Var                              | Required | Default                  |
|----------------------------------|----------|--------------------------|
| `AZURE_OPENAI_ENDPOINT`          | yes      | —                        |
| `AZURE_OPENAI_API_KEY`           | yes      | —                        |
| `AZURE_OPENAI_DEPLOYMENT`        | no       | `gpt-5.1`                |
| `AZURE_OPENAI_API_VERSION`       | no       | `2024-08-01-preview`     |
| `AZURE_OPENAI_EMBEDDING_DEPLOYMENT` | no    | `text-embedding-3-large` |
| `SERVICE_API_KEY`                | no       | unset → no auth          |
| `LOG_LEVEL`                      | no       | `INFO`                   |
| `REQUEST_TIMEOUT_SECONDS`        | no       | `60`                     |

## Local run

```bash
cd new-features/foundry/agents-service
pip install -r requirements.txt

export AZURE_OPENAI_ENDPOINT="https://oai-openhorizonsdev1215.openai.azure.com"
export AZURE_OPENAI_API_KEY="..."
export AZURE_OPENAI_DEPLOYMENT="gpt-5.1"

uvicorn app.main:app --reload --port 8080

# In another shell:
curl localhost:8080/v1/agents | jq
curl -X POST localhost:8080/v1/agents/architect/chat \
  -H 'content-type: application/json' \
  -d '{"messages":[{"role":"user","content":"Como modelar multi-tenant no AKS?"}]}' | jq
```

## Container build

```bash
docker build -t ghcr.io/ohorizons/ohorizons-foundry-agents:v7.2.4 .
docker push ghcr.io/ohorizons/ohorizons-foundry-agents:v7.2.4
```

## Deploy on AKS/ARO

See `deploy/helm/open-horizons/foundry-agents/` for the Kubernetes manifests.
