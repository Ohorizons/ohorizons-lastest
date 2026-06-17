---
name: figjam-diagrams
description: >
  Create professional FigJam diagrams using the Figma MCP connector with Mermaid syntax,
  Microsoft brand colors, and proven rendering patterns. Encodes hard-won lessons about
  FigJam's Mermaid renderer quirks and provides Microsoft-branded color palettes.
  USE FOR: create diagram, FigJam diagram, flowchart, sequence diagram, architecture diagram,
  process flow, Mermaid diagram, agent flow, SDLC diagram, deployment diagram, diagrama,
  fluxo, sequência, system interaction, entity relationship.
  DO NOT USE FOR: Figma UI design (not diagrams), presentations (use pptx-creator),
  or pptx-creator), Word documents (use docx-creator).
---

# FigJam Diagrams — Professional Mermaid Diagrams Skill

## Overview

This skill creates professional FigJam diagrams via the `Figma:generate_diagram` tool using Mermaid syntax with Microsoft brand aesthetics. It encodes critical rendering fixes and proven patterns.

## CRITICAL: Rendering Rules

### ⚠️ Rule 1: NEVER Use `classDef` with `fill` for Node Backgrounds

FigJam's Mermaid renderer **does NOT reliably support** `classDef` with `fill:#fff`. Nodes may render completely empty/invisible.

**BAD — May render empty:**
```mermaid
classDef plan fill:#fff,stroke:#FFB900,stroke-width:3px,color:#323130
PO["PO creates Epic"]:::plan
```

**GOOD — Always renders correctly:**
```mermaid
PO["PO creates Epic"]
style PO stroke:#FFB900,stroke-width:3px
```

### ✅ Rule 2: Use Individual `style` Declarations Per Node

Always apply styles individually AFTER all nodes and edges are declared:

```mermaid
flowchart LR
    A["Node A"]
    B["Node B"]
    A --> B

    style A stroke:#0078D4,stroke-width:3px
    style B stroke:#107C10,stroke-width:3px
```

### ✅ Rule 3: `classDef` IS Safe for Sequence Diagrams

Sequence diagrams use `rect rgba()` for color bands — this renders perfectly:

```mermaid
sequenceDiagram
    rect rgba(0,120,212,0.15)
    A->>B: message
    end
```

### ✅ Rule 4: `classDef` with `stroke-only` MAY Work

If you must use classDef, **omit fill entirely** and only set stroke:

```mermaid
classDef blue stroke:#0078D4,stroke-width:3px
```

But prefer individual `style` declarations for maximum reliability.

---

## Microsoft Brand Color Palette

### Primary Colors (use for node strokes)

| Color Name | Hex | RGB | Use For |
|-----------|-----|-----|---------|
| **Blue** | `#0078D4` | `0,120,212` | Code, Development, Primary actions |
| **Yellow/Gold** | `#FFB900` | `255,185,0` | Planning, Warnings, Events |
| **Green** | `#107C10` | `16,124,16` | Testing, Success, Approved |
| **Red** | `#E81123` | `232,17,35` | Security, Critical, Blocked |
| **Teal** | `#008272` | `0,130,114` | Monitoring, Observability, Infrastructure |
| **Purple** | `#5C2D91` | `92,45,145` | Agents, AI, Modernization |
| **Orange** | `#D83B01` | `216,59,1` | Human actions, Manual steps, ChatOps |

### Neutral Colors

| Color Name | Hex | Use For |
|-----------|-----|---------|
| **Text** | `#323130` | Node text color |
| **Light BG** | `#F3F2F1` | Legend backgrounds |
| **Border** | `#D2D0CE` | Legend borders |
| **Subtle** | `#605E5C` | Muted text |

### SDLC Phase Color Mapping

| Phase | Color | Hex | Agents |
|-------|-------|-----|--------|
| **PLAN** | Yellow | `#FFB900` | Aurora |
| **CODE** | Blue | `#0078D4` | Ary, Dev+Copilot |
| **TEST** | Green | `#107C10` | Íris |
| **SECURE** | Red | `#E81123` | Operação |
| **MONITOR** | Teal | `#008272` | Sabiá |
| **MODERNIZE** | Purple | `#5C2D91` | Águia |
| **HUMAN** | Orange | `#D83B01` | Manual merge, Deploy |

---

## Diagram Templates

### Template 1: Flowchart (LR — Left to Right)

```mermaid
flowchart LR
    A["Step 1"]
    B["Step 2"]
    C["Step 3"]
    D["Step 4"]

    A -->|"action"| B
    B -->|"result"| C
    C -->|"output"| D

    style A stroke:#FFB900,stroke-width:3px
    style B stroke:#0078D4,stroke-width:3px
    style C stroke:#107C10,stroke-width:3px
    style D stroke:#008272,stroke-width:3px
```

### Template 2: Flowchart (TB — Top to Bottom)

Use for hierarchy, deployment levels, or organizational structures.

```mermaid
flowchart TB
    TOP["Top Level"]
    MID1["Mid A"]
    MID2["Mid B"]
    BOT["Bottom"]

    TOP --> MID1
    TOP --> MID2
    MID1 --> BOT
    MID2 --> BOT

    style TOP stroke:#E81123,stroke-width:3px
    style MID1 stroke:#0078D4,stroke-width:3px
    style MID2 stroke:#0078D4,stroke-width:3px
    style BOT stroke:#107C10,stroke-width:3px
```

### Template 3: Sequence Diagram with Color Bands

Use `rect rgba(R,G,B,0.15)` for light color bands per phase — 15% opacity is the sweet spot.

```mermaid
sequenceDiagram
    participant A as System A
    participant B as System B
    participant C as System C

    rect rgba(255,185,0,0.15)
    Note over A: Planning Phase
    A->>B: request
    B->>B: process
    B-->>C: handoff
    end

    rect rgba(0,120,212,0.15)
    Note over B: Execution Phase
    C->>C: execute
    C-->>A: result
    end
```

### Template 4: Subgraph-Based (Groups/Categories)

```mermaid
flowchart LR
    subgraph GROUP_A["Category A"]
        A1["Item 1"]
        A2["Item 2"]
    end

    subgraph GROUP_B["Category B"]
        B1["Item 3"]
        B2["Item 4"]
    end

    A1 --> B1
    A2 --> B2

    style A1 stroke:#0078D4,stroke-width:3px
    style A2 stroke:#0078D4,stroke-width:3px
    style B1 stroke:#107C10,stroke-width:3px
    style B2 stroke:#107C10,stroke-width:3px
```

---

## Tool Call Pattern

Always use the `Figma:generate_diagram` tool:

```json
{
  "mermaidSyntax": "",
  "userIntent": ""
}
```

### userIntent Best Practices

Write descriptive intents that help Figma render context:

- ✅ "SDLC end-to-end flow with Microsoft brand colors showing 6 AI agents in the pipeline"
- ✅ "Sequence diagram with transparent color bands per phase at 15% opacity"
- ✅ "Deployment hierarchy showing enterprise vs organization level agents"
- ❌ "diagram"
- ❌ "flow"

---

## Common Diagram Recipes

### Recipe: Agent Individual Flow
For a single agent's internal flow (triggers → processing → outputs):

```
flowchart LR + subgraphs for TRIGGERS, PROCESSING, OUTPUTS
Use agent's assigned color for processing nodes
Use Yellow for trigger nodes
Use Green for output nodes
```

### Recipe: Multi-Agent Handoff
For showing handoffs between agents:

```
sequenceDiagram with rect rgba() bands
Each agent gets its own participant
Color bands match agent colors at 15% opacity
```

### Recipe: Requirements Matrix
For showing RF/RNF (functional/non-functional requirements):

```
flowchart TB with subgraphs
FUNCTIONAL subgraph with Green strokes
NON-FUNCTIONAL subgraph with Blue strokes
DEPENDENCIES shown as dashed arrows
```

### Recipe: Evolution Timeline
For skill → agent → autonomous progression:

```
flowchart LR with 3 phase nodes
Phase 1 (Skill) = Blue
Phase 2 (Agent) = Purple  
Phase 3 (Autonomous) = Teal
Connected with -->|"graduate"| edges
```

---

## Checklist Before Generating

1. ☐ Using individual `style` per node (NOT `classDef` with `fill`)
2. ☐ Microsoft brand colors applied correctly
3. ☐ Node text in double quotes: `["Node Label"]`
4. ☐ Edge labels in double quotes: `-->|"label"|`
5. ☐ Subgraph titles in double quotes: `subgraph ID["Title"]`
6. ☐ No special characters in node IDs (use alphanumeric only)
7. ☐ `userIntent` is descriptive (not generic)
8. ☐ For sequence diagrams: `rect rgba()` with 15% opacity
9. ☐ Styles declared AFTER all nodes and edges
10. ☐ `flowchart` keyword (not `graph`) for best compatibility