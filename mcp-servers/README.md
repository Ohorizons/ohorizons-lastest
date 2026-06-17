# MCP Ecosystem Server

A unified MCP server that exposes tools from 10 reference sources, running in a single Docker container. Auto-starts with your computer.

## Sources

| Source | Tools | GitHub |
|--------|-------|--------|
| **Spec-Kit** | `speckit_get_phases`, `speckit_get_commands`, `speckit_get_methodology`, `speckit_get_philosophy`, `speckit_search` | [github/spec-kit](https://github.com/github/spec-kit) |
| **Anthropics Skills** | `anthropics_list_skills`, `anthropics_get_skill`, `anthropics_get_skill_template`, `anthropics_search_skills`, `anthropics_get_spec` | [anthropics/skills](https://github.com/anthropics/skills) |
| **Awesome Copilot** | `awesome_list_items`, `awesome_get_item`, `awesome_search`, `awesome_get_readme` | [github/awesome-copilot](https://github.com/github/awesome-copilot) |
| **Agent Framework** | `agentfw_get_patterns`, `agentfw_get_sample`, `agentfw_search_docs`, `agentfw_get_declarative_agents` | [microsoft/agent-framework](https://github.com/microsoft/agent-framework) |
| **GitHub Agentic Workflows** | `ghaw_get_workflow_patterns`, `ghaw_get_security_guidelines`, `ghaw_get_contributing`, `ghaw_get_agents_md` | [github/gh-aw](https://github.com/github/gh-aw) |
| **AGENTS.md** | `agentsmd_get_format_spec`, `agentsmd_get_readme`, `agentsmd_get_section_templates` | [agentsmd/agents.md](https://github.com/agentsmd/agents.md) |
| **GitHub Copilot Docs** | `copilotdocs_list_sections`, `copilotdocs_get_page`, `copilotdocs_search`, `copilotdocs_get_customization`, `copilotdocs_get_extensions` | [docs.github.com/en/copilot](https://docs.github.com/en/copilot) |
| **Anthropic Platform Docs** | `anthropicdocs_list_sections`, `anthropicdocs_get_page`, `anthropicdocs_search`, `anthropicdocs_get_agent_sdk`, `anthropicdocs_get_prompt_engineering` | [platform.claude.com/docs](https://platform.claude.com/docs) |
| **Backstage Docs** | `backstagedocs_list_sections`, `backstagedocs_get_page`, `backstagedocs_search`, `backstagedocs_get_catalog`, `backstagedocs_get_software_templates`, `backstagedocs_get_plugins`, `backstagedocs_get_api_reference` | [backstage/backstage](https://github.com/backstage/backstage) |

**Total: 46 tools**

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

Copy the skill file to your OpenClaw skills directory:

```bash
cp configs/openclaw-skill.md ~/.openclaw/skills/mcp-ecosystem/SKILL.md
```

## Commands

| Command | Description |
|---------|-------------|
| `make up` | Build and start the container |
| `make down` | Stop the container |
| `make logs` | Tail container logs |
| `make status` | Show container status |
| `make rebuild` | Force rebuild and restart |
| `make clean` | Remove container, volumes, and images |
| `make health` | Check server health endpoint |
| `make test-tool` | Quick test that the MCP protocol responds |

## Architecture

```
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
│  │           Tool Modules              │    │
│  │  spec-kit │ anthropics │ awesome    │    │
│  │  agent-fw │ gh-aw │ agents-md      │    │
│  │  github-copilot-docs │ backstage-docs       │    │
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
|----------|---------|-------------|
| `GH_TOKEN` | *(empty)* | GitHub token — increases API rate limit from 60 to 5000 req/h |
| `CACHE_TTL_MS` | `3600000` | Cache TTL in milliseconds (default: 1 hour) |
| `PORT` | `3100` | HTTP server port |
| `CACHE_DIR` | `/app/cache` | Cache directory (Docker volume mount) |
