# Open Horizons AI Chat Plugin

Backstage plugin that provides an AI-powered chat interface using **Azure OpenAI SDK + MCP tools**.

Inspired by the [Backstage AI Chat Plugin with Azure AI Foundry Agents](https://moimhossain.com/2025/10/14/building-backstage-ai-chat-plugin-with-azure-ai-foundry-agents/) article, but replaces Azure AI Foundry with **Anthropic Azure OpenAI SDK** and the .NET backend with **Python FastAPI**.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Backstage Frontend (React)                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  @open-horizons/plugin-ai-chat                       │   │
│  │  ChatPage.tsx → ChatService.ts (SSE client)          │   │
│  └───────────────────┬──────────────────────────────────┘   │
│                      │ POST /api/proxy/agent-api/...        │
│  ┌───────────────────┴──────────────────────────────────┐   │
│  │  @backstage/plugin-proxy-backend                     │   │
│  │  Forwards to http://localhost:8008                    │   │
│  └───────────────────┬──────────────────────────────────┘   │
└──────────────────────┼──────────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────────┐
│  Python FastAPI Backend (server/agent-api)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  main.py                                              │   │
│  │  ├─ POST /api/agents/chat  (SSE streaming)           │   │
│  │  ├─ GET  /api/agents/health                          │   │
│  │  ├─ Azure OpenAI SDK (anthropic)                            │   │
│  │  ├─ MCP Tool definitions (8 tools)                   │   │
│  │  └─ System prompt (platform context)                  │   │
│  └──────────────────────────────────────────────────────┘   │
│             │                        │                       │
│  ┌──────────┴────────┐  ┌──────────┴────────────────┐      │
│  │ Claude API        │  │ Backstage MCP Actions      │      │
│  │ (anthropic.com)   │  │ (localhost:7007/api/mcp)   │      │
│  └───────────────────┘  └───────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Key Differences from the Original Article

| Aspect | Original (Azure AI Foundry) | Open Horizons (Azure OpenAI SDK) |
|--------|----------------------------|---------------------------|
| **Backend** | .NET 10 minimal API | Python FastAPI |
| **AI Model** | GPT-4o via Azure AI Foundry | Claude Sonnet via Anthropic API |
| **Auth** | Managed Identity + DefaultAzureCredential | API Key (AZURE_OPENAI_API_KEY) |
| **Streaming** | .NET IAsyncEnumerable + SSE | FastAPI StreamingResponse + SSE |
| **Threads** | Server-side thread management | In-memory conversation history |
| **Tools** | Azure AI Foundry Agent tools | Claude native tool use + MCP |
| **Deploy** | Azure Container Apps | Docker / Kubernetes / Any |

## MCP Tools Available

The agent has access to 8 MCP tools that integrate with the Backstage platform:

1. **backstage_catalog_search** — Search software catalog (components, APIs, resources)
2. **backstage_techdocs_search** — Search TechDocs documentation
3. **github_security_alerts** — Query GitHub Advanced Security alerts
4. **backstage_scaffolder_list_templates** — List golden path templates
5. **backstage_scaffolder_create** — Scaffold new projects from templates
6. **copilot_metrics_summary** — Get Copilot adoption and usage metrics
7. **onboarding_progress** — Track developer onboarding steps
8. **platform_status** — Check platform service health

## Quick Start

### 1. Start the Python backend

```bash
cd backstage/server/agent-api

# Create .env from example
cp .env.example .env
# Edit .env and add your AZURE_OPENAI_API_KEY

# Install dependencies
pip install -r requirements.txt

# Run the server
python main.py
# → Agent API running at http://localhost:8008
```

### 2. Install the frontend plugin

```bash
cd backstage

# Add the plugin to the app package
yarn --cwd packages/app add @open-horizons/plugin-ai-chat

# Start Backstage
yarn dev
```

### 3. Access AI Chat

Navigate to **http://localhost:3000/ai-chat** or click **AI Chat** in the sidebar.

## Configuration

### app-config.yaml

The proxy endpoint is already configured:

```yaml
proxy:
  endpoints:
    '/agent-api':
      target: 'http://localhost:8008'
      changeOrigin: true
      allowedMethods: ['GET', 'POST']
```

### Environment Variables (Backend)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_OPENAI_API_KEY` | Yes | — | Azure OpenAI API key |
| `AZURE_OPENAI_DEPLOYMENT` | No | `claude-sonnet-4-20250514` | Claude model to use |
| `MAX_TOKENS` | No | `4096` | Max tokens per response |
| `HOST` | No | `0.0.0.0` | Server bind address |
| `PORT` | No | `8008` | Server port |
| `CORS_ORIGINS` | No | `http://localhost:3000,...` | Allowed CORS origins |
| `MCP_ENDPOINT` | No | — | Backstage MCP Actions URL |

## Production Deployment

### Docker

```bash
cd backstage/server/agent-api
docker build -t open-horizons-agent .
docker run -p 8008:8008 \
  -e AZURE_OPENAI_API_KEY=your-azure-openai-key \
  -e AZURE_OPENAI_DEPLOYMENT=claude-sonnet-4-20250514 \
  open-horizons-agent
```

### Kubernetes

Deploy alongside the Backstage pod with the agent as a sidecar or separate deployment.
Use Kubernetes Secrets for the `AZURE_OPENAI_API_KEY`.

## File Structure

```
backstage/
├── plugins/ai-chat/               # Backstage frontend plugin
│   ├── package.json
│   └── src/
│       ├── index.ts                # Public API
│       ├── plugin.ts               # Plugin + routable extension
│       ├── routes.ts               # Route ref
│       └── components/ChatPage/
│           ├── ChatPage.tsx         # Main chat UI
│           └── ChatService.ts       # SSE streaming client
│
├── server/agent-api/               # Python backend
│   ├── main.py                     # FastAPI + Azure OpenAI SDK
│   ├── requirements.txt            # Python dependencies
│   ├── Dockerfile                  # Container build
│   └── .env.example                # Environment template
│
├── packages/app/src/
│   ├── App.tsx                     # Route: /ai-chat → AiChatPage
│   └── components/Root/Root.tsx    # Sidebar: AI Chat item
│
└── app-config.yaml                 # Proxy: /agent-api → :8008
```
