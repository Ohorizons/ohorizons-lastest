---
title: "ADR-0003 · Backstage OSS and ai-chat instead of RHDH and Lightspeed"
description: "Decision record for using Backstage OSS and the Open Horizons ai-chat plugin instead of Red Hat Developer Hub and Lightspeed."
author: "Open Horizons"
date: "2026-06-18"
status: "accepted"
tags: ["adr", "backstage", "ai-chat", "open-source"]
---

# ADR-0003: Backstage OSS and ai-chat instead of RHDH and Lightspeed

- Status: Accepted
- Date: 2026-06-18
- Deciders: Platform architecture

## Context

The sibling 3horizons program is built on Red Hat Developer Hub (RHDH) with the Red Hat Lightspeed chat plugin and Red Hat model-serving. Open Horizons is an Azure plus GitHub accelerator. Porting capability from 3horizons raised the question of whether to bring Red Hat components along or to use the open-source equivalents already present here.

Open Horizons already ships an OSS chat: the `ai-chat` Backstage plugin and the `agent-api` backend, which is more capable than Lightspeed (multi-agent, trajectory logging, cost tracking, MCP tools).

## Decision

Use **Backstage OSS** as the portal and the **ai-chat plugin plus agent-api** as the chat surface. Do not introduce RHDH, the Lightspeed plugin, Red Hat model-serving, or any OpenShift or UBI dependency.

When porting code from 3horizons, strip all Red Hat references: RHDH and Lightspeed become Backstage OSS and ai-chat; OpenShift and ARO become AKS; `oc` becomes `kubectl`; UBI base images become OSS Python base images; the `rhdh` namespace becomes `backstage`.

## Consequences

- The platform stays fully open source and open standard, consistent with the no-lock-in promise.
- The chat capability is preserved and improved relative to Lightspeed.
- Ported services run on standard Kubernetes and standard container base images, deployable on any AKS cluster.
- Any future need for Red Hat-specific features would require a new ADR and would break the open-standard posture.
- The foundry gateway exposes an OpenAI-compatible API so the ai-chat backend talks to Azure OpenAI without Red Hat shims.
