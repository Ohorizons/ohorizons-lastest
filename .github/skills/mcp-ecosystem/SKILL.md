---
name: mcp-ecosystem
description: >-
  Access 61 tools across 12 modules from the local MCP Ecosystem server to fetch
  live methodology, templates, components, and reference data for spec-kit,
  anthropics-skills, awesome-copilot, agent-framework, gh-aw, agents-md,
  github-copilot-docs, backstage-docs, backstage-plugins, backstage-ui,
  spotify-backstage, and backstage-org. USE FOR: Spec-Driven Development phases
  and commands, Microsoft Agent Framework patterns, GitHub Agentic Workflows
  (gh-aw), AGENTS.md format and section templates, awesome-copilot
  skills/agents/prompts lookup, GitHub Copilot documentation and customization,
  Anthropic skills catalog, Backstage documentation, Software Catalog, Software
  Templates, plugin directory (core + community), Backstage UI components and
  Storybook, Spotify Portal docs, and github.com/backstage repositories. Also
  USE FOR wiring the AI Chat (agent-api) to the ecosystem so agents can ground
  answers in real upstream docs. DO NOT USE FOR general web search, infra MCP
  servers (azure/github/terraform/kubernetes — see mcp-config.json), or
  non-reference queries.
---

# MCP Ecosystem

The **MCP Ecosystem** is the platform's own Model Context Protocol (MCP) server.
It exposes **61 tools across 12 modules** that fetch live, cached reference data
(methodology, format specs, templates, components, plugin catalogs, and docs)
from curated upstream sources. It is the L3 Context Engineering surface that lets
Open Horizons agents — and the Backstage **AI Chat** — ground their answers in
real, current documentation instead of model recall.

> **Two different "MCP" surfaces — do not confuse them:**
> - **MCP Ecosystem** (this skill): the *implemented* TypeScript server in
>   [mcp-servers/](../../../mcp-servers) serving documentation/reference tools.
> - **Infra MCP policy** ([mcp-servers/mcp-config.json](../../../mcp-servers/mcp-config.json)):
>   the *access policy* mapping runtime agents to operational MCP servers
>   (azure, github, terraform, kubernetes, helm, …). That is a separate concern.

## When to use this skill

Load this skill when you need to:

- Retrieve **Spec-Driven Development** phases, commands, philosophy (spec-kit).
- Look up **Microsoft Agent Framework** patterns, samples, declarative agents.
- Get **GitHub Agentic Workflows** (gh-aw) patterns and security guidelines.
- Fetch the **AGENTS.md** format spec and section templates.
- Search **awesome-copilot** skills, agents, prompts, instructions.
- Read **GitHub Copilot** docs, customization, and extensions.
- Search the **Anthropic skills** catalog and specs.
- Query **Backstage** docs, Software Catalog, Software Templates, API reference.
- Browse the **Backstage plugin** directory (core + community).
- Inspect **Backstage UI** components and Storybook stories.
- Read **Spotify Portal** docs and discover **github.com/backstage** repos.
- Wire the **AI Chat / agent-api** so agents can call the ecosystem.

Do **not** use it for general web search, for infra/operational MCP servers, or
for anything that is not upstream reference data.

## The server at a glance

| Property | Value |
| --- | --- |
| Server name | `mcp-ecosystem` |
| Source | [mcp-servers/](../../../mcp-servers) (TypeScript, MCP SDK + Express) |
| Transport | Streamable HTTP (`StreamableHTTPServerTransport`) |
| Endpoint | `http://localhost:3100/mcp` |
| Health | `GET http://localhost:3100/health` → `{ "status": "ok", "sessions": N }` |
| Modules / tools | **12 modules · 61 tools** |
| Cache | On-disk JSON cache (`CACHE_DIR`, default 1h TTL via `CACHE_TTL_MS`) |
| Auth to upstreams | Optional `GH_TOKEN` raises GitHub raw/API rate limits |
| Image | `ohorizons` GHCR: `mcp-ecosystem` (see CHANGELOG for current tag) |

### Where it runs (two phases)

The same server image is used in two moments of the platform lifecycle:

- **Phase 1 — Installation (LOCAL):** runs on the operator's machine via Docker
  during platform build, so the Copilot agents (`@deploy`, `@terraform`, …) can
  ground build-time decisions in real upstream docs. Ephemeral; never shipped to
  Azure.
- **Phase 2 — Runtime (AZURE / AKS):** deployed to the `ai-services` namespace
  (gated to `enable_mcp_ecosystem`), where the Backstage **AI Chat** calls it to
  ground developer answers. The AI Chat (`agent-api`) lives in the same namespace
  and reaches it at `http://mcp-ecosystem.ai-services.svc.cluster.local:3100/mcp`;
  a `NetworkPolicy` restricts `:3100` to the `agent-api` pod.

Full deployment detail: [mcp-servers/ARCHITECTURE.md](../../../mcp-servers/ARCHITECTURE.md#7-deployment--lifecycle).

### Run it locally

```bash
cd mcp-servers
make up        # docker compose up -d  (builds + starts on :3100)
make health    # curl http://localhost:3100/health  → {"status":"ok"}
make logs      # follow logs
make down      # stop
```

The `.env` file is optional. The host port is configurable to avoid collisions
(Grafana **Loki** also defaults to `3100`):

```bash
MCP_ECOSYSTEM_PORT=3101 docker compose up -d
```

Environment variables (all optional): `PORT` (3100), `CACHE_DIR`,
`CACHE_TTL_MS` (3600000), `GH_TOKEN`, `MCP_ECOSYSTEM_PORT` (local host port).

## Tool catalog (12 modules · 61 tools)

### Group A — Agent & AI frameworks (7 modules · 30 tools)

| Module | Prefix | Tools |
| --- | --- | --- |
| spec-kit (5) | `speckit_` | `get_phases`, `get_commands`, `get_methodology`, `get_philosophy`, `search` |
| anthropics-skills (5) | `anthropics_` | `list_skills`, `get_skill`, `get_skill_template`, `search_skills`, `get_spec` |
| awesome-copilot (4) | `awesome_` | `list_items`, `get_item`, `search`, `get_readme` |
| agent-framework (4) | `agentfw_` | `get_patterns`, `get_sample`, `search_docs`, `get_declarative_agents` |
| gh-aw (4) | `ghaw_` | `get_workflow_patterns`, `get_security_guidelines`, `get_contributing`, `get_agents_md` |
| agents-md (3) | `agentsmd_` | `get_format_spec`, `get_readme`, `get_section_templates` |
| github-copilot-docs (5) | `copilotdocs_` | `list_sections`, `get_page`, `search`, `get_customization`, `get_extensions` |

### Group B — Backstage ecosystem (5 modules · 31 tools)

| Module | Prefix | Tools |
| --- | --- | --- |
| backstage-docs (7) | `backstagedocs_` | `list_sections`, `get_page`, `search`, `get_catalog`, `get_software_templates`, `get_plugins`, `get_api_reference` |
| backstage-plugins (6) | `backstageplugins_` | `list_directory`, `list_community`, `get_community_plugin`, `search_community`, `list_core`, `get_core_plugin` |
| backstage-ui (8) | `backstageui_` | `list_components`, `get_component`, `get_api_report`, `get_readme`, `get_changelog`, `storybook_list_stories`, `storybook_get_story`, `storybook_search` |
| spotify-backstage (6) | `spotifybackstage_` | `list_sections`, `get_page`, `get_portal_docs`, `get_plugins_docs`, `get_core_features`, `discover_links` |
| backstage-org (4) | `backstageorg_` | `list_repos`, `get_repo_readme`, `search_repos`, `get_backstage_plugins` |

> Tool names are the prefix + the suffix shown, e.g. `speckit_get_phases`,
> `backstagedocs_search`, `backstageui_storybook_search`.

## How the AI Chat uses the ecosystem

The Backstage **AI Chat** (agent-api) ships a thin Python client and advertises a
small, curated set of ecosystem tools to the model so agents can ground answers:

- Client: [backstage/server/agent-api/tools/mcp_ecosystem.py](../../../backstage/server/agent-api/tools/mcp_ecosystem.py)
- Advertised to the model (orchestrator, sentinel, lighthouse, guardian, forge, pipeline):
  - `ecosystem_list_tools` — discover everything the server exposes.
  - `ecosystem_call_tool(name, args)` — call any of the 61 tools directly.
  - `search_backstage_docs(query)` → `backstagedocs_search`
  - `get_spec_kit_methodology()` → `speckit_get_methodology`
  - `search_copilot_docs(query)` → `copilotdocs_search`
  - `search_anthropic_docs(query)` → `anthropics_search_skills`

The client targets `MCP_ECOSYSTEM_URL` (default `http://localhost:3100/mcp`).
In-cluster, point it at the `mcp-ecosystem` Service. If the server is
unreachable, the client degrades gracefully and the chat answers without
grounding rather than failing.

### Calling a tool directly (JSON-RPC over HTTP)

```bash
curl -s http://localhost:3100/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call",
       "params":{"name":"speckit_get_phases","arguments":{}}}'
```

List all tools:

```bash
curl -s http://localhost:3100/mcp -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

## Workflow for agents

1. **Discover** — if unsure which tool fits, call `ecosystem_list_tools` first.
2. **Pick the narrowest tool** — prefer `*_search` for discovery, then a
   `get_*` tool to fetch the specific page/spec/template.
3. **Cite the source** — ecosystem tools return upstream content; attribute it.
4. **Cache-aware** — responses are cached (~1h). For "latest", note staleness.
5. **Stay in scope** — for live cloud state use the infra MCPs, not this server.

## Operational notes

- **Caching:** results persist under `CACHE_DIR` with `CACHE_TTL_MS` TTL to keep
  upstream rate limits low and responses fast. Delete the cache volume to force
  a refresh.
- **Rate limits:** set `GH_TOKEN` to raise GitHub raw/API limits for the
  `backstage-org`, `backstage-plugins`, and `*_get_readme` style tools.
- **Adding a module:** create `mcp-servers/src/tools/<name>.ts` exporting a
  `register<Name>Tools(server, cache)` function, register it in
  [mcp-servers/src/index.ts](../../../mcp-servers/src/index.ts), and keep the
  README, this skill, and `mcp-servers/ARCHITECTURE.md` counts in sync.
- **Health/readiness:** `GET /health` is used for container and K8s probes.

## Related

- Architecture deep-dive: [mcp-servers/ARCHITECTURE.md](../../../mcp-servers/ARCHITECTURE.md)
- Server README: [mcp-servers/README.md](../../../mcp-servers/README.md)
- Usage guide: [mcp-servers/USAGE.md](../../../mcp-servers/USAGE.md)
- AI Chat client: [backstage/server/agent-api/tools/mcp_ecosystem.py](../../../backstage/server/agent-api/tools/mcp_ecosystem.py)
- Infra MCP policy (different surface): [mcp-servers/mcp-config.json](../../../mcp-servers/mcp-config.json)
