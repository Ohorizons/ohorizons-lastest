---
name: sdd-spec-engineer
description: 'Spec-Driven Development orchestrator that turns natural language into production-grade specs through discovery, EARS requirements, Mermaid architecture, sequenced task plans with [P] markers, pre-implementation gates, traceability matrices, and coding-agent handoff. USE FOR: SDD, ''spec this'', ''plan this'', implementation plan, constitution, quality gate, spec sync, bugfix spec, or Kiro-like workflows that need SPECIFICATION/DESIGN/TASKS artifacts. DO NOT USE FOR: standalone FRD/NFRD authoring before sdd_init (use requirements-engineer), INVEST user story decomposition or GitHub Issue creation (use story-planning), Foundry runtime/provisioning detail (use ai-foundry-operations or foundry-agent-blueprint), or general agentic architecture trade-off decisions (use agentic-architecture-patterns).'
---

# SDD Spec Engineer

This package provides a complete Spec-Driven Development workflow for GitHub Copilot.

## Available Agents (GitHub Copilot)

| Agent | Purpose |
|-------|---------|
| **Spec Engineer** | Full pipeline orchestrator, the only agent developers need |
| **Design Architect** | Architecture and Mermaid diagrams |
| **Task Planner** | Task breakdown with [P] markers |
| **Spec Reviewer** | Quality gate and traceability matrix |

## Suggested prompt file commands

| Command | Purpose |
|---------|---------|
| `/sdd:spec` | Full pipeline: scan → discover → spec → clarify → design → tasks → analyze |
| `/sdd:design` | Generate DESIGN.md from existing spec |
| `/sdd:tasks` | Generate TASKS.md from existing design |
| `/sdd:analyze` | Run quality gate on existing specs |
| `/sdd:bugfix` | Generate bugfix specification |

## Key Features

- Interactive discovery with smart questions before generating
- Requirements-First AND Design-First workflows
- EARS notation for unambiguous acceptance criteria
- Mandatory Mermaid diagrams in architecture
- Pre-implementation gates (constitution enforcement)
- [P] parallel task markers for team coordination
- /clarify phase for spec disambiguation
- Automatic quality gate with traceability matrix
- Sequential feature numbering (001-, 002-)
- Implementation handoff to GitHub Copilot agent mode or terminal agents
- 6 pre-built hook templates

## Reference Files

Read `references/ears-notation.md` before generating specifications.
Read `references/spec-templates.md` for artifact templates.
