# MCP Ecosystem — Architecture

> Status: current · Scope: `mcp-servers/` · Layer: **L3 Context Engineering**
> Companion skill: [mcp-ecosystem skill](../.github/skills/mcp-ecosystem/SKILL.md)

The **MCP Ecosystem** is Open Horizons' own [Model Context Protocol](https://modelcontextprotocol.io)
server. It exposes **61 tools across 12 modules** that fetch live, cached
reference data — methodology, format specs, templates, UI components, plugin
catalogs, and documentation — from curated upstream sources. It is the runtime
that lets platform agents and the Backstage **AI Chat** ground answers in real,
current upstream documentation instead of relying on model recall.

---

## 1. Where it fits

```mermaid
flowchart LR
    subgraph L5["L5 Agentic Execution"]
        AIChat["Backstage AI Chat<br/>(agent-api)"]
        Agents["Platform agents<br/>orchestrator · sentinel · forge …"]
    end
    subgraph L3["L3 Context Engineering"]
        ECO["MCP Ecosystem server<br/>:3100 /mcp · 12 modules · 61 tools"]
        CACHE["On-disk cache<br/>cache.json · TTL 1h"]
    end
    subgraph UP["Upstream sources (read-only)"]
        GH["raw.githubusercontent.com<br/>GitHub Contents / Trees API"]
    end

    AIChat -->|JSON-RPC over HTTP| ECO
    Agents -->|MCP client| ECO
    ECO --> CACHE
    ECO -->|fetch + cache| GH
```

**Two distinct MCP surfaces** (do not conflate):

| Surface | What it is | File |
| --- | --- | --- |
| **MCP Ecosystem** (this doc) | *Implemented* server serving documentation/reference tools | [mcp-servers/](.) |
| **Infra MCP policy** | *Access policy* mapping runtime agents → operational MCP servers (`azure`, `github`, `terraform`, `kubernetes`, …) | [mcp-config.json](mcp-config.json) |

---

## 2. Component architecture

```mermaid
flowchart TB
    subgraph Server["mcp-ecosystem (Node.js / TypeScript)"]
        IDX["index.ts<br/>registerAllTools()"]
        FACT["shared/server-factory.ts<br/>Express + Streamable HTTP<br/>per-session McpServer"]
        subgraph Shared["shared/"]
            CACHE["cache.ts<br/>Map + cache.json (TTL)"]
            FETCH["github-fetcher.ts<br/>fetchRaw · listContents · listTree"]
            TYPES["types.ts"]
        end
        subgraph Tools["src/tools/ — 12 modules"]
            GA["Group A · Agent & AI frameworks (7)<br/>spec-kit · anthropics-skills · awesome-copilot<br/>agent-framework · gh-aw · agents-md · github-copilot-docs"]
            GB["Group B · Backstage ecosystem (5)<br/>backstage-docs · backstage-plugins · backstage-ui<br/>spotify-backstage · backstage-org"]
        end
    end

    FACT --> IDX --> Tools
    Tools --> FETCH --> CACHE
    Tools -.->|register| FACT
```

- **`src/index.ts`** — composition root. `registerAllTools(server)` wires every
  module's `register<Name>Tools(server)` in two groups (A: agent/AI frameworks,
  B: Backstage ecosystem).
- **`src/shared/server-factory.ts`** — builds an `McpServer` (`mcp-ecosystem`
  v1.0.0, capabilities: tools/prompts/resources) and runs the Express HTTP host.
- **`src/shared/`** — cross-cutting cache, GitHub fetchers, and types.
- **`src/tools/<module>.ts`** — one file per module; each registers N tools via
  `server.tool(name, description, schema, handler)`.

---

## 3. Transport & session model

The server speaks **MCP over Streamable HTTP** (`StreamableHTTPServerTransport`)
on a single `/mcp` endpoint, with per-session isolation.

```mermaid
sequenceDiagram
    participant C as Client (AI Chat / agent)
    participant E as Express /mcp
    participant T as Transport (per session)
    participant S as McpServer (per session)
    participant U as Upstream + cache

    C->>E: POST /mcp (no session id) — initialize
    E->>T: new transport (randomUUID session)
    E->>S: createServer() + registerTools()
    S-->>C: result + Mcp-Session-Id header
    C->>E: POST /mcp (Mcp-Session-Id) tools/call
    E->>S: dispatch tool
    S->>U: cacheGet → miss → fetch → cacheSet
    U-->>C: tool result (JSON)
    C->>E: DELETE /mcp (Mcp-Session-Id) — close
    E->>T: drop session
```

| Route | Purpose |
| --- | --- |
| `POST /mcp` | Initialize a session (no `Mcp-Session-Id`) or send a request (with id). Unknown id → `404`. |
| `GET /mcp` | Server-to-client stream for an active session (`400` if none). |
| `DELETE /mcp` | Tear down a session. |
| `GET /health` | `{ "status": "ok", "sessions": N }` — used by container/K8s probes. |

Each session gets a **fresh `McpServer` instance** to avoid "Already connected"
errors; transports are tracked in a `Map` and removed on `onclose`/`DELETE`.
`uncaughtException`/`unhandledRejection` handlers keep the process alive.

---

## 4. Data layer — fetch & cache

All upstream reads go through `shared/github-fetcher.ts` and are cached by
`shared/cache.ts`:

- **`fetchRaw(owner, repo, path, branch)`** → `raw.githubusercontent.com`.
- **`listContents(owner, repo, path, branch)`** → GitHub Contents API.
- **`listTree(owner, repo, branch, prefix)`** → Git Trees API (recursive, one call).

Cache characteristics:

- **Write-through**: in-memory `Map` + persisted to `${CACHE_DIR}/cache.json`.
- **TTL**: `CACHE_TTL_MS` (default `3600000` = 1h); expired entries are skipped
  on read and pruned on load.
- **Durable**: cache survives restarts (loaded on startup); corrupt files are
  discarded and repopulated.
- **Resilient**: cache write failures are non-fatal.
- **Auth**: optional `GH_TOKEN` (Bearer) raises GitHub raw/API rate limits.

---

## 5. Tool catalog (12 modules · 61 tools)

### Group A — Agent & AI frameworks (7 modules · 30 tools)

| Module | Prefix | Count | Tools |
| --- | --- | --- | --- |
| spec-kit | `speckit_` | 5 | `get_phases`, `get_commands`, `get_methodology`, `get_philosophy`, `search` |
| anthropics-skills | `anthropics_` | 5 | `list_skills`, `get_skill`, `get_skill_template`, `search_skills`, `get_spec` |
| awesome-copilot | `awesome_` | 4 | `list_items`, `get_item`, `search`, `get_readme` |
| agent-framework | `agentfw_` | 4 | `get_patterns`, `get_sample`, `search_docs`, `get_declarative_agents` |
| gh-aw | `ghaw_` | 4 | `get_workflow_patterns`, `get_security_guidelines`, `get_contributing`, `get_agents_md` |
| agents-md | `agentsmd_` | 3 | `get_format_spec`, `get_readme`, `get_section_templates` |
| `github-copilot-docs` | `copilotdocs_` | 5 | `list_sections`, `get_page`, `search`, `get_customization`, `get_extensions` |

### Group B — Backstage ecosystem (5 modules · 31 tools)

| Module | Prefix | Count | Tools |
| --- | --- | --- | --- |
| `backstage-docs` | `backstagedocs_` | 7 | `list_sections`, `get_page`, `search`, `get_catalog`, `get_software_templates`, `get_plugins`, `get_api_reference` |
| `backstage-plugins` | `backstageplugins_` | 6 | `list_directory`, `list_community`, `get_community_plugin`, `search_community`, `list_core`, `get_core_plugin` |
| `backstage-ui` | `backstageui_` | 8 | `list_components`, `get_component`, `get_api_report`, `get_readme`, `get_changelog`, `storybook_list_stories`, `storybook_get_story`, `storybook_search` |
| `spotify-backstage` | `spotifybackstage_` | 6 | `list_sections`, `get_page`, `get_portal_docs`, `get_plugins_docs`, `get_core_features`, `discover_links` |
| `backstage-org` | `backstageorg_` | 4 | `list_repos`, `get_repo_readme`, `search_repos`, `get_backstage_plugins` |

Full tool name = `prefix + suffix`, e.g. `speckit_get_phases`,
`backstageui_storybook_search`.

---

## 6. AI Chat integration

The Backstage **AI Chat** (agent-api) connects through a thin Python client and
advertises a curated subset of tools to the model.

- **Client**: [agent-api MCP Ecosystem client](../backstage/server/agent-api/tools/mcp_ecosystem.py)
- **Target URL**: `MCP_ECOSYSTEM_URL` (default `http://localhost:3100/mcp`;
  in-cluster → the `mcp-ecosystem` Service).
- **Advertised tools** (orchestrator, sentinel, lighthouse, guardian, forge, pipeline):

| Model-facing tool | Maps to ecosystem tool |
| --- | --- |
| `ecosystem_list_tools` | `tools/list` (discovery) |
| `ecosystem_call_tool(name, args)` | any of the 61 tools |
| `search_backstage_docs(query)` | `backstagedocs_search` |
| `get_spec_kit_methodology()` | `speckit_get_methodology` |
| `search_copilot_docs(query)` | `copilotdocs_search` |
| `search_anthropic_docs(query)` | `anthropics_search_skills` |

If the server is unreachable, the client **degrades gracefully** — the chat
answers without grounding rather than failing the request.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Chat as AI Chat (agent-api)
    participant Eco as MCP Ecosystem :3100
    Dev->>Chat: "How do Backstage software templates work?"
    Chat->>Eco: tools/call backstagedocs_search {query}
    Eco-->>Chat: cached upstream docs
    Chat-->>Dev: grounded answer + source attribution
```

---

## 7. Deployment

### Local (Docker Compose)

```bash
cd mcp-servers
make up      # docker compose up -d --build  → :3100
make health  # curl http://localhost:3100/health
make logs
make down
```

`docker-compose.yml`: `restart: unless-stopped`, port `3100`, a named volume for
`CACHE_DIR`, and `GH_TOKEN`/`CACHE_TTL_MS` passthrough.

### Container image

Published to GHCR as `mcp-ecosystem` (multi-stage Node build; see
[Dockerfile](Dockerfile) and the platform CHANGELOG for the current tag). Never
use `:latest` in manifests.

### Kubernetes / AKS

Deploy as a Deployment + Service in the platform namespace; probe `GET /health`
for liveness/readiness; mount a PVC at `CACHE_DIR` to persist the cache; inject
`GH_TOKEN` from Key Vault via CSI. The AI Chat reaches it via the in-cluster
`mcp-ecosystem` Service DNS name on port 3100.

---

## 8. Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `3100` | HTTP listen port |
| `CACHE_DIR` | `<cwd>/cache` | Cache directory (mount a volume) |
| `CACHE_TTL_MS` | `3600000` | Cache TTL (1 hour) |
| `GH_TOKEN` | (empty) | Optional GitHub token to raise upstream rate limits |
| `MCP_ECOSYSTEM_URL` | `http://localhost:3100/mcp` | **Client-side** (agent-api) target URL |

---

## 9. Security

- **Read-only**: the server only performs `GET` reads against public upstream
  sources; it holds no write credentials and mutates no external state.
- **Secrets**: `GH_TOKEN` is optional and injected via env/Key Vault, never
  committed. It is a low-privilege read token.
- **Network egress**: only `raw.githubusercontent.com` and `api.github.com`.
- **Tenancy**: per-session transports isolate concurrent clients; unknown
  session ids are rejected (`404`).
- **Resilience**: global exception handlers prevent crashes; cache failures and
  upstream errors are contained per request.
- **Supply chain**: pin the GHCR tag; scan the image (Trivy) in CI.

---

## 10. Observability

- **Health/readiness**: `GET /health` → `{ status, sessions }`.
- **Logs**: structured `[mcp-ecosystem]` prefixed stderr for transport/handler
  errors and lifecycle events.
- **Capacity signal**: `sessions` count surfaces active client load.

---

## 11. Extending the server

1. Create `src/tools/<module>.ts` exporting
   `register<Module>Tools(server: McpServer)`; register tools with
   `server.tool(name, description, zodSchema, handler)`.
2. Fetch upstream via `shared/github-fetcher.ts`; never bypass the cache.
3. Wire it into `src/index.ts` `registerAllTools()` under Group A or B.
4. **Keep counts in sync** across: this file, [README.md](README.md), the
   [mcp-ecosystem skill](../.github/skills/mcp-ecosystem/SKILL.md),
   and the platform docs.
5. If the AI Chat should expose it, add a convenience wrapper + advertise it in
   the relevant agents under `backstage/server/agent-api/`.

---

## 12. References

- Source: [mcp-servers/](.) · [src/index.ts](src/index.ts) · [src/shared/server-factory.ts](src/shared/server-factory.ts)
- Server README: [README.md](README.md) · Usage: [USAGE.md](USAGE.md)
- Skill: [mcp-ecosystem skill](../.github/skills/mcp-ecosystem/SKILL.md)
- AI Chat client: [agent-api MCP Ecosystem client](../backstage/server/agent-api/tools/mcp_ecosystem.py)
- Model Context Protocol: <https://modelcontextprotocol.io>
