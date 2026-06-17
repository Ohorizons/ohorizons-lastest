---
title: "primitive-selection-and-plugin-toggle - Specification"
feature_id: "002-primitive-selection-and-plugin-toggle"
version: "1.0.0"
date: "2026-05-05"
author: "Platform Engineering"
status: "Approved"
---

# primitive-selection-and-plugin-toggle - Specification

## Summary

Extends the install wizard manifest with selectable lists for individual chat agents, skills, prompts, and MCP servers, plus an effective toggle for the Backstage AI Chat plugin in `app-config.production.yaml`. Empty lists keep the current behavior of including everything; populated lists turn the wizard into an allowlist enforcer that filters what the platform exposes.

## Stakeholders

- Platform engineers and SREs running `scripts/install-wizard.sh`.
- CI pipelines invoking the wizard with `--auto`.
- Generated repositories that copy `.github/agents` and `.github/skills` via Golden Path `fetch:plain` steps.

## Requirements (EARS)

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| REQ-AGENTS-001 | The install wizard manifest SHALL allow a list of selected chat agent ids. | Manifest accepts `agents:` array. Empty default keeps all 19 agents. Wizard exits 2 when ids are missing on disk. Selected agents are reflected under `golden-paths/common/agents/.github/agents/` after render. |
| REQ-SKILLS-001 | The install wizard manifest SHALL allow a list of selected skill ids. | `skills:` array. Empty default keeps all 28. Unknown ids exit 2. Selected skills end up under `golden-paths/common/agents/.github/skills/`. |
| REQ-PROMPTS-001 | The install wizard manifest SHALL allow a list of selected prompts. | `prompts:` array. Empty default keeps all 16 prompts. Unknown ids exit 2. |
| REQ-MCP-001 | The install wizard manifest SHALL allow a list of selected MCP servers. | `mcp_servers:` array. Empty default keeps all 12. `render-manifests.sh` emits a `MCP_SERVERS_ENABLED` ConfigMap when the ecosystem is enabled. Unknown ids exit 2. |
| REQ-PLUGIN-001 | WHEN `enable_ai_chat_plugin` is set to `false`, THE wizard SHALL omit the AI Chat plugin from the generated `app-config.production.yaml`. | Sections registering `plugin-ai-chat` (proxy, integrations) are stripped. `.bak.<timestamp>` backup created before rewrite. Backend `index.ts` is left untouched. |
| REQ-SCHEMA-002 | The selection schema SHALL describe agents, skills, prompts, and mcp_servers fields with pattern validation. | `openhorizons-selection.schema.json` adds the four arrays as `uniqueItems` of kebab-case strings. Manifests without the fields remain valid. |
| REQ-DEPS-001 | Wizard SHALL keep RULE-001..RULE-004 valid when primitive lists are populated. | `enable_ai_chat_plugin=true` plus an empty `agents` list still requires `enable_agent_api=true`. |
| REQ-TESTS-002 | The wizard test suite SHALL include 5 tests proving allowlist semantics and AI Chat plugin filtering. | tests/wizard/run.sh appends Tests 13-17. All 26 tests pass on macOS bash 3.2 and on the CI workflow. |
| REQ-DOCS-002 | Documentation SHALL describe the new lists and defaults in MASTER_INSTALLATION.md. | Selection Matrix updated with four new rows. Empty list semantics explained. |

## Out of Scope

- Refactoring Golden Path templates per agent or per skill.
- Frontend changes to Backstage to hide AI Chat menu items.
- Per-MCP-server runtime control (only build-time filter via ConfigMap).

## Dependencies

- Inherits the schema validator and dependency rules from feature 001.
- Reuses `golden-paths/common/agents/` package referenced by 32 templates' `fetch:plain` step.

## Open Questions

None at the time of writing.
