---
title: "Azure Validation Runbook"
description: "Runbook for agent-supervised Azure validation runs that deploy, validate, document, and destroy a full Open Horizons H1/H2/H3 environment."
author: "Open Horizons"
date: "2026-06-18"
version: "1.0.0"
status: "review"
tags: ["azure", "validation", "deployment", "agents", "terraform", "aks", "h3"]
---

# Azure Validation Runbook

> Use this runbook to validate Open Horizons end to end in a real Azure subscription without flooding the agent context with raw logs. Scripts execute deterministic commands; agents read structured artifacts, fix issues, document remediations, and rerun only the failed phase.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-18 | Open Horizons | Initial agent-supervised validation workflow |

## Table of Contents

- [1. Operating Model](#1-operating-model)
- [2. Agent Responsibilities](#2-agent-responsibilities)
- [3. Safety Gates](#3-safety-gates)
- [4. Run Artifacts](#4-run-artifacts)
- [5. Phase Sequence](#5-phase-sequence)
- [6. Error Handling Loop](#6-error-handling-loop)
- [7. Commands](#7-commands)
- [8. Evidence and Documentation](#8-evidence-and-documentation)
- [9. Cleanup](#9-cleanup)
- [References](#references)

## 1. Operating Model

The validation model is **script executor + agent supervisor**.

Scripts run Azure CLI, Terraform, kubectl, curl, and inventory commands. Agents read the generated artifacts and decide what to do next. This reduces token usage, keeps full logs on disk, and makes the run reproducible.

```text
@deploy
  starts phase scripts
  reads status.json and errors.json
  routes failures to specialist agents
  asks before paid or destructive operations
  records final evidence

scripts/azure-validation-run.sh
  runs deterministic commands
  writes logs and JSON artifacts
  never prints secrets intentionally
```

## 2. Agent Responsibilities

| Agent | Responsibility |
|-------|----------------|
| `@deploy` | Overall orchestration, phase gates, approval, retry, final evidence |
| `@azure-portal-deploy` | Subscription, provider registration, quota, region/SKU, Azure inventory |
| `@terraform` | Terraform plan failures, provider issues, module fixes, `tfplan.json` analysis |
| `@security` | OPA/conftest, RBAC, private endpoints, public access, secret handling |
| `@sre` | AKS, pods, events, logs, health checks, observability evidence |
| `@backstage-expert` | Backstage health, GitHub auth, catalog, templates, TechDocs, AI Chat |
| `@github-integration` | GitHub App, OAuth callback, GHCR image availability, GHAS/Actions visibility |

## 3. Safety Gates

### 3.1 Validation Scopes

Use `--validation-scope` to choose how much integration to validate:

| Scope | Purpose | GitHub inputs required? | What is disabled |
|-------|---------|-------------------------|------------------|
| `infra` | Azure-only infrastructure plan/apply: networking, AKS, ACR, Key Vault, PostgreSQL, Azure Managed Redis, observability, Defender, AI Foundry | No | ArgoCD, GitHub runners, Backstage/AI Chat runtime, MCP ecosystem, Foundry agents gateway, Purview, Cost Management, DR |
| `nogithub` | H1/H2/H3 integration without GitHub SSO, GitHub runners, or GitHub catalog/OAuth | No GitHub inputs required, but AKS must already be applied and reachable | GitHub runners and GitHub SSO/catalog integration |
| `platform` | Platform services without GitHub runners or AI runtime | Client GitHub org and admin group required | GitHub runners, AI Chat runtime, MCP ecosystem, Foundry agents gateway |
| `full` | Full H1/H2/H3 integration | Yes: client GitHub org, GitHub token/app data, admin group | Nothing intentionally disabled |

Do not invent GitHub values for `platform` or `full`. Use `infra` when the goal is to validate Azure infrastructure without real GitHub integration. Use `nogithub` only after the `infra` plan has been applied and AKS credentials work, because it includes Kubernetes workloads.

### 3.2 Human Approval Gates

The following phases are non-destructive and can run without approval:

- `preflight`
- `plan`
- `validate-h1`
- `validate-h2`
- `validate-h3`
- `validate-all`
- `inventory`
- `docs`

The following phases require explicit flags:

| Phase | Required Approval |
|-------|-------------------|
| `apply` | `--confirm-apply` |
| `destroy` | `--confirm-destroy --destroy-confirm-text <customer>-<environment>` |
| RG deletion | `--delete-rg` plus destroy confirmation |

Do not run `apply` or `destroy` from specialist agents. `@deploy` owns these gates.

## 4. Run Artifacts

Artifacts are written under `runs/azure-validation/<run-id>/`. The entire `runs/` folder is ignored by Git because it can contain subscription IDs, resource IDs, logs, screenshots, generated tfvars, and other run-specific evidence.

Required top-level artifacts:

| Artifact | Purpose |
|----------|---------|
| `status.json` | Current phase, pass/fail, failed check, owner agent, retry hint |
| `errors.json` | Structured, sanitized error list |
| `summary.md` | Human-readable timeline |
| `fixes.md` | Agent-written root cause, remediation, validation, retry result |
| `tfplan.sanitized.json` | Agent-safe Terraform plan view with secrets and subscription IDs masked |
| `terraform-output.sanitized.json` | Agent-safe Terraform output view with sensitive outputs redacted |

Phase folders:

```text
00-preflight/
01-plan/
02-apply/
03-validate-h1/
04-validate-h2/
05-validate-h3/
07-inventory/
08-docs/
10-destroy/
```

Agents and reviewers should prefer `*.sanitized.json` files when available. Raw plan, output, kubeconfig, and CLI evidence can contain tenant-specific identifiers or secrets and must remain in ignored run folders.

## 5. Phase Sequence

### 5.1 Preflight

Validates Azure context before spending money:

- Azure CLI auth and subscription
- Required provider registration
- Regional VM usage and public IP usage
- AKS version availability (`1.34`)
- Cognitive Services / AI Foundry quota visibility

### 5.2 Plan

Creates a full Terraform plan without applying resources:

- `terraform fmt -recursive -check`
- `terraform init -backend=false`
- `terraform validate`
- `terraform plan`
- `terraform show -json`
- optional `conftest` if installed locally

### 5.3 Apply

Applies the previously generated plan. This phase requires `--confirm-apply`.

### 5.4 Validate H1

Checks foundational infrastructure and AKS:

- AKS credentials
- node readiness
- all namespaces pod snapshot
- cluster events

### 5.5 Validate H2

Checks platform services:

- ArgoCD
- observability
- External Secrets
- Backstage
- `ai-services` namespace if present

### 5.6 Validate H3

Checks AI and agent services:

- Cognitive Services / AI Foundry resources
- AI Search services
- `ai-services` pods and services
- agent API / MCP ecosystem evidence when deployed

### 5.7 Inventory and Docs

Captures Azure inventory and writes a draft resource inventory from live state.

### 5.8 Destroy

Destroys Terraform-managed resources and optionally deletes the empty RG. This phase requires destroy confirmation text matching `<customer>-<environment>`.

## 6. Error Handling Loop

When a phase fails:

1. `@deploy` reads `status.json` and `errors.json`.
2. `@deploy` routes the error to the `owner_agent`.
3. The specialist reads only the referenced log file or relevant JSON artifact.
4. The specialist fixes code/configuration where safe.
5. The specialist records root cause and remediation in `fixes.md`.
6. `@deploy` reruns only the failed phase.
7. The run continues when `status.json` returns `passed`.

Example error payload:

```json
{
  "phase": "plan",
  "status": "failed",
  "failed_check": "terraform_plan",
  "owner_agent": "terraform",
  "safe_to_retry": true
}
```

## 7. Commands

Run preflight:

```bash
scripts/azure-validation-run.sh \
  --phase preflight \
  --customer-name <client-name> \
  --environment prod \
  --location eastus2 \
  --dr-location centralus
```

Run plan:

```bash
scripts/azure-validation-run.sh \
  --phase plan \
  --run-id <run-id> \
  --customer-name <client-name> \
  --environment prod \
  --domain-name <client-domain> \
  --github-org <client-github-org> \
  --validation-scope full \
  --base-tfvars terraform/environments/production.tfvars
```

Run an Azure-only infrastructure plan without GitHub inputs:

```bash
scripts/azure-validation-run.sh \
  --phase plan \
  --run-id <run-id> \
  --customer-name <client-name> \
  --environment prod \
  --domain-name <temporary-azure-dns-zone> \
  --validation-scope infra
```

After `infra` is applied and `validate-h1` passes, plan the no-GitHub integration layer:

```bash
scripts/azure-validation-run.sh \
  --phase plan \
  --run-id <run-id> \
  --customer-name <client-name> \
  --environment prod \
  --domain-name <temporary-azure-dns-zone> \
  --validation-scope nogithub
```

This phase is intentionally blocked until `kubectl cluster-info` succeeds. It prevents Terraform from failing later with a low-level Kubernetes provider REST client error.

Apply after human approval:

```bash
scripts/azure-validation-run.sh \
  --phase apply \
  --run-id <run-id> \
  --confirm-apply
```

Validate all horizons:

```bash
scripts/azure-validation-run.sh --phase validate-all --run-id <run-id>
scripts/azure-validation-run.sh --phase inventory --run-id <run-id>
scripts/azure-validation-run.sh --phase docs --run-id <run-id>
```

Destroy after human approval:

```bash
scripts/azure-validation-run.sh \
  --phase destroy \
  --run-id <run-id> \
  --customer-name <client-name> \
  --environment prod \
  --confirm-destroy \
  --destroy-confirm-text <client-name>-prod
```

## 8. Evidence and Documentation

Do not commit raw run artifacts. After a successful run, sanitize selected evidence and copy it into a versioned example folder such as the [Azure validation example](../examples/azure-validation/).

Recommended evidence:

- resource inventory with resource IDs redacted or intentionally retained for internal evidence
- Terraform output summary with sensitive outputs removed
- `kubectl get pods -A` snapshot
- ArgoCD app health screenshot
- Grafana dashboard screenshot
- Backstage portal screenshot
- AI Foundry deployment screenshot
- issue/fix log from `fixes.md`

## 9. Cleanup

After `destroy`, verify no resources remain:

```bash
az resource list -g rg-<client-name>-prod -o table
az group show -n rg-<client-name>-prod -o table
```

If the resource group remains empty and you explicitly want it removed:

```bash
az group delete -n rg-<client-name>-prod --yes --no-wait
```

## References

- [Azure Validation Example](../examples/azure-validation/README.md)
- [Environment Sizing & Regions](ENVIRONMENT_SIZING.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Azure Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/)
- [Terraform CLI documentation](https://developer.hashicorp.com/terraform/cli)
