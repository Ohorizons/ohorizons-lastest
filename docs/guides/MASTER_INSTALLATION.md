---
title: "Open Horizons - Master Installation Guide"
description: "Complete installation guide for the Agentic DevOps Platform accelerator: every layer, every functionality, end-to-end. The single source of truth when adopting Open Horizons in a client environment."
author: "Platform Engineering"
date: "2026-05-05"
version: "1.0.0"
status: "approved"
tags: ["installation", "accelerator", "master-guide", "platform-engineering", "agentic-devops"]
---

# Open Horizons - Master Installation Guide

This is the master guide for installing the Open Horizons Agentic DevOps Platform accelerator end to end. It is the single document a client should read first. It covers every layer, every shipping feature, the order of operations, and where to find the per-task deep dives.

> If you only need the deploy commands, jump straight to [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).
> If you only need to understand the wizard developers will use, see [WIZARD_GUIDE.md](WIZARD_GUIDE.md).
> This guide explains how the two fit together and lists every functional capability the client gets.

## Table of Contents

- [What You Are Installing](#what-you-are-installing)
- [The Five Layers and What Ships in Each](#the-five-layers-and-what-ships-in-each)
- [Inventory at a Glance](#inventory-at-a-glance)
- [Reference Architecture](#reference-architecture)
- [Installation Roadmap](#installation-roadmap)
- [Stage 0 - Prerequisites](#stage-0---prerequisites)
- [Stage 1 - Receive the Template](#stage-1---receive-the-template)
- [Stage 2 - Provision Infrastructure (L1)](#stage-2---provision-infrastructure-l1)
- [Stage 3 - Deploy the Platform (L2)](#stage-3---deploy-the-platform-l2)
- [Stage 4 - Wire Context (L3)](#stage-4---wire-context-l3)
- [Stage 5 - Activate Intent (L4)](#stage-5---activate-intent-l4)
- [Stage 6 - Run Agentic Execution (L5)](#stage-6---run-agentic-execution-l5)
- [Stage 7 - Configure Identity Federation](#stage-7---configure-identity-federation)
- [Stage 8 - Validate End to End](#stage-8---validate-end-to-end)
- [Day-Two Operations](#day-two-operations)
- [Reverse and Reset](#reverse-and-reset)
- [References](#references)

## What You Are Installing

Open Horizons is an opinionated, open-source accelerator for Platform Engineering teams that need to deliver AI-native developer experiences on Azure with GitHub. It implements the **Context Platform Stack** (5 layers, grounded in 25+ peer-reviewed papers) as a deployable reference, not as theory.

The accelerator covers:

- The **Internal Developer Platform (IDP)** that developers use day to day - Backstage on AKS with Software Catalog, TechDocs, Software Templates, and DORA / Cost dashboards.
- The **Agent IDP** - 4 agent runtime APIs, trajectory and cost middleware, agent identity, and a Backstage AI Chat plugin.
- The **scaffolder** that creates new repositories on demand via wizard - 34 Golden Paths, all aligned to the same agents, TechDocs, CI/CD, and an opt-in Azure baseline.
- The **AI primitives** that make Copilot Chat productive in this codebase - 19 chat agents, 16 prompts, 8 instructions, 27 skills, and 12 MCP server tools.
- The **infrastructure** to run all of the above - 16 Terraform modules covering AKS, networking, registries, databases, secrets, security, observability, AI Foundry, GitHub runners, ArgoCD, Backstage, Defender, Purview, disaster recovery, cost management, and naming.
- The **governance and policy** stack - OPA/Gatekeeper rules for Kubernetes and Terraform, CONSTITUTION + SPECIFICATION + IMPLEMENTATION_PLAN templates, scope-guard hooks, and intent-drift measurement.
- The **observability** stack - Prometheus rules, Grafana dashboards, Alertmanager wiring, plus per-agent trajectory and cost telemetry.

## The Five Layers and What Ships in Each

| Layer | Concern | What Ships |
|-------|---------|------------|
| L1 - Cloud Infrastructure | Compute and security baseline | 16 Terraform modules in [`terraform/modules/`](../../terraform/modules/) covering AKS, networking, ACR, databases (Postgres + Redis), Key Vault and external secrets, Defender, Purview, observability, cost management, GitHub runners, AI Foundry, ArgoCD, Backstage, naming, disaster recovery, security baseline. Environment tfvars in [`terraform/environments/`](../../terraform/environments/). |
| L2 - Platform Engineering | Golden paths, GitOps, governance | Backstage portal in [`backstage/`](../../backstage/) (catalog, TechDocs, software templates, AI Chat plugin), 34 Golden Paths in [`golden-paths/`](../../golden-paths/), ArgoCD app-of-apps in [`argocd/`](../../argocd/), 7 Kubernetes OPA policies and 1 Terraform OPA policy in [`policies/`](../../policies/), 5 Grafana dashboards in [`grafana/dashboards/`](../../grafana/dashboards/), Prometheus recording and alerting rules in [`prometheus/`](../../prometheus/), 9 GitHub Actions workflows in [`.github/workflows/`](../../.github/workflows/), 22 automation scripts in [`scripts/`](../../scripts/). |
| L3 - Context Engineering | Agent context and tools | 27 skills in [`.github/skills/`](../../.github/skills/), 12 MCP servers in [`mcp-servers/src/tools/`](../../mcp-servers/src/tools/), three-tier memory architecture in [`backstage/server/agent-api/memory/`](../../backstage/server/agent-api/memory/), Shared Context Store (CA-MCP), CODEMAP-based program skeletons. |
| L4 - Intent Engineering | Specifications and governance | CONSTITUTION, SPECIFICATION, IMPLEMENTATION_PLAN templates in [`golden-paths/common/templates/`](../../golden-paths/common/templates/), Specky scope-guard hooks in [`.github/hooks/specky/`](../../.github/hooks/specky/), [`.github/model-routing.yaml`](../../.github/model-routing.yaml), drift telemetry via [`scripts/measure-intent-drift.sh`](../../scripts/measure-intent-drift.sh). |
| L5 - Agentic Execution | Runtime agents and identity | 19 Copilot Chat agents in [`.github/agents/`](../../.github/agents/), 16 prompts in [`.github/prompts/`](../../.github/prompts/), 8 instructions in [`.github/instructions/`](../../.github/instructions/), 4 runtime agent APIs in [`backstage/server/`](../../backstage/server/) (`agent-api`, `agent-api-impact`, `agent-api-maf`, `agent-api-sk`), trajectory and cost middleware, agent identity in [`backstage/k8s/agent-identity.yaml`](../../backstage/k8s/agent-identity.yaml). |

## Inventory at a Glance

| Capability | Count |
|-----------|------:|
| Terraform modules | 16 |
| Kubernetes manifests for Backstage stack | 11 |
| Backstage plugins (custom) | 1 (AI Chat) |
| Runtime agent APIs | 4 |
| Golden Path templates | 34 |
| Copilot Chat agents | 19 |
| Prompts | 16 |
| Instructions | 8 |
| Skills | 27 |
| MCP servers | 12 |
| GitHub Actions workflows | 9 |
| ArgoCD applications | 2 |
| OPA policies (Kubernetes) | 7 |
| OPA policies (Terraform) | 1 |
| Grafana dashboards | 5 |
| Prometheus rule sets | 2 |
| Automation scripts | 22 |
| Guides under `docs/guides/` | 10 |
| Context Platform Stack chapters and playbooks | 11 |
| Runbooks | 2 |
| Total Markdown docs | 231 |

## Reference Architecture

```text
+------------------------------------------------------------+
|                  Developers / Tech Leads                   |
+------------------------------------------------------------+
                          |
                          v
+------------------------------------------------------------+
|                    Backstage Portal (L2)                   |
|  Software Catalog | TechDocs | Wizard | AI Chat Plugin     |
+------------------------------------------------------------+
        |                    |                    |
        v                    v                    v
+--------------+    +--------------+    +-----------------+
| Scaffolder   |    | Agent APIs   |    | DORA + Cost     |
| 34 Golden    |    | (4 runtimes) |    | Dashboards      |
| Paths (L2)   |    | (L5)         |    | (L2)            |
+------+-------+    +------+-------+    +-----------------+
       |                   |
       v                   v
+--------------+    +-----------------+
| GitHub repos |    | MCP servers (12)|
| + agents +   |    | (L3 context)    |
| TechDocs +   |    +-----------------+
| optional     |
| Azure infra  |
+------+-------+
       |
       v
+------------------------------------------------------------+
|                Azure (L1) provisioned by                   |
|  Terraform: AKS, ACR, KV, Postgres, Redis, AI Foundry,     |
|  Defender, Log Analytics, App Insights, Managed Grafana.   |
+------------------------------------------------------------+
```

## Installation Roadmap

```text
[0] Prerequisites
     |
     v
[1] Receive the template (fork, branding, branches)
     |
     v
[1.5] Run the install wizard (component selection)
     |
     v
[2] Provision infrastructure (Terraform - 16 modules)
     |
     v
[3] Deploy the platform (Backstage, ArgoCD, Observability, Policies)
     |
     v
[4] Wire context (MCP servers, skills, memory)
     |
     v
[5] Activate intent (CONSTITUTION, SPECIFICATION, drift telemetry)
     |
     v
[6] Run agentic execution (chat agents, runtime APIs, agent identity)
     |
     v
[7] Configure identity federation (OIDC for platform and generated repos)
     |
     v
[8] Validate end to end (templates, docs, agents, observability)
```

Most stages have automation. The roadmap above maps to actual scripts and guides under [`scripts/`](../../scripts/) and [`docs/guides/`](.).

## Selection Matrix (Install Wizard)

The install wizard at [`scripts/install-wizard.sh`](../../scripts/install-wizard.sh) is the supported way to choose what gets installed. It runs interactively or non-interactively (CI/CD) and persists every selection to a single manifest at the repo root.

### Inputs

| Selection | Choices | Default | Where it goes |
|-----------|---------|---------|---------------|
| Horizon | `h1` / `h2` / `h3` / `all` | `all` | `--horizon` flag of `scripts/deploy-full.sh` |
| Deployment mode | `express` / `standard` / `enterprise` | `express` | `deployment_mode` in tfvars |
| Terraform modules (11) | individual booleans (`enable_container_registry`, `enable_databases`, `enable_defender`, `enable_purview`, `enable_argocd`, `enable_external_secrets`, `enable_observability`, `enable_github_runners`, `enable_cost_management`, `enable_ai_foundry`, `enable_disaster_recovery`) | matches existing `terraform/terraform.tfvars.example` | `terraform/environments/<env>.tfvars` |
| Backstage components (6) | `enable_ai_chat_plugin`, `enable_agent_api`, `enable_agent_api_impact`, `enable_agent_api_maf`, `enable_agent_api_sk`, `enable_mcp_ecosystem` | AI Chat plus its agent-api on, others off | `terraform/environments/<env>.tfvars` |
| Golden Paths (34) | any subset of `<horizon>/<template>` ids | all 34 | `catalog.locations` of `backstage/app-config.production.yaml` |
| Chat agents (19) | optional allowlist of agent ids in `agents:` | empty list = include all | `golden-paths/common/agents/.rendered/.github/agents/` |
| Skills (28) | optional allowlist of skill folder names in `skills:` | empty list = include all | `golden-paths/common/agents/.rendered/.github/skills/` |
| Prompts (16) | optional allowlist of prompt ids in `prompts:` | empty list = include all | `golden-paths/common/agents/.rendered/.github/prompts/` |
| MCP servers (12) | optional allowlist of MCP ids in `mcp_servers:` | empty list = include all | `golden-paths/common/agents/.rendered/mcp-servers/enabled.txt` |

### Outputs

| Artifact | Path | Behavior |
|----------|------|----------|
| Manifest | `.openhorizons-selection.yaml` | Single source of truth. Atomic writes, `.bak` backup on every change. |
| Audit log | `.openhorizons-selection.history` | Append-only entry per successful run (timestamp, user, env, sha256 of manifest). |
| Tfvars | `terraform/environments/<env>.tfvars` | Generated from `terraform.tfvars.example` plus selection. Existing values preserved. |
| App config | `backstage/app-config.production.yaml` | Regenerated so only selected Golden Paths appear under `catalog.locations`. Non-Golden-Path entries preserved. |
| Rendered manifests | `backstage/k8s/.rendered/` | Filtered Kustomize directory built by `scripts/render-manifests.sh`. Contains only the manifests for enabled Backstage components. Applied by `scripts/deploy-full.sh` Phase 5b via `kubectl apply -k`. |

### Dependency Rules

Validations run before any file is written. Violations exit `2` and write nothing.

| Rule | Trigger | Requirement |
|------|---------|-------------|
| RULE-001 | `enable_ai_foundry: true` | `--horizon h3` or `all` |
| RULE-002 | `enable_ai_chat_plugin: true` | `enable_agent_api: true` |
| RULE-003 | `enable_mcp_ecosystem: true` | At least one Golden Path with `mcp-` prefix selected |
| RULE-004 | `enable_disaster_recovery: true` | `deployment_mode` `standard` or `enterprise` |

### CLI

```bash
# Interactive
scripts/install-wizard.sh

# Curated presets (one-line installs)
scripts/install-wizard.sh --environment dev --auto --profile minimal   # H1 only, no AI Chat
scripts/install-wizard.sh --environment dev --auto --profile standard  # H1 + H2 platform
scripts/install-wizard.sh --environment dev --auto --profile full      # everything (H3 + AI Foundry + MCP)

# Non-interactive (CI/CD)
scripts/install-wizard.sh \
  --environment dev \
  --horizon all \
  --auto \
  --selection-file .openhorizons-selection.yaml

# Dry-run (prints diffs, writes nothing)
scripts/install-wizard.sh --environment dev --auto --dry-run

# Hand off to deploy-full.sh after wizard completes
scripts/install-wizard.sh --environment dev --auto --next-step deploy
```

Exit codes: `0` success, `1` usage error, `2` dependency rule violation, `3` validator failure, `4` user aborted.

### Profile Presets

| Profile | Horizon | Mode | Key components | Golden Paths |
|---------|---------|------|----------------|--------------|
| `minimal` | h1 | express | container_registry, databases (Backstage core only, no AI Chat) | basic-cicd, web-application, security-baseline |
| `standard` | h2 | standard | argocd, observability, external_secrets, cost_management, AI Chat plugin | all H1 + H2 |
| `full` | all | enterprise | all 11 modules + all 6 Backstage components, including AI Foundry and MCP ecosystem | all 34 |

### Schema Validation

The manifest is validated against [`scripts/openhorizons-selection.schema.json`](../../scripts/openhorizons-selection.schema.json) every time the wizard loads it. Invalid manifests are rejected before any file is written:

- Required keys: `horizon`, `environment`, `deployment_mode`, `modules`, `backstage_components`, `golden_paths`.
- Enum values for horizon, environment and deployment_mode.
- No unknown top-level keys.
- No keys starting with `secret_`, `token_`, `password_`, or `key_`.

## Stage 0 - Prerequisites

> **Detailed prerequisites guide:** [PREREQUISITES.md](PREREQUISITES.md) covers Azure tenant/subscription requirements, GitHub / GitHub Enterprise / Azure DevOps setup, t-shirt sizing (Small / Medium / Large / XLarge), region selection, cost estimates, and a pre-deployment checklist. Read it first.

| Capability | Why it is required |
|-----------|--------------------|
| Azure subscription with Owner or User Access Administrator | Create RGs, assign RBAC, enable OIDC |
| Microsoft Entra tenant where you can register applications | Federated credentials for GitHub Actions OIDC |
| GitHub organization with Admin access | Platform repo and developer repos |
| GitHub App or OAuth App | Backstage authentication and scaffolder writes |
| Domain name | Production ingress for the portal |
| CLI tools | `az` >= 2.55, `gh` >= 2.40, `terraform` >= 1.5, `kubectl` >= 1.28, `helm` >= 3.13, `node` >= 20, `yarn` >= 4 |

Validate locally with [`scripts/validate-prerequisites.sh`](../../scripts/validate-prerequisites.sh).

## Stage 1 - Receive the Template

These steps differ when the client is consuming Open Horizons as a productized template instead of working in this monorepo directly:

1. Fork or import the repository into the client GitHub organization. If forking is blocked, mirror it.
2. Run the install wizard to configure the platform for your environment:
   ```bash
   cp .env.example .env
   scripts/install-wizard.sh
   ```
   The wizard collects GitHub org/repo, domain, auth provider (GitHub/Entra/Guest), container registry, Azure details, and AI services configuration. It writes `.env` and optionally generates K8s manifests.
3. If the wizard didn't render manifests, run manually:
   ```bash
   scripts/render-k8s.sh
   ```
   This generates all K8s manifests from templates in `backstage/k8s/templates/` using the values from `.env`. No manual search-and-replace is needed.
4. Make sure the GitHub App or PAT used by Backstage has `repo`, `workflow`, and `admin:org` (read).
5. Register Azure resource providers listed in [DEPLOYMENT_GUIDE.md, Step 1.2](DEPLOYMENT_GUIDE.md#12-register-required-azure-resource-providers).

## Stage 2 - Provision Infrastructure (L1)

The 16 Terraform modules are wired by [`terraform/main.tf`](../../terraform/main.tf) and consumed via the deployment script. Three options are documented in [DEPLOYMENT_GUIDE.md - Choose Your Deployment Method](DEPLOYMENT_GUIDE.md#choose-your-deployment-method):

- Agent-guided (`@deploy` in VS Code Copilot Chat).
- Automated script: `./scripts/deploy-full.sh --environment dev`.
- Manual step-by-step in 10 phases (Steps 1-10 of the deployment guide).

What gets created:

- **Networking**: VNet, subnets, NSGs, optional private endpoints (`networking`).
- **Identity and secrets**: Workload Identity, Key Vault, External Secrets Operator (`security`, `external-secrets`).
- **Compute**: AKS cluster with autoscaling node pools (`aks-cluster`).
- **Container platform**: ACR with private endpoint (`container-registry`).
- **Data**: PostgreSQL Flexible Server and Redis (`databases`).
- **Observability**: Log Analytics, Application Insights, Managed Prometheus, Managed Grafana (`observability`).
- **Security**: Defender for Cloud, Purview, security baseline (`defender`, `purview`, `security`).
- **AI**: AI Foundry project and connections (`ai-foundry`).
- **Operations**: GitHub self-hosted runners (`github-runners`), DR plan (`disaster-recovery`), cost management (`cost-management`).
- **Platform**: ArgoCD bootstrap, Backstage Helm release (`argocd`, `backstage`).

## Stage 3 - Deploy the Platform (L2)

Once Terraform finishes:

- **Backstage** runs as a Deployment in the `backstage` namespace and is exposed through NGINX ingress with TLS managed by cert-manager. Catalog locations from [`backstage/app-config.production.yaml`](../../backstage/app-config.production.yaml) preload all 34 Golden Paths.
- **ArgoCD** is bootstrapped with the app-of-apps in [`argocd/app-of-apps/`](../../argocd/app-of-apps/) and syncs the GitOps applications listed in [`argocd/apps/`](../../argocd/apps/) (External Secrets Operator and Gatekeeper today; the structure supports more apps without changes).
- **Policies** are applied automatically via Kustomize manifests in [`policies/kubernetes/`](../../policies/kubernetes/) plus a Conftest-style policy in [`policies/terraform/`](../../policies/terraform/).
- **Observability** stack uses Managed Prometheus / Managed Grafana with the dashboards under [`grafana/dashboards/`](../../grafana/dashboards/) and recording / alerting rules in [`prometheus/`](../../prometheus/).
- **CI/CD** is wired via the workflows in [`.github/workflows/`](../../.github/workflows/) (`ci-cd`, `cd`, `terraform-test`, `issue-ops`, plus housekeeping workflows).

## Stage 4 - Wire Context (L3)

L3 is what makes the agents productive in this codebase rather than generic. It is mostly already wired in the repo, but the client needs to know it is there:

- **27 skills** in [`.github/skills/`](../../.github/skills/) cover Azure CLI, Terraform CLI, kubectl, Helm, ArgoCD, GitHub CLI, Backstage deployment, observability stack, validation scripts, story planning, test coverage, pipeline diagnostics, codespaces golden paths, IssueOps, MCP CLI, MCP ecosystem, and document creation (Markdown, DOCX, PPTX, XLSX, PDF, FigJam).
- **12 MCP servers** in [`mcp-servers/src/tools/`](../../mcp-servers/src/tools/) expose live reference data for spec-kit, Microsoft Agent Framework, Anthropic skills, AGENTS.md, awesome-copilot, GitHub Copilot docs, gh-aw, Backstage docs / org / plugins / UI, and Spotify Backstage. They run via [`mcp-servers/docker-compose.yml`](../../mcp-servers/docker-compose.yml) and can be deployed to AKS using [`backstage/k8s/mcp-ecosystem-deployment.yaml`](../../backstage/k8s/mcp-ecosystem-deployment.yaml).
- **Three-tier memory** (Hot, Warm, Cold) lives under [`backstage/server/agent-api/memory/`](../../backstage/server/agent-api/memory/) along with the Shared Context Store.
- **CODEMAP** at [`CODEMAP.md`](../../CODEMAP.md) is the program skeleton that agents read before navigating the codebase.

Operational checks:

- `bash scripts/audit-context-quality.sh` measures context rot.
- `bash scripts/measure-intent-drift.sh` produces a health score on intent drift.

## Stage 5 - Activate Intent (L4)

L4 is what keeps the agents on task when scope or constraints change:

- The intent templates in [`golden-paths/common/templates/`](../../golden-paths/common/templates/) (`CONSTITUTION.md`, `SPECIFICATION.md`, `IMPLEMENTATION_PLAN.md`) are produced for every new repository and reused across the platform itself.
- The Specky scope-guard hooks in [`.github/hooks/specky/`](../../.github/hooks/specky/) run on `preToolUse` and block writes outside approved scope.
- The model routing in [`.github/model-routing.yaml`](../../.github/model-routing.yaml) maps SDLC phases to optimal models (Opus / Sonnet / Haiku-style decisions).

## Stage 6 - Run Agentic Execution (L5)

The platform exposes two agent surfaces:

- **Copilot Chat agents** in [`.github/agents/`](../../.github/agents/). 19 role-based agents that run inside VS Code: `ado-integration`, `architect`, `azure-portal-deploy`, `backstage-expert`, `compass`, `deploy`, `devops`, `docs`, `github-integration`, `hybrid-scenarios`, `pipeline`, `platform`, `prompt`, `reviewer`, `security`, `sentinel`, `sre`, `terraform`, `test`. Catalog and metadata are summarized in [`AGENTS.md`](../../AGENTS.md).
- **Runtime agent APIs** in [`backstage/server/`](../../backstage/server/):
  - `agent-api` - AI Chat backend used by the Backstage AI Chat plugin.
  - `agent-api-impact` - Agentic DevOps impact analytics (DORA correlation, KPIs).
  - `agent-api-maf` - Microsoft Agent Framework reference implementation.
  - `agent-api-sk` - Semantic Kernel reference implementation.

  Trajectory logging and cost tracking live in [`backstage/server/agent-api/middleware/`](../../backstage/server/agent-api/middleware/). Identity, RBAC, and NetworkPolicy for runtime agents are in [`backstage/k8s/agent-identity.yaml`](../../backstage/k8s/agent-identity.yaml).

The Backstage **AI Chat plugin** lives in [`backstage/plugins/ai-chat/`](../../backstage/plugins/ai-chat/) and is what end users interact with from the portal.

## Stage 7 - Configure Identity Federation

OIDC is split into two scopes - the platform repo and any repo the wizard generates:

- **Platform repo** uses [`scripts/setup-identity-federation.sh`](../../scripts/setup-identity-federation.sh) which adds federated credentials for the `main` branch and pull requests, plus Azure RBAC and the `AZURE_CLIENT_ID / AZURE_TENANT_ID / AZURE_SUBSCRIPTION_ID` repository secrets.
- **Generated repos** use [`golden-paths/common/azure-infrastructure/scripts/setup-azure-oidc.sh`](../../golden-paths/common/azure-infrastructure/scripts/setup-azure-oidc.sh) which is shipped inside every repo where the wizard's `Provision Azure Infrastructure` toggle is on. The helper supports `--dry-run`. Detailed usage in [Azure OIDC Setup](../../golden-paths/common/azure-infrastructure/docs/azure-oidc.md).

When OIDC is in place, the workflow [`.github/workflows/azure-infrastructure.yml`](../../golden-paths/common/azure-infrastructure/.github/workflows/azure-infrastructure.yml) shipped to generated repos runs `az deployment group what-if` or `apply` without long-lived credentials.

## Stage 8 - Validate End to End

A clean install should pass all of the following:

- `bash scripts/validate-prerequisites.sh`
- `bash scripts/validate-config.sh --environment dev`
- `bash scripts/validate-deployment.sh --environment dev`
- `bash scripts/validate-scaffolder-templates.sh golden-paths` - 34 templates.
- `bash scripts/validate-docs.sh --include-skeletons` - 0 errors.
- `bash scripts/validate-agents.sh` - all chat agents valid.
- `bash scripts/validate-substitutions.sh` - branding placeholders resolved.

Wizard automated tests:

- `bash tests/wizard/run.sh` runs **27 smoke asserts** covering CLI flags, dry-run safety, idempotency, dependency rules, schema validation, profile presets, and primitive allowlists.
- `bash tests/wizard/e2e.sh` runs **36 end-to-end asserts** that drive `install-wizard.sh -> render-manifests.sh -> kubectl kustomize` for each profile (`minimal`, `standard`, `full`) plus a custom-allowlist scenario.
- `KUBECTL_E2E_SERVER=1 bash tests/wizard/e2e.sh` adds **3 extra asserts** that submit the rendered manifests to a live Kubernetes cluster via `kubectl apply --dry-run=server`. This validates the actual admission control without applying anything.
- The CI workflow [.github/workflows/wizard-tests.yml](../../.github/workflows/wizard-tests.yml) runs both suites on every PR touching wizard code.

Functional smoke tests:

- Sign in to the Backstage portal with GitHub.
- Open a Golden Path (for example `h1-foundation/basic-cicd`) and submit the wizard with `Provision Azure Infrastructure` enabled.
- Confirm the new repository contains `catalog-info.yaml`, `mkdocs.yml`, `docs/`, `.github/agents/`, and `deploy/azure/` plus the Azure workflow.
- Run the OIDC helper inside the new repo: `./scripts/setup-azure-oidc.sh --resource-group <rg> --create-resource-group`.
- Run the workflow in `what-if` mode and confirm it authenticates via OIDC.

## Day-Two Operations

| Task | Reference |
|------|-----------|
| Add a new Golden Path | [`golden-paths/README.md`](../../golden-paths/README.md), per-template `template.yaml` |
| Add or change a Copilot agent | [`AGENTS.md`](../../AGENTS.md), [`.github/agents/`](../../.github/agents/) |
| Add a skill | [`.github/skills/`](../../.github/skills/) (companion `SKILL.md`) |
| Add an MCP server | [`mcp-servers/src/tools/`](../../mcp-servers/src/tools/) plus [`backstage/k8s/mcp-ecosystem-deployment.yaml`](../../backstage/k8s/mcp-ecosystem-deployment.yaml) |
| Roll the Backstage container image | [`backstage/Dockerfile.acr`](../../backstage/Dockerfile.acr) and the `cd.yml` workflow |
| Update Helm releases | [`deploy/helm/`](../../deploy/helm/) |
| Apply Kubernetes policies | [`policies/kubernetes/`](../../policies/kubernetes/) |
| Validate Terraform changes | `bash scripts/setup-pre-commit.sh` then `terraform fmt`, `terraform validate`, `tflint`, `tfsec` |
| Audit context rot | `bash scripts/audit-context-quality.sh` |
| Measure intent drift | `bash scripts/measure-intent-drift.sh` |
| Troubleshoot a deployment | [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) |

## Reverse and Reset

- **Tear down generated infra**: in the generated repository run the workflow with `mode=apply` against an empty parameter set or use `az deployment group delete`.
- **Tear down platform infra**: `./scripts/deploy-full.sh --environment dev --destroy` after backing up state.
- **Remove OIDC artifacts** (platform repo example):
  ```bash
  APP_ID=$(az ad app list --display-name <app-name> --query '[0].appId' -o tsv)
  az role assignment delete --assignee "$APP_ID" --scope <scope> --role Contributor
  az ad app delete --id "$APP_ID"
  gh secret delete AZURE_CLIENT_ID --repo <org>/<repo>
  gh secret delete AZURE_TENANT_ID --repo <org>/<repo>
  gh secret delete AZURE_SUBSCRIPTION_ID --repo <org>/<repo>
  ```

## References

- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Wizard Guide](WIZARD_GUIDE.md)
- [Client Installation Guide](CLIENT_INSTALLATION.md)
- [Architecture Guide](ARCHITECTURE_GUIDE.md)
- [Administrator Guide](ADMINISTRATOR_GUIDE.md)
- [Module Reference](MODULE_REFERENCE.md)
- [Performance Tuning Guide](PERFORMANCE_TUNING_GUIDE.md)
- [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md)
- [Copilot Agents Complete Guide](copilot-agents-complete-guide.md)
- [Copilot Agents Best Practices](copilot-agents-best-practices.md)
- [AGENTS Catalog](../../AGENTS.md)
- [CODEMAP](../../CODEMAP.md)
- [Golden Paths README](../../golden-paths/README.md)
- [Azure OIDC Setup](../../golden-paths/common/azure-infrastructure/docs/azure-oidc.md)
- [Context Platform Stack chapters](../context-engineer/)
- [Runbooks](../runbooks/)
