---
title: "Open Horizons · Technical Architecture Review"
description: "Architecture review board meeting pack for Open Horizons, including general and detailed diagrams, flows, decisions, and review questions."
author: "Open Horizons"
date: "2026-06-18"
version: "2.0.0"
status: "review"
tags: ["architecture", "azure", "github", "backstage", "agentic-devops", "technical-review"]
product: "Open Horizons (Agentic DevOps Platform)"
platform: "Microsoft Azure + GitHub · Backstage OSS on AKS"
---

> Technical architecture review package for Open Horizons. This document explains the architecture layers, the integration flows, and the purpose of each diagram in the review set. The diagrams are designed for an architecture-board discussion: broad views first, detailed views next, and a sequence view for the critical path.

## Change Log

| Version | Date | Author | Changes |
| ------- | ---- | ------ | ------- |
| 2.0.0 | 2026-06-18 | Open Horizons | Rebuilt the package around 10 editorial diagrams, added detailed flow explanations, expanded review questions, and clarified validation status. |
| 1.0.0 | 2026-06-18 | Open Horizons | Initial architecture review document. |

## Table of Contents

- [1. Review Goals](#1-review-goals)
- [2. Diagram Set](#2-diagram-set)
- [3. Architecture Model](#3-architecture-model)
- [4. Diagram Walkthrough](#4-diagram-walkthrough)
- [5. Integration Flows](#5-integration-flows)
- [6. Cross-Cutting Architecture](#6-cross-cutting-architecture)
- [7. Non-Functional Review](#7-non-functional-review)
- [8. Architecture Decisions](#8-architecture-decisions)
- [9. Review Agenda](#9-review-agenda)
- [10. Validation Status](#10-validation-status)
- [References](#references)

## 1. Review Goals

This pack supports a technical architecture review for **Open Horizons (Agentic DevOps Platform)**. The objective is to make the system understandable from three perspectives: how the whole platform connects, how each adoption stage works internally, and how critical flows behave across GitHub, Azure DevOps, Backstage, AKS, and Azure AI Foundry.

The diagrams intentionally split the architecture into **general** and **detail** views. General views avoid overcrowding. Detail views explain lower-level integration logic. The sequence diagram captures the critical path from Golden Path scaffolding to deployment and AI response.

## 2. Diagram Set

All diagram sources live in `../../.github/skills/azure-architecture-diagrams/output/`. Each diagram has an editable `.drawio` source and an exported `.svg` for documents and presentations.

| # | Diagram | Type | Purpose | Artifacts |
| - | ------- | ---- | ------- | --------- |
| 1 | Architecture Overview | Executive architecture map | Shows H1, H2, H3, and the operating model at review-board level. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/architecture-overview.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/architecture-overview.svg) |
| 2 | System Context | System boundary | Shows actors, hybrid engineering systems, platform services, AI services, and Azure runtime. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/system-context.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/system-context.svg) |
| 3 | H1 Foundation | Deployment view | Shows Azure Landing Zone services: network, identity, data, AKS, observability, and recovery. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/h1-foundation.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/h1-foundation.svg) |
| 4 | H1 Network and Security Detail | Security and network flow | Explains private connectivity, Workload Identity, secrets, policy, and telemetry. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/h1-network-security-detail.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/h1-network-security-detail.svg) |
| 5 | H2 Enhancement | Platform services view | Shows GitOps, Backstage IDP, Golden Paths, and observability. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/h2-enhancement.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/h2-enhancement.svg) |
| 6 | H2 GitOps and Observability Detail | Delivery and feedback flow | Explains how source changes become deployments and how observability feeds governance. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/h2-gitops-observability-detail.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/h2-gitops-observability-detail.svg) |
| 7 | H3 Innovation | Agentic AI component view | Shows AI plugins, Agent API, context engineering, governance, and Azure AI Foundry. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/h3-innovation.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/h3-innovation.svg) |
| 8 | H3 Agent Flow Detail | Agent request flow | Explains routing, cache, memory, RAG, tools, guardrails, inference, and telemetry. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/h3-agent-flow-detail.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/h3-agent-flow-detail.svg) |
| 9 | Hybrid Azure DevOps + GitHub | Hybrid platform view | Explains coexistence scenarios A/B/C, dual auth, catalog providers, and shared runtime. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/hybrid-devops-github.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/hybrid-devops-github.svg) |
| 10 | Critical Path Sequence | Sequence view | Shows developer self-service from scaffold to deployment and AI response. | [.drawio](../../.github/skills/azure-architecture-diagrams/output/sequence-golden-path.drawio) · [.svg](../../.github/skills/azure-architecture-diagrams/output/sequence-golden-path.svg) |

## 3. Architecture Model

Open Horizons is organized around three adoption stages and five architecture layers.

| Adoption stage | Platform layer coverage | Core capability |
| -------------- | ----------------------- | --------------- |
| **H1 Foundation** | L1 Cloud and Infrastructure | Azure Landing Zone, AKS, hub-spoke network, private endpoints, identity, data, registry, security, observability, and recovery. |
| **H2 Enhancement** | L2 Platform Engineering | Backstage OSS IDP, ArgoCD GitOps, Golden Paths, observability stack, platform governance, and developer self-service. |
| **H3 Innovation** | L3 Context Engineering, L4 Intent Engineering, L5 Agentic Execution | Agent runtime, model routing, MCP tools, shared context store, memory tiers, Azure AI Foundry, RAG, trajectory logging, cost control, and agent identity. |

The architecture review should move from broad to specific:

1. Use **Architecture Overview** to explain the layered platform.
2. Use **System Context** to explain boundaries and actors.
3. Use **H1, H2, and H3 general views** to explain each stage.
4. Use **H1, H2, and H3 detail views** to review integration and risk.
5. Use **Hybrid Azure DevOps + GitHub** to decide the adoption path.
6. Use **Critical Path Sequence** to validate the end-to-end behavior.

## 4. Diagram Walkthrough

### 4.1 Architecture Overview

The overview diagram is the entry point for executives and architects. It separates the platform into H3, H2, H1, and the operating model. It should not be used to debate implementation details. Its purpose is to confirm scope, ownership boundaries, and review order.

Key points to explain:

- H3 depends on H2 and H1, but H3 resources are gated to the Innovation stage.
- H2 is the developer and platform-services layer: Backstage, GitOps, Golden Paths, and observability.
- H1 is the secure Azure runtime and Landing Zone foundation.
- The operating model is not optional: security posture, delivery governance, cost, reliability, documentation, and review artifacts are part of the architecture.

### 4.2 System Context

The system context diagram shows the complete platform boundary. It connects developers, platform engineers, runtime agents, GitHub Enterprise, Azure DevOps, Backstage, ArgoCD, AI services, AKS, identity, data, and telemetry.

Primary flow:

1. A developer initiates work through GitHub, Azure DevOps, Backstage, or GitHub Copilot.
2. Source and CI/CD systems build, test, scan, and publish artifacts.
3. ArgoCD reconciles platform and application workloads to AKS.
4. Backstage exposes self-service and AI experiences.
5. Agent API invokes Azure AI Foundry and uses memory and RAG services.
6. Azure runtime services enforce identity, private data access, and telemetry.

Architectural checks:

- Confirm that there is no public access path to stateful PaaS services.
- Confirm that GitHub and Azure DevOps are both represented as first-class integration systems.
- Confirm that agent telemetry and governance are part of the system boundary, not an afterthought.

### 4.3 H1 Foundation

The H1 Foundation diagram shows the secure Azure Landing Zone. It is the deployment view for infrastructure teams.

Planes:

- **Network edge**: Application Gateway, Azure Firewall, Private Endpoints, and hub-spoke VNet.
- **Security and identity**: Microsoft Entra ID, Key Vault, Managed Identity, and Defender for Cloud.
- **Data and registry**: ACR, PostgreSQL, Storage Account, and Microsoft Purview.
- **AKS workloads**: AKS, GitHub Actions runners, External Secrets, and Policy/OPA.
- **Observability and continuity**: Azure Monitor, Log Analytics, Application Insights, and Recovery Services Vault.

Review focus:

- Validate subnet boundaries and private endpoint strategy.
- Validate Workload Identity and Key Vault access.
- Validate backup, restore, monitoring, and incident visibility.
- Validate that container images are private, signed, scanned, and pulled through approved paths.

### 4.4 H1 Network and Security Detail

The H1 detail diagram expands the private connectivity and identity story. This is the view for security, networking, and platform operations.

Detailed flow:

1. The public edge admits only approved HTTPS requests.
2. Traffic stays inside the hub-spoke network after ingress.
3. Workloads use Workload Identity, not static credentials.
4. External Secrets reads from Key Vault and writes only scoped Kubernetes secrets.
5. Azure Policy and Kubernetes policies block non-compliant resources.
6. Defender and Azure Monitor collect security and operations signals.
7. KQL, alerts, and runbooks support response.

Review focus:

- Confirm Private DNS zone linking for Key Vault, ACR, PostgreSQL, Storage, and AI services.
- Confirm Azure Firewall egress policies for build runners and agent workloads.
- Confirm that Kubernetes NetworkPolicy isolates agent namespaces and MCP/tool traffic.
- Confirm that Key Vault RBAC scopes are narrow and auditable.

### 4.5 H2 Enhancement

The H2 Enhancement diagram explains platform services. It is the main view for platform engineering, developer experience, and SRE discussion.

Planes:

- **Source and CI/CD**: GitHub repositories, GitHub Actions, GHCR, and GitHub Advanced Security.
- **GitOps delivery**: ArgoCD, sync waves, drift detection, and deployment health.
- **Developer portal**: Backstage IDP, Golden Paths, TechDocs, and the catalog database.
- **Observability**: Prometheus, Grafana, Loki, and Alertmanager.
- **Consumer workflows**: developers, platform engineers, and SRE workflows.

Review focus:

- Confirm repository and image promotion model.
- Confirm how Golden Paths create SDD artifacts and catalog metadata.
- Confirm how drift, health, and alerts are surfaced to operators.
- Confirm Backstage persistence and secret handling.

### 4.6 H2 GitOps and Observability Detail

The H2 detail diagram explains the delivery and feedback loop.

Detailed flow:

1. A source change updates code, manifest, chart, plugin, or template.
2. CI validates the change with build, test, and security scanning.
3. The desired state records the immutable image digest.
4. ArgoCD sync waves apply resources in the correct order.
5. Kubernetes health and probes validate rollout quality.
6. Prometheus, Loki, Grafana, and Alertmanager update operations visibility.
7. Drift, cost, or risk produces a concrete review action.

Review focus:

- Confirm failure behavior for sync waves and rollback.
- Confirm dashboard ownership and alert routing.
- Confirm how platform teams review drift and cost.
- Confirm that developers see enough status in Backstage without needing cluster access.

### 4.7 H3 Innovation

The H3 Innovation diagram explains the agentic AI layer. It is the main view for AI, platform, security, and operations stakeholders.

Planes:

- **Portal experience**: AI Chat, AI Impact, and GitHub Copilot.
- **Agent runtime**: Agent API, model router, orchestrator agents, and MCP servers.
- **Context and memory**: Shared Context Store, memory tiers, Azure Cache for Redis, and skills/agents.
- **Governance**: trajectory logging, cost tracking, agent identity, and Content Safety.
- **Azure AI Foundry**: Azure OpenAI, Foundry agent service, Azure AI Search, and Application Insights.

Review focus:

- Confirm model routing rules by task class and SDLC phase.
- Confirm memory boundaries: short-term session state vs long-term durable memory.
- Confirm MCP tool curation and least-privilege tool access.
- Confirm trajectory, cost, safety, and evaluation requirements before H3 rollout.

### 4.8 H3 Agent Flow Detail

The H3 detail diagram explains a single agent request. It separates request control, context control, tool control, model control, and observability control.

Detailed flow:

1. Agent API validates request and identity.
2. Model router classifies the task and selects a model tier.
3. Redis checks semantic cache and short-term state.
4. Azure AI Search and MCP tools curate bounded context.
5. Safety and scope policies run before tool or model execution.
6. Azure AI Foundry and Azure OpenAI complete inference.
7. Trajectory, cost, and OpenTelemetry are persisted.
8. A grounded answer returns to the portal.

Review focus:

- Confirm token budget and context window policy.
- Confirm cache hit behavior and cache invalidation rules.
- Confirm tool selection boundaries and namespace conventions.
- Confirm eval, safety, and regression gates for agent changes.

### 4.9 Hybrid Azure DevOps + GitHub

The hybrid diagram explains coexistence across GitHub and Azure DevOps.

Scenarios:

| Scenario | Source | CI/CD | Work tracking | Portal behavior |
| -------- | ------ | ----- | ------------- | --------------- |
| **A** | GitHub Repos | Azure Pipelines | Azure Boards | Catalog shows GitHub code and ADO delivery metadata. |
| **B** | Azure Repos | Azure Pipelines | Azure Boards | Catalog uses the Azure DevOps provider and GitHub Copilot Standalone is independent of GitHub repos. |
| **C** | GitHub Repos | GitHub Actions | GitHub Issues or external tracker | Catalog uses GitHub provider, GHAS, Actions, GHCR, and ArgoCD. |

Review focus:

- Confirm the default migration scenario per team.
- Confirm GitHub OAuth and Microsoft Entra ID sign-in requirements.
- Confirm whether images land in GHCR, ACR, or both.
- Confirm how catalog ownership and work tracking metadata are normalized.

### 4.10 Critical Path Sequence

The sequence diagram shows the operational path that matters most: a developer scaffolds a service, CI/CD validates it, ArgoCD deploys it, and the agent responds to an AI request.

Message sequence:

1. Developer opens a Golden Path.
2. Backstage scaffolds a repository.
3. GitHub or Azure DevOps triggers CI/CD.
4. CI/CD runs tests and security scans.
5. The image and manifest are updated.
6. ArgoCD syncs to AKS.
7. Runtime status returns to Backstage.
8. Developer asks AI Chat.
9. Agent API routes and retrieves context.
10. Azure AI Foundry performs model inference.
11. Response and telemetry return to Agent API.
12. Answer and impact insight return to the developer.

Review focus:

- Confirm which steps are synchronous vs asynchronous.
- Confirm retry and rollback behavior for CI/CD and GitOps.
- Confirm what trace id follows the flow across systems.
- Confirm that AI response telemetry can be correlated to the developer request.

## 5. Integration Flows

### 5.1 Delivery Flow

The delivery flow begins in source control and ends in AKS. GitHub Actions or Azure Pipelines builds and scans the workload. The desired state is updated through manifests or Helm values. ArgoCD reconciles the desired state using sync waves and health checks. Runtime status and drift are returned to operators through Backstage, Grafana, and alerts.

### 5.2 Identity and Secret Flow

Workloads use Microsoft Entra Workload Identity. A Kubernetes service account is federated to a Managed Identity. The workload obtains a scoped token from Entra ID and uses it to reach Key Vault or other Azure services. External Secrets syncs only selected values into Kubernetes. Static service-principal secrets are not part of the target architecture.

### 5.3 Agent Request Flow

The Agent API validates identity and request shape, routes the task, checks cache and memory, retrieves context, applies guardrails, invokes Foundry, records trajectory and cost, and returns a grounded response. Tool execution is mediated through curated MCP servers and managed identity.

### 5.4 Hybrid Catalog Flow

The Backstage catalog reads metadata from GitHub and Azure DevOps providers. Each entity can include GitHub annotations, Azure DevOps annotations, ArgoCD annotations, and Kubernetes annotations. The portal shows a unified view even when source control, CI/CD, and work tracking are split across systems.

## 6. Cross-Cutting Architecture

### 6.1 Security

- Private endpoints protect data services and platform dependencies.
- Azure Firewall controls egress.
- Application Gateway with WAF controls ingress.
- Microsoft Entra ID and Workload Identity remove the need for long-lived credentials.
- Defender for Cloud, Azure Policy, and Kubernetes policy provide preventive and detective controls.

### 6.2 Observability

- Prometheus, Grafana, Loki, and Alertmanager provide the platform operations view.
- Azure Monitor, Log Analytics, and Application Insights provide cloud and application telemetry.
- Agent telemetry includes trajectories, model calls, tool calls, cost, latency, and quality signals.

### 6.3 Governance

- SDD artifacts capture intent before implementation.
- ADRs capture design decisions.
- ArgoCD captures desired state and drift.
- Trajectory logging captures agent decisions and tool outcomes.
- Cost tracking captures per-agent and per-route usage.

### 6.4 Data and Context

- PostgreSQL stores Backstage catalog and platform state.
- Azure Cache for Redis supports semantic cache, vector memory, and session memory.
- Azure AI Search supports RAG retrieval.
- Purview provides data classification and governance scope.

## 7. Non-Functional Review

| Concern | Architecture treatment | Review question |
| ------- | ---------------------- | --------------- |
| Availability | AKS node pools, ArgoCD self-heal, health probes, Recovery Services Vault | What SLO applies per H1, H2, and H3 service? |
| Scalability | Cluster autoscaler, separated user node pools, model routing, cache reuse | Which workloads need independent scale boundaries? |
| Security | Private networking, Workload Identity, Key Vault, Defender, Policy | Are all public data paths eliminated? |
| Reliability | Sync waves, health checks, rollback, telemetry, runbooks | What is the rollback strategy for each critical service? |
| Cost | Model routing, Redis cache, per-agent budgets, Azure Monitor cost reporting | What budgets and alerts are approved? |
| Compliance | ADRs, SDD artifacts, Purview, policy gates, trajectory audit | What evidence must be retained for audit? |

## 8. Architecture Decisions

Existing ADRs in [`adr/`](adr/) support this review:

- [0001 · Context Platform Stack layers](adr/0001-context-platform-stack-layers.md)
- [0002 · Foundry agents gateway L6 harness](adr/0002-foundry-agents-gateway-l6-harness.md)
- [0003 · Backstage OSS, not RHDH](adr/0003-backstage-oss-not-rhdh.md)
- [0004 · Memory and cache backends](adr/0004-memory-and-cache-backends.md)
- [0005 · Foundry resources gated to H3](adr/0005-foundry-resources-gated-to-h3.md)

Decisions to confirm during the review:

- H3 enablement criteria and rollout order.
- Hybrid scenario default per business unit.
- Private endpoint and DNS topology per environment.
- Model routing policy and agent budget thresholds.
- Observability retention and incident-response ownership.

## 9. Review Agenda

Suggested 75-minute technical review agenda:

| Time | Topic | Diagram |
| ---- | ----- | ------- |
| 5 min | Scope, goals, and quality bar | Architecture Overview |
| 10 min | System boundary and actors | System Context |
| 12 min | H1 Landing Zone and security | H1 Foundation + H1 Network Detail |
| 12 min | H2 platform services and operations | H2 Enhancement + H2 Detail |
| 15 min | H3 agentic AI runtime and governance | H3 Innovation + H3 Agent Detail |
| 10 min | Hybrid Azure DevOps + GitHub adoption | Hybrid Diagram |
| 8 min | End-to-end critical path | Sequence Diagram |
| 3 min | Open decisions and next actions | ADRs and review questions |

## 10. Validation Status

The generated diagram set was validated with the local draw.io XML validator:

```bash
python3 .github/skills/azure-architecture-diagrams/scripts/validate_drawio.py \
  .github/skills/azure-architecture-diagrams/output/<diagram>.drawio \
  --require-icon --require-edge
```

All 10 `.drawio` files pass XML, icon, and connector checks. All 10 SVG files were rendered to PNG with `rsvg-convert` for visual QA. The draw.io MCP server is configured in `.vscode/mcp.json`, and the MCP SDK imports successfully from the skill-local virtual environment.

## References

- [Open Horizons architecture guide](OpenHorizons_Architecture.md)
- [ADR index](adr/README.md)
- [Microsoft Azure architecture icons](https://learn.microsoft.com/azure/architecture/icons/)
- [GitHub Octicons](https://primer.style/octicons/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Azure AI Foundry documentation](https://learn.microsoft.com/azure/ai-foundry/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/)
