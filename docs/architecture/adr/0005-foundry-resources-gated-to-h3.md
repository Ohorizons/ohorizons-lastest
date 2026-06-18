---
title: "ADR-0005 · Foundry resources gated to the H3 Horizon"
description: "Decision record for gating Foundry runtime resources to H3 Innovation adoption."
author: "Open Horizons"
date: "2026-06-18"
status: "accepted"
tags: ["adr", "h3", "azure-ai-foundry", "finops"]
---

# ADR-0005: Foundry resources gated to the H3 Horizon

- Status: Accepted
- Date: 2026-06-18
- Deciders: Platform architecture, FinOps

## Context

The platform adopts in three Horizons. H1 Foundation and H2 Enhancement deliver the IDP and governance without any agent runtime. The Foundry agents gateway, its Cosmos memory, its Azure AI Foundry model deployments, and the semantic cache are agent-runtime concerns that not every customer adopts on day one, and they carry recurring cost.

If these resources were always provisioned, H1 and H2 customers would pay for an agent runtime they do not yet use.

## Decision

Gate all Foundry runtime resources to **H3 Innovation**. In the sizing profiles, `foundry_agents`, `cosmos_memory`, and the semantic prompt cache default to disabled for Small and are enabled progressively for Medium, Large, and Extra Large. In Terraform, the Cosmos account, database, and container use a `count` guarded by `foundry_agents_config.enabled` and `cosmos_memory.enabled`.

The `gpt-5.1` model deployment is added to the default model list so routing targets and deployed models agree, but the gateway and its stateful backends remain opt-in.

## Consequences

- H1 and H2 deploy and run without provisioning any Foundry runtime resource or incurring its cost.
- Enabling H3 is a configuration change in the sizing profile and tfvars, not a code change.
- Partners customize per client by toggling the H3 flags, consistent with delivering a base that partners extend.
- The architecture, sizing, and Terraform agree on the gate, so there is one place to turn H3 on.
- Capacity and cost for H3 resources must be confirmed against the target subscription before enabling.
