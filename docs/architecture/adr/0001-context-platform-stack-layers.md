---
title: "ADR-0001 · Five-layer Context Platform Stack"
description: "Decision record for using the five-layer Context Platform Stack as the authoritative Open Horizons operating model."
author: "Open Horizons"
date: "2026-06-18"
status: "accepted"
tags: ["adr", "architecture", "context-platform-stack"]
---

# ADR-0001: Five-layer Context Platform Stack

- Status: Accepted
- Date: 2026-06-18
- Deciders: Platform architecture

## Context

Agentic systems must answer five distinct questions: where agents run, what they can access, what they can know, what they should optimize for, and how every model call is governed. The marketing deck presents a six-layer model that splits Integration (L5) and Harness (L6) into separate layers. The repository, however, implements the platform as five layers in `CODEMAP.md`, where Integration is folded into Platform Engineering and the Harness is the Agentic Execution layer.

Two framings were in tension: a six-layer teaching model that maps cleanly to distinct on-call owners, and a five-layer operating model that matches the actual code structure.

## Decision

The authoritative architecture uses **five layers**: L1 Cloud Infrastructure, L2 Platform Engineering, L3 Context Engineering, L4 Intent Engineering, and L5 Agentic Execution (the harness). The six-layer model is retained only as an executive teaching aid; it does not drive folder structure, ownership, or deployment.

The harness (the L6 concept in the deck) is implemented as the Agentic Execution layer and realized by the foundry agents gateway. Integration concerns (GitHub, Azure DevOps, ArgoCD, MCP) live inside L2 Platform Engineering.

## Consequences

- The code, `CODEMAP.md`, and this architecture document agree on five layers, removing the contradiction between deck and repository.
- Sales material may still present six layers; any such use must footnote that the operating model is five layers.
- Ownership maps to the five layers; the harness has a single owner (SRE, FinOps, Security) even though it is one layer.
- If Integration grows complex enough to need its own owner and cadence, this ADR can be superseded by promoting Integration to a distinct layer.
