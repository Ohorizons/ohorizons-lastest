---
title: "Open Horizons Wizard Guide"
description: "End-to-end walkthrough of the Backstage wizard used by clients to scaffold repositories and choose what the agents and Azure deployment should do"
author: "Platform Engineering"
date: "2026-05-05"
version: "1.0.0"
status: "approved"
tags: ["wizard", "golden-paths", "backstage", "azure", "agents", "client-onboarding"]
---

# Open Horizons Wizard Guide

The Open Horizons platform ships as a turnkey solution that clients install once and then use as a self-service portal. Every repository, every agent, and every Azure deployment is created through a wizard inside Backstage. This guide explains what the wizard does, what each option means, and what gets generated end to end.

## Table of Contents

- [Who This Guide Is For](#who-this-guide-is-for)
- [What the Wizard Produces](#what-the-wizard-produces)
- [Wizard Flow](#wizard-flow)
- [Choosing a Golden Path](#choosing-a-golden-path)
- [Common Wizard Steps](#common-wizard-steps)
- [Azure Deployment Toggle](#azure-deployment-toggle)
- [What Gets Created in the Generated Repo](#what-gets-created-in-the-generated-repo)
- [Activating the Generated Repository](#activating-the-generated-repository)
- [Reference Templates](#reference-templates)

## Who This Guide Is For

- Developers consuming the Open Horizons portal to scaffold work.
- Tech leads picking the right Golden Path for a given workload.
- Platform engineers operating the portal at the client site.
- Solution architects evaluating Open Horizons as a productized platform.

> The wizard runs on top of an already deployed platform. To install or upgrade the platform itself, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md). For the client-receive checklist when adopting the template, see [CLIENT_INSTALLATION.md](CLIENT_INSTALLATION.md).

## What the Wizard Produces

The wizard is the single entry point for creating new work. Selecting a Golden Path drives all the downstream automation:

- A new GitHub repository under the configured organization.
- A skeleton with Backstage `catalog-info.yaml` and TechDocs (`mkdocs.yml`, `docs/`).
- Three reusable Copilot agents (`pipeline`, `sentinel`, `compass`) wired into `.github/agents/` with companion skills under `.github/skills/`.
- (Optional) An Azure infrastructure baseline in `deploy/azure/` plus a `.github/workflows/azure-infrastructure.yml` workflow with `what-if` and `apply` modes that authenticate via OIDC.
- Catalog registration so the new component shows up in the Backstage portal automatically.

## Wizard Flow

```text
+----------------------------+
| 1. Open Horizons Portal    |
|    (Backstage on AKS)      |
+-------------+--------------+
              |
              v
+----------------------------+
| 2. Choose Golden Path      |
|    (34 templates)          |
+-------------+--------------+
              |
              v
+----------------------------+
| 3. Wizard Form             |
|    - Identity & Repo       |
|    - Workload Options      |
|    - Azure Deployment      |  <-- toggle
|    - CI/CD & Security      |
+-------------+--------------+
              |
              v
+----------------------------+
| 4. Scaffolder Steps        |
|    fetch:template          |
|    fetch:plain (agents)    |
|    publish:github          |
|    catalog:register        |
+-------------+--------------+
              |
              v
+----------------------------+
| 5. Output                  |
|    - Repo URL              |
|    - Catalog entity        |
|    - Optional Azure infra  |
|    - GitHub Actions ready  |
+----------------------------+
```

## Choosing a Golden Path

Templates are grouped into three horizons. All 34 templates pass schema validation, generate documentation, and ship the Copilot agents. **32 of them** include the Azure Deployment toggle described below; the remaining 2 (`infrastructure-provisioning` and `rag-application`) always provision Azure because their value proposition is the infrastructure itself.

| Horizon | Examples | When to Pick |
|---------|----------|--------------|
| H1 Foundation | `web-application`, `basic-cicd`, `documentation-site`, `new-microservice`, `security-baseline`, `infrastructure-provisioning` | Greenfield repos and standardization |
| H2 Enhancement | `microservice`, `api-microservice`, `api-gateway`, `event-driven-microservice`, `gitops-deployment`, `todo-app` | Service-oriented patterns and migrations |
| H3 Innovation | `mcp-agent-framework`, `mcp-spec-kit`, `multi-agent-system`, `foundry-agent`, `rag-application`, `mlops-pipeline` | Agentic, AI, and MCP workloads |

See [`golden-paths/README.md`](../../golden-paths/README.md) for the full list and per-template summaries.

## Common Wizard Steps

Most templates share these wizard sections. Optional sections appear only on templates where they are meaningful.

### Identity and Repository

| Field | Behavior |
|-------|----------|
| `name` / `appName` / `serviceName` | Unique kebab-case identifier; used to derive Azure resource names and Backstage entity refs. |
| `owner` | Backstage owner picker; backed by the catalog `Group`/`User` entities. |
| `description` | Free-form text used in `catalog-info.yaml` and the generated PR description. |
| `repoUrl` | Backstage RepoUrlPicker restricted to `github.com`. |
| `visibility` | `private` by default. |

### Workload Options

Each template surfaces only the options it can act on. Examples:

- Language and runtime version (`python`, `nodejs`, `dotnet`).
- API protocol (`REST`, `gRPC`, `GraphQL`).
- Messaging (`event-hub`, `service-bus`).
- Storage (`postgres`, `cosmos-nosql`, `redis`).

### Azure Deployment

This toggle controls whether the wizard generates Azure infrastructure for the new repo. Defaults to `true` so that the generated repo is production-ready out of the box.

```yaml
- title: Azure Deployment
  description: Optional Azure infrastructure baseline
  properties:
    deployToAzure:
      title: Provision Azure Infrastructure
      type: boolean
      default: true
```

Templates that always provision Azure (`infrastructure-provisioning`, `rag-application`) do not show this toggle because Azure is the deliverable.

### CI/CD and Security

- `enableSecurity` (GHAS code scanning).
- `enableDependencyReview` (Dependabot + dependency review).
- `enableDeploy` and `deploymentTarget` for compute target.
- `requireApproval` for production environments.

## Azure Deployment Toggle

When `deployToAzure` is checked, the wizard adds the following to the generated repository:

```text
deploy/
└── azure/
    ├── main.bicep                 # Log Analytics, App Insights, Storage baseline
    └── README.md                  # Deployment instructions
.github/
└── workflows/
    └── azure-infrastructure.yml   # what-if / apply via OIDC
scripts/
└── setup-azure-oidc.sh            # One-time helper to wire OIDC + secrets
```

The workflow expects three repository secrets (set automatically by the helper script):

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

The platform repository itself already has these configured. New repositories run `./scripts/setup-azure-oidc.sh --resource-group <rg> --create-resource-group` once after creation. See [`golden-paths/common/azure-infrastructure/docs/azure-oidc.md`](../../golden-paths/common/azure-infrastructure/docs/azure-oidc.md).

### Modes

The generated workflow supports two deployment modes selected via `workflow_dispatch`:

- `what-if`: Runs `az deployment group what-if` and prints the diff. Safe to run from any branch.
- `apply`: Runs `az deployment group create` and provisions or updates resources.

### Disabling the Toggle

Unchecking `deployToAzure` produces a repository without the Bicep baseline, the Azure workflow, or the OIDC helper. Useful for libraries, CLI tools, frontend packages, or repositories that deploy elsewhere.

## What Gets Created in the Generated Repo

Every Golden Path produces this minimum surface area:

```text
<repo-name>/
├── README.md
├── catalog-info.yaml              # Backstage catalog entry
├── mkdocs.yml                     # TechDocs config
├── docs/
│   └── index.md                   # Initial documentation
├── .github/
│   ├── agents/                    # pipeline, sentinel, compass
│   ├── skills/                    # pipeline-diagnostics, test-coverage, story-planning
│   └── workflows/                 # CI, security, optional Azure
└── (template-specific application code)
```

### Copilot Agents

Three reusable agents are injected into every generated repo:

| Agent | Purpose |
|-------|---------|
| `pipeline` | Diagnose and remediate GitHub Actions failures. |
| `sentinel` | Quality gates and test coverage analysis. |
| `compass` | Sprint planning and INVEST-style story decomposition. |

Each agent ships with a companion skill under `.github/skills/<skill>/SKILL.md`. They follow the lean-agent + rich-skill pattern documented in [`AGENTS.md`](../../AGENTS.md).

## Activating the Generated Repository

After the wizard finishes, the developer follows three short steps. They are also written into the PR or initial commit of the generated repo.

1. **Configure Azure OIDC** (only if `deployToAzure` was checked):
   ```bash
   ./scripts/setup-azure-oidc.sh \
     --resource-group <resource-group> \
     --create-resource-group
   ```

2. **Run the infrastructure preview**:
   ```bash
   gh workflow run azure-infrastructure.yml \
     --field environment=dev \
     --field resource_group=<resource-group> \
     --field location=centralus \
     --field mode=what-if
   ```

3. **Apply the deployment when the diff is clean**:
   ```bash
   gh workflow run azure-infrastructure.yml \
     --field environment=dev \
     --field resource_group=<resource-group> \
     --field location=centralus \
     --field mode=apply
   ```

## Reference Templates

| Template | Wizard Highlights |
|----------|------------------|
| [`h1-foundation/basic-cicd`](../../golden-paths/h1-foundation/basic-cicd/template.yaml) | Adds CI/CD to an existing repo; full pipeline + security toggles. |
| [`h1-foundation/security-baseline`](../../golden-paths/h1-foundation/security-baseline/template.yaml) | GHAS, secret scanning, branch protection. |
| [`h1-foundation/web-application`](../../golden-paths/h1-foundation/web-application/template.yaml) | Frontend + backend + database + auth. |
| [`h2-enhancement/microservice`](../../golden-paths/h2-enhancement/microservice/template.yaml) | Production-grade service with observability and HPA. |
| [`h2-enhancement/todo-app`](../../golden-paths/h2-enhancement/todo-app/template.yaml) | Reference application using the wizard end-to-end. |
| [`h3-innovation/mcp-agent-framework`](../../golden-paths/h3-innovation/mcp-agent-framework/template.yaml) | MCP server with Microsoft Agent Framework. |
| [`h3-innovation/rag-application`](../../golden-paths/h3-innovation/rag-application/template.yaml) | RAG application; Azure infra is mandatory. |

For the catalog of agents, prompts, and skills the platform exposes inside Backstage, see [`AGENTS.md`](../../AGENTS.md).
