---
title: "Open Horizons · Documentation Style Guide"
description: "Editorial design, color, diagram, and Markdown conventions for enterprise-facing Open Horizons documentation."
author: "Open Horizons"
date: "2026-06-18"
version: "1.0.0"
status: "review"
tags: ["documentation", "design-system", "editorial", "azure", "github"]
---

> Editorial design system for enterprise-facing Open Horizons documentation. Use this guide to keep Markdown documents, architecture diagrams, customer review packs, and forked client documentation consistent, professional, and aligned with Microsoft Azure + GitHub presentation standards.

## Change Log

| Version | Date | Author | Changes |
| ------- | ---- | ------ | ------- |
| 1.0.0 | 2026-06-18 | Open Horizons | Initial editorial documentation standard. |

## Table of Contents

- [1. Purpose](#1-purpose)
- [2. Editorial Principles](#2-editorial-principles)
- [3. Color System](#3-color-system)
- [4. Document Structure](#4-document-structure)
- [5. Diagram Standards](#5-diagram-standards)
- [6. Callouts and Tables](#6-callouts-and-tables)
- [7. Enterprise Fork Checklist](#7-enterprise-fork-checklist)
- [References](#references)

## 1. Purpose

Open Horizons documentation is part of the product experience. Enterprise customers should be able to fork the repository, replace organization-specific values, and use the docs directly in technical architecture reviews, onboarding workshops, and day-two operations.

This guide defines the documentation standard for:

- Architecture review packs.
- Administrator, deployment, troubleshooting, and module guides.
- Customer-facing README files.
- Backstage TechDocs content.
- Editable `.drawio` diagrams and exported SVGs.

## 2. Editorial Principles

Documentation must be clear, technical, and presentation-ready.

- **English by default**: customer-facing documentation is written in English unless a customer-specific fork requires another language.
- **One purpose per page**: each document must make its audience and use case obvious.
- **General before detail**: open with context, then walk through decisions, flows, operations, and references.
- **No crowded diagrams**: split diagrams when content grows. Use overview + detail views instead of one unreadable canvas.
- **Versioned artifacts**: source diagrams (`.drawio`) and exported diagrams (`.svg`) must live in a versioned docs asset folder.
- **No fabricated metrics**: external market or KPI claims must cite a credible source or be removed.

## 3. Color System

Use the Open Horizons Microsoft/Azure-aligned palette for containers, labels, connector lines, badges, and documentation accents. Do not recolor official Azure, Microsoft, or GitHub product icons.

| Role | Color | Hex | Use |
| ---- | ----- | --- | --- |
| Microsoft Red | Red | `#F25022` | Security, AI governance, warnings, runtime risk |
| Microsoft Green | Green | `#7FBA00` | Runtime, data, success, healthy state |
| Microsoft Blue | Azure Blue | `#00A4EF` | Azure services, Foundry, telemetry, cloud platform |
| Microsoft Yellow | Yellow | `#FFB900` | Identity, cost, routing, caution, operational gates |
| Primary Blue | Blue | `#0078D4` | Platform, portal, Backstage, navigation, links |
| Sidebar Dark | Dark | `#1B1B1F` | Source control, governance, headers, strong contrast |
| Neutral Gray | Gray | `#5E636B` | Secondary text, captions, labels, footers |

Recommended color strip for hero sections and review packs:

```text
#F25022 · #FFB900 · #7FBA00 · #00A4EF · #5E636B
```

## 4. Document Structure

Every major Markdown document must include:

1. YAML frontmatter with `title`, `description`, `author`, `date`, `version`, `status`, and `tags`.
2. One H1 title.
3. A short blockquote summary that states purpose and audience.
4. Change log table.
5. Table of contents when the document has more than three major sections.
6. Numbered H2 sections for predictable review navigation.
7. A References section with linked sources.

Recommended frontmatter:

```yaml
---
title: "Open Horizons · Document Title"
description: "One-sentence purpose statement."
author: "Open Horizons"
date: "YYYY-MM-DD"
version: "1.0.0"
status: "draft | review | approved | archived"
tags: ["open-horizons", "azure", "github"]
---
```

## 5. Diagram Standards

Architecture diagrams must follow the editorial style used in the architecture review package.

- Use **large canvases** when needed. Do not compress complex architecture into a 16:9 slide if it harms readability.
- Keep **overview diagrams** clean and move implementation flow into **detail diagrams**.
- Use horizontal planes for boundaries such as H1, H2, H3, GitHub, Azure DevOps, Azure runtime, identity, or governance.
- Use white cards with a left accent bar, short titles, and at most three short supporting lines.
- Use official Azure, Microsoft, and GitHub icons only. If a product has no official icon, use a labeled card.
- Keep connectors out of card text. Prefer a dedicated flow-summary lane for complex multi-step flows.
- Store editable `.drawio` and exported `.svg` files together under `docs/assets/architecture/`.

Current architecture package:

| Diagram | Source |
| ------- | ------ |
| Architecture Overview | [architecture-overview.svg](../assets/architecture/architecture-overview.svg) |
| System Context | [system-context.svg](../assets/architecture/system-context.svg) |
| H1 Foundation | [h1-foundation.svg](../assets/architecture/h1-foundation.svg) |
| H1 Network and Security Detail | [h1-network-security-detail.svg](../assets/architecture/h1-network-security-detail.svg) |
| H2 Enhancement | [h2-enhancement.svg](../assets/architecture/h2-enhancement.svg) |
| H2 GitOps and Observability Detail | [h2-gitops-observability-detail.svg](../assets/architecture/h2-gitops-observability-detail.svg) |
| H3 Innovation | [h3-innovation.svg](../assets/architecture/h3-innovation.svg) |
| H3 Agent Flow Detail | [h3-agent-flow-detail.svg](../assets/architecture/h3-agent-flow-detail.svg) |
<!-- markdownlint-disable-next-line MD044 -->
| Hybrid Azure DevOps + GitHub | [hybrid-devops-github.svg](../assets/architecture/hybrid-devops-github.svg) |
| Critical Path Sequence | [sequence-golden-path.svg](../assets/architecture/sequence-golden-path.svg) |

## 6. Callouts and Tables

Use callouts sparingly and keep them enterprise-focused.

Recommended callout labels:

- `Note`: neutral context.
- `Decision`: architecture decision or design rationale.
- `Security`: identity, secret, policy, or network control.
- `Validation`: command or check that confirms readiness.
- `Customer Action`: required action during a client fork or deployment.

Example:

> **Security**
>
> Use Workload Identity for Azure access. Do not store service-principal secrets in repository files, Backstage app config, or Kubernetes manifests.

Tables should be used for structured comparisons, role mappings, decision matrices, and review agendas. Keep table cells concise and avoid multi-paragraph table content.

## 7. Enterprise Fork Checklist

Before presenting a fork to a customer, verify:

- The README and guide titles use the customer-approved product name.
- Domain, GitHub organization, Azure subscription, and environment values are placeholders or customer-specific.
- Architecture diagrams are stored under `docs/assets/architecture/` and render without broken icons.
- `.drawio` sources are committed with the SVG exports.
- MCP configuration is present in `.vscode/mcp.json` when the diagram MCP workflow is needed.
- No generated `output/`, local `.venv`, `.env`, tokens, or tfvars are committed.
- Market or KPI claims include credible references or are removed.

## References

- [Architecture Review Pack](../architecture/ARCHITECTURE_REVIEW.md)
- [Microsoft Azure architecture icons](https://learn.microsoft.com/azure/architecture/icons/)
- [GitHub Octicons](https://primer.style/octicons/)
- [Microsoft Writing Style Guide](https://learn.microsoft.com/style-guide/welcome/)
- [Markdownlint rules](https://github.com/DavidAnson/markdownlint)
