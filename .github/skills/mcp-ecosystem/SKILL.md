---
name: mcp-ecosystem
description: "Provides access to 46 tools from the local MCP ecosystem server to fetch live methodology, templates, and reference data from spec-kit, agent-framework, gh-aw, anthropics-skills, agents-md, awesome-copilot, github-copilot-docs, anthropic-platform-docs, and backstage-docs. USE FOR: spec-driven development, agent framework patterns, agentic workflow patterns, Anthropic skill catalog, AGENTS.md format, awesome-copilot skills/agents/prompts lookup, GitHub Copilot documentation and customization, Anthropic API and Agent SDK docs, prompt engineering best practices, Backstage documentation, Software Catalog, Software Templates, plugin development, Backstage API reference. DO NOT USE FOR: general web search, non-reference queries."
---

# MCP Ecosystem

Access live reference data from 10 open-source projects via a local MCP server running at `http://localhost:3100/mcp`.

## Prerequisites

The Docker container must be running:
```bash
cd mcp-servers && make up
```

Verify: `curl -s http://localhost:3100/health` should return `{"status":"ok"}`.

## Available Tools

### Spec-Kit (github/spec-kit)
| Tool | Description |
|------|-------------|
| `speckit_get_phases` | Development phases and workflow |
| `speckit_get_commands` | Slash commands reference (/speckit.*) |
| `speckit_get_methodology` | Full Spec-Driven Development doc |
| `speckit_get_philosophy` | Core philosophy and goals |
| `speckit_search` | Search README by keyword |

### Anthropics Skills (anthropics/skills)
| Tool | Description |
|------|-------------|
| `anthropics_list_skills` | List all skills in catalog |
| `anthropics_get_skill` | Get a specific skill's SKILL.md |
| `anthropics_get_skill_template` | Get skill creation template |
| `anthropics_search_skills` | Filter skills by name |
| `anthropics_get_spec` | Get Agent Skills specification |

### Awesome Copilot (github/awesome-copilot)
| Tool | Description |
|------|-------------|
| `awesome_list_items` | List skills, agents, or prompts |
| `awesome_get_item` | Get specific item content |
| `awesome_search` | Search across all types |
| `awesome_get_readme` | Get full catalog index |

### Agent Framework (microsoft/agent-framework)
| Tool | Description |
|------|-------------|
| `agentfw_get_patterns` | Architecture highlights and features |
| `agentfw_get_sample` | Browse Python/.NET samples |
| `agentfw_search_docs` | Search documentation |
| `agentfw_get_declarative_agents` | List declarative agent samples |

### GitHub Agentic Workflows (github/gh-aw)
| Tool | Description |
|------|-------------|
| `ghaw_get_workflow_patterns` | Overview and workflow authoring |
| `ghaw_get_security_guidelines` | Guardrails and security model |
| `ghaw_get_contributing` | Development setup guide |
| `ghaw_get_agents_md` | Real-world AGENTS.md example |

### AGENTS.md (agentsmd/agents.md)
| Tool | Description |
|------|-------------|
| `agentsmd_get_format_spec` | The AGENTS.md format specification |
| `agentsmd_get_readme` | Project README with explanation |
| `agentsmd_get_section_templates` | Recommended section templates |

| `claudecode_get_settings` | Settings reference |
| `claudecode_get_page` | Any doc page by slug |

### GitHub Copilot Docs (docs.github.com/en/copilot)
| Tool | Description |
|------|-------------|
| `copilotdocs_list_sections` | List all Copilot documentation sections and pages |
| `copilotdocs_get_page` | Get a specific Copilot docs page by path slug |
| `copilotdocs_search` | Search across all Copilot docs by keyword |
| `copilotdocs_get_customization` | Get Copilot customization docs (instructions, agents, skills, prompts) |
| `copilotdocs_get_extensions` | Get Copilot Extensions / building docs |

### Anthropic Platform Docs (platform.claude.com/docs)
| Tool | Description |
|------|-------------|
| `anthropicdocs_list_sections` | List all 651 Anthropic developer doc pages (API, Agent SDK, models, tools, skills) |
| `anthropicdocs_get_page` | Get a specific Anthropic docs page by slug |
| `anthropicdocs_search` | Search across all Anthropic docs by keyword |
| `anthropicdocs_get_agent_sdk` | Get the full Agent SDK documentation (Python, TS, skills, MCP, hooks, subagents) |
| `anthropicdocs_get_prompt_engineering` | Get prompt engineering best practices and techniques |

### Backstage Docs (backstage/backstage)
| Tool | Description |
|------|-------------|
| `backstagedocs_list_sections` | List all Backstage doc sections/pages with slugs |
| `backstagedocs_get_page` | Get a specific Backstage doc page by path slug |
| `backstagedocs_search` | Search across all Backstage docs by keyword |
| `backstagedocs_get_catalog` | Get Software Catalog docs (entities, YAML, relations) |
| `backstagedocs_get_software_templates` | Get Scaffolder/Templates docs (actions, Golden Paths) |
| `backstagedocs_get_plugins` | Get plugin development docs (create, test, composability) |
| `backstagedocs_get_api_reference` | Get TypeDoc API reference for any @backstage/* package |

## When to Use

- Before creating a new skill → call `anthropics_get_skill_template` or `awesome_list_items`
- Before writing AGENTS.md → call `agentsmd_get_section_templates`
- When planning a project → call `speckit_get_methodology`
- When building an AI agent → call `agentfw_get_patterns`
- When setting up CI/CD automation → call `ghaw_get_workflow_patterns`
- When customizing GitHub Copilot → call `copilotdocs_get_customization`
- When building Copilot Extensions → call `copilotdocs_get_extensions`
- When looking for any Copilot feature docs → call `copilotdocs_search`
- When building with Anthropic API or Agent SDK → call `anthropicdocs_get_agent_sdk`
- When optimizing prompts for Claude → call `anthropicdocs_get_prompt_engineering`
- When looking for any Anthropic feature docs → call `anthropicdocs_search`
- When working with Backstage → call `backstagedocs_search` or `backstagedocs_list_sections`
- When building Backstage plugins → call `backstagedocs_get_plugins`
- When configuring Software Catalog → call `backstagedocs_get_catalog`
- When creating Golden Path templates → call `backstagedocs_get_software_templates`
- When looking up Backstage package APIs → call `backstagedocs_get_api_reference`
