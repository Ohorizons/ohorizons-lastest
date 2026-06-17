---
applyTo: "**/*.mmd,**/*.mermaid"
description: "Mermaid diagram syntax rules for FigJam rendering. Enforces safe style patterns that prevent invisible nodes and broken rendering in FigJam's Mermaid renderer."
---

# Mermaid for FigJam Rules

## Critical Rendering Rules

FigJam's Mermaid renderer has known quirks. These rules prevent invisible nodes, broken styling, and rendering failures.

### Node & Edge Ordering

- Declare ALL nodes and edges FIRST, then style declarations LAST
- Never intersperse `style` between node definitions

### DO

```mermaid
flowchart LR
    A[Plan] --> B[Build]
    B --> C[Test]
    C --> D[Deploy]
    style A stroke:#0078D4,stroke-width:2px,color:#0078D4
    style B stroke:#7FBA00,stroke-width:2px,color:#7FBA00
    style C stroke:#FFB900,stroke-width:2px,color:#FFB900
    style D stroke:#F25022,stroke-width:2px,color:#F25022
```

### DON'T

```mermaid
flowchart LR
    classDef blue fill:#0078D4,color:#fff    %% BREAKS — fill makes nodes invisible
    A[Plan]:::blue --> B[Build]
    style B fill:#7FBA00                      %% BREAKS — fill in flowcharts
```

## Style Rules

- **NEVER** use `classDef` with `fill` property in flowcharts — nodes render invisible in FigJam
- **NEVER** use `fill` in individual `style` declarations for flowchart nodes
- Use `stroke` + `stroke-width` + `color` only for flowchart node styling
- `classDef` with stroke-only (no fill) may work but individual `style` is safer
- Use `rect rgba(R,G,B,0.15)` for color bands in sequence diagrams — 15% opacity is the sweet spot

## Labels

- Node labels: under 30 characters — use abbreviations for long names
- Edge labels: 1-3 words maximum
- Use `[ ]` for rectangular nodes (default), `([ ])` for stadium/pill, `{ }` for diamond/decision
- Avoid special characters in labels: no quotes, no backticks, no HTML entities

## Color Palette

Use only Microsoft brand colors — maximum 5 per diagram:

| Color | Hex | Use For |
|-------|-----|--------|
| Primary Blue | `#0078D4` | Primary actions, headers |
| Yellow | `#FFB900` | Planning, warnings |
| Green | `#107C10` | Success, testing |
| Red | `#E81123` | Critical, security |
| Teal | `#008272` | Infrastructure, monitoring |
| Purple | `#5C2D91` | AI, modernization |
| Orange | `#D83B01` | Human actions, manual steps |

## Diagram Type Guidelines

| Type | Direction | Syntax | Best For |
|------|-----------|--------|----------|
| Process flow | `flowchart LR` | Left-to-right | Pipelines, CI/CD, workflows |
| Hierarchy | `flowchart TB` | Top-to-bottom | Org charts, architectures |
| Sequence | `sequenceDiagram` | Top-to-bottom | API calls, handoffs |
| State | `stateDiagram-v2` | Auto | Lifecycle, state machines |

## Limits

- Maximum 15-20 nodes per diagram — split larger diagrams into multiple views
- Maximum 5 colors per diagram to avoid visual noise
- Maximum 3 nesting levels in subgraphs
- If a diagram is too complex for FigJam, consider the HTML Diagrammer agent instead
