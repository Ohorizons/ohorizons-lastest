---
title: "primitive-selection-and-plugin-toggle — Constitution"
feature_id: "001-primitive-selection-and-plugin-toggle"
version: "1.0.0"
date: "2026-05-05"
author: "SDD Pipeline"
status: "Draft"
---
<!-- markdownlint-disable -->
# primitive-selection-and-plugin-toggle — Constitution

> The foundational charter for the **primitive-selection-and-plugin-toggle** project, establishing principles, constraints, and success criteria.

---

## Article 1: Project Identity

- **Name:** primitive-selection-and-plugin-toggle
- **Description:** Foundational charter for primitive-selection-and-plugin-toggle
- **Creator:** SDD Pipeline
- **License:** MIT

---

## Article 2: Principles


- Allowlist by default for safety - clients explicitly opt in to share specific agents/skills/MCP servers/plugins, never blanket include

- Discovery is automatic - new agents/skills/MCP servers under .github or mcp-servers must be auto-discovered without manifest edits

- Filtering happens once at install time, not at runtime - the wizard outputs a filtered surface so generated repos and Backstage runtime see only enabled primitives

- Failures are loud - missing or invalid primitive references in the manifest must error before any write


---

## Article 3: Constraints


- Must not break existing 21/21 wizard tests

- Must remain backward compatible with .openhorizons-selection.yaml (additive changes only)

- Generated repos that already exist must keep working without re-running the wizard

- Bash 3.2 compatibility (no associative arrays, no ${var,,})

- Cannot require new external runtimes (bash + yq + python3 only)


---

## Article 4: Success Criteria

| ID | Criterion | Measure |
|----|-----------|---------|
| SC-001 | Project compiles without errors | `npm run build` exits 0 |
| SC-002 | All requirements traceable | Every REQ has design + task mapping |
| SC-003 | Quality gates pass | Analysis gate returns APPROVE |

---

## Article 5: Scope

### In Scope
- Core project features

### Out of Scope
- Future enhancements not in initial scope

---

## Amendment Log

| # | Date | Author | Rationale | Articles Affected |
|---|------|--------|-----------|-------------------|
| — | — | — | Initial version | All |
