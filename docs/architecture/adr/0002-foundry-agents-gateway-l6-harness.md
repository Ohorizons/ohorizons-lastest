---
title: "ADR-0002 · Foundry agents gateway as the L6 harness service"
description: "Decision record for implementing the Foundry agents harness as a standalone gateway service."
author: "Open Horizons"
date: "2026-06-18"
status: "accepted"
tags: ["adr", "azure-ai-foundry", "agentic-execution", "gateway"]
---

# ADR-0002: Foundry agents gateway as the L6 harness service

- Status: Accepted
- Date: 2026-06-18
- Deciders: Platform architecture

## Context

The platform needs a control point that wraps every model call to enforce identity, budget, caching, tool governance, telemetry, and agent-to-agent routing. Two implementation options existed: keep this logic as in-process middleware inside each agent backend, or extract it into a standalone gateway service.

The in-process approach already partially exists in the agent-api middleware (trajectory and cost tracking). The standalone approach was ported from the sibling 3horizons program, where the gateway runs as a dedicated service in its own namespace.

## Decision

Implement the harness as a **standalone gateway service**, `foundry-agents`, living in the repository under `foundry/` and deployed to the `ai-services` namespace on AKS. The gateway fronts Azure AI Foundry and exposes an OpenAI-compatible API plus per-agent endpoints.

The service composes discrete components behind one entry point: semantic prompt cache, A2A v1.0 router, pre and post tool hooks, 21-field telemetry, and Cosmos enterprise memory.

## Consequences

- The harness scales, is probed, and is audited independently of any single agent backend.
- Network policy can permit the Azure AI Foundry endpoint only from the gateway, making the budget and identity checks unbypassable.
- The gateway is a potential bottleneck and single point of failure, mitigated by horizontal replicas sized per environment and readiness probes.
- The service lives in `foundry/` so all Foundry runtime code is colocated, consistent with the decision that Foundry is an H3 concern.
- Existing in-process trajectory and cost middleware remain for non-Foundry agents; the gateway is the path for Foundry-routed traffic.
