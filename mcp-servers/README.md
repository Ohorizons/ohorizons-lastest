# MCP Ecosystem Server

A unified MCP server that exposes **61 tools across 12 modules** from curated
reference sources, running in a single Docker container. Auto-starts with your
computer.

> Architecture deep-dive: [ARCHITECTURE.md](ARCHITECTURE.md) ·
> Platform skill: [mcp-ecosystem skill](../.github/skills/mcp-ecosystem/SKILL.md)

## Where it runs

The same image serves **two phases** of the platform lifecycle:

| Phase | Where | Who uses it |
| --- | --- | --- |
| **1 · Installation** | **Local** (this `docker compose`, `:3100`) | The operator + Copilot agents while **building** the platform |
| **2 · Runtime** | **Azure / AKS** (`ai-services` namespace, gated to `enable_mcp_ecosystem`) | The Backstage **AI Chat** that developers use |

At runtime the AI Chat (`agent-api`, same namespace) reaches it at
`http://mcp-ecosystem.ai-services.svc.cluster.local:3100/mcp`; a `NetworkPolicy`
restricts `:3100` to the `agent-api` pod. The operational MCP servers
(`azure`, `github`, `terraform`, …) in [mcp-config.json](mcp-config.json) are a
separate, local-only surface and are not deployed to AKS. See
[ARCHITECTURE.md](ARCHITECTURE.md#7-deployment--lifecycle) for the full picture.

## Sources

### Group A — Agent & AI frameworks (7 modules · 30 tools)

| Source | Tools | Upstream |
| --- | --- | --- |
| **Spec-Kit** (5) | `speckit_get_phases`, `speckit_get_commands`, `speckit_get_methodology`, `speckit_get_philosophy`, `speckit_search` | [`github/spec-kit`](https://github.com/github/spec-kit) |
| **Anthropics Skills** (5) | `anthropics_list_skills`, `anthropics_get_skill`, `anthropics_get_skill_template`, `anthropics_search_skills`, `anthropics_get_spec` | [anthropics/skills](https://github.com/anthropics/skills) |
| **Awesome Copilot** (4) | `awesome_list_items`, `awesome_get_item`, `awesome_search`, `awesome_get_readme` | [`github/awesome-copilot`](https://github.com/github/awesome-copilot) |
| **Agent Framework** (4) | `agentfw_get_patterns`, `agentfw_get_sample`, `agentfw_search_docs`, `agentfw_get_declarative_agents` | [microsoft/agent-framework](https://github.com/microsoft/agent-framework) |
| **GitHub Agentic Workflows** (4) | `ghaw_get_workflow_patterns`, `ghaw_get_security_guidelines`, `ghaw_get_contributing`, `ghaw_get_agents_md` | [`github/gh-aw`](https://github.com/github/gh-aw) |
| **AGENTS.md** (3) | `agentsmd_get_format_spec`, `agentsmd_get_readme`, `agentsmd_get_section_templates` | [agentsmd/agents.md](https://github.com/agentsmd/agents.md) |
| **GitHub Copilot Docs** (5) | `copilotdocs_list_sections`, `copilotdocs_get_page`, `copilotdocs_search`, `copilotdocs_get_customization`, `copilotdocs_get_extensions` | [`docs.github.com/en/copilot`](https://docs.github.com/en/copilot) |

### Group B — Backstage ecosystem (5 modules · 31 tools)

| Source | Tools | Upstream |
| --- | --- | --- |
| **Backstage Docs** (7) | `backstagedocs_list_sections`, `backstagedocs_get_page`, `backstagedocs_search`, `backstagedocs_get_catalog`, `backstagedocs_get_software_templates`, `backstagedocs_get_plugins`, `backstagedocs_get_api_reference` | [`backstage/backstage`](https://github.com/backstage/backstage) |
| **Backstage Plugins** (6) | `backstageplugins_list_directory`, `backstageplugins_list_community`, `backstageplugins_get_community_plugin`, `backstageplugins_search_community`, `backstageplugins_list_core`, `backstageplugins_get_core_plugin` | [`backstage/community-plugins`](https://github.com/backstage/community-plugins) |
| **Backstage UI** (8) | `backstageui_list_components`, `backstageui_get_component`, `backstageui_get_api_report`, `backstageui_get_readme`, `backstageui_get_changelog`, `backstageui_storybook_list_stories`, `backstageui_storybook_get_story`, `backstageui_storybook_search` | [`backstage/backstage` (ui)](https://github.com/backstage/backstage) |
| **Spotify Backstage** (6) | `spotifybackstage_list_sections`, `spotifybackstage_get_page`, `spotifybackstage_get_portal_docs`, `spotifybackstage_get_plugins_docs`, `spotifybackstage_get_core_features`, `spotifybackstage_discover_links` | [`backstage.spotify.com`](https://backstage.spotify.com) |
| **Backstage Org** (4) | `backstageorg_list_repos`, `backstageorg_get_repo_readme`, `backstageorg_search_repos`, `backstageorg_get_backstage_plugins` | [`github.com/backstage`](https://github.com/backstage) |

**Total:** 61 tools across 12 modules

## Quick Start

```bash
# 1. Copy and configure environment
cp .env.example .env
# Edit .env and add your GH_TOKEN (optional but recommended)

# 2. Build and start
make up

# 3. Verify
make health
# → { "status": "ok", "sessions": 0 }
```

> **Port already in use?** Grafana Loki also defaults to `3100`. Run on another
> host port with `MCP_ECOSYSTEM_PORT=3101 docker compose up -d`.

### Deploy to AKS with your own ACR

The AKS manifests default to the public GHCR image. To use a private ACR:

```bash
# Import once per tag, then point the installer at the ACR path
az acr import --name <your-acr> \
  --source ghcr.io/ohorizons/mcp-ecosystem:<tag> --image mcp-ecosystem:<tag>
export MCP_ECOSYSTEM_IMAGE="<your-acr>.azurecr.io/mcp-ecosystem:<tag>"
scripts/render-k8s.sh && scripts/render-manifests.sh
```

## Auto-Start on Boot

The container uses `restart: unless-stopped`. Combined with Docker Desktop's auto-launch:

1. **Docker Desktop** → Settings → General → ✓ "Start Docker Desktop when you log in"
2. That's it. On every login: Docker starts → container restarts → `http://localhost:3100/mcp` available

## Register in Clients

### VS Code MCP Configuration

Merge into `~/Library/Application Support/Claude/VS Code MCP settings`:

```json
{
  "mcpServers": {
    "mcp-ecosystem": {
      "url": "http://localhost:3100/mcp"
    }
  }
}
```

### VS Code (GitHub Copilot)

Add to `.vscode/settings.json`:

```json
{
  "mcp": {
    "servers": {
      "mcp-ecosystem": {
        "type": "http",
        "url": "http://localhost:3100/mcp"
      }
    }
  }
}
```

### GitHub Copilot CLI

```bash
claude mcp add mcp-ecosystem --transport http --url http://localhost:3100/mcp
```

### OpenClaw

Copy the platform skill file to your OpenClaw skills directory:

```bash
cp ../.github/skills/mcp-ecosystem/SKILL.md ~/.openclaw/skills/mcp-ecosystem/SKILL.md
```

## Commands

| Command | Description |
| --- | --- |
| `make up` | Build and start the container |
| `make down` | Stop the container |
| `make logs` | Tail container logs |
| `make status` | Show container status |
| `make rebuild` | Force rebuild and restart |
| `make clean` | Remove container, volumes, and images |
| `make health` | Check server health endpoint |
| `make test-tool` | Quick test that the MCP protocol responds |

## Architecture

```text
┌─────────────────────────────────────────────┐
│              Docker Container               │
│         mcp-ecosystem (port 3100)           │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │        Express + MCP SDK            │    │
│  │   StreamableHTTPServerTransport     │    │
│  └──────────┬──────────────────────────┘    │
│             │                               │
│  ┌──────────▼──────────────────────────┐    │
  │           Tool Modules (12)         │    │
  │  A: spec-kit │ anthropics │ awesome │    │
  │     agent-fw │ gh-aw │ agents-md    │    │
  │     github-copilot-docs             │    │
  │  B: backstage-docs │ -plugins │ -ui │    │
  │     spotify-backstage │ backstage-org│   │
│  └──────────┬──────────────────────────┘    │
│             │                               │
│  ┌──────────▼──────────────────────────┐    │
│  │      Shared Library                 │    │
│  │  github-fetcher │ cache │ types     │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  📁 /app/cache/ (Docker Volume)             │
└─────────────────────────────────────────────┘
         │
    localhost:3100/mcp
         │
    ┌────┼────────┬──────────┬───────────┐
    │    │        │          │           │
 VS Code  Claude   Claude    OpenClaw
         Desktop   Code     (via curl)
```

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `GH_TOKEN` | *(empty)* | GitHub token — increases API rate limit from 60 to 5000 req/h |
| `CACHE_TTL_MS` | `3600000` | Cache TTL in milliseconds (default: 1 hour) |
| `PORT` | `3100` | HTTP server port |
| `CACHE_DIR` | `/app/cache` | Cache directory (Docker volume mount) |
