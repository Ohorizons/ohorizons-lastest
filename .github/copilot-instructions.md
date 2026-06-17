# GitHub Copilot Instructions for Open Horizons Platform

## Project Overview

Open Horizons is an open-source **Agentic DevOps Platform** (not just an IDP) deployed on Azure AKS. It serves two personas through a single Backstage portal: **Developer IDP** (services, golden paths, docs) and **Agent IDP** (agent catalog, trajectories, cost, governance). The platform implements the Context Platform Stack: a 5-layer architecture grounded in 25+ peer-reviewed papers.

### The 5-Layer Architecture

```
L5 Agentic Execution  → backstage/server/agent-api*/ + middleware/ + .github/agents/
L4 Intent Engineering  → CONSTITUTION.md + golden-paths/common/templates/ + hooks/ + model-routing
L3 Context Engineering → mcp-servers/ + memory/ (SCS, tiers) + skills/ + CODEMAP.md
L2 Platform Engineering→ backstage/ + argocd/ + policies/ + golden-paths/ + grafana/
L1 Cloud/Infrastructure→ terraform/modules/ (16 modules) + backstage/k8s/
```

The platform is organized into three adoption stages:

- **H1 Foundation**: Core infrastructure (AKS, networking, security, databases)
- **H2 Enhancement**: Platform services (ArgoCD, Backstage, observability, Golden Paths)
- **H3 Innovation**: AI capabilities (AI Chat, AI Impact, agents)

## Current Versions

| Image | Tag | Registry |
|-------|-----|----------|
| `ohorizons-backstage` | `v7.2.4` | GHCR (public) |
| `ohorizons-agent-api` | `v7.2.4` | GHCR (public) |
| `ohorizons-agent-api-impact` | `v7.2.4` | GHCR (public) |
| `mcp-ecosystem` | `v7.2.4` | GHCR (public) |

**Tag format**: `v<semver>-<suffix>` — Never use `:latest` in deployment manifests.

## Infrastructure

Infrastructure is configured per-client via `.env` and the install wizard.
Run `scripts/render-k8s.sh` to generate K8s manifests from templates.

### Required Azure Resources
| Resource | Description |
|----------|-------------|
| AKS Cluster | Kubernetes cluster for platform workloads |
| Resource Group | Container for all Azure resources |
| Subscription | Azure subscription with Contributor access |

### Local (kind)
| Resource | Value |
|----------|-------|
| Kind Cluster | Configurable via local setup |
| Backstage | `localhost:7007` |
| AI Chat | `127.0.0.1:8008` |
| AI Impact | `127.0.0.1:8011` |
| ArgoCD | `localhost:8443` |
| Grafana | `localhost:3000` |
| Prometheus | `localhost:9090` (NodePort 30900) |

## Technology Stack

- **Infrastructure**: Terraform for Azure (AKS, networking, databases)
- **Container Platform**: Azure Kubernetes Service (AKS)
- **GitOps**: ArgoCD for continuous deployment
- **IDP**: Backstage (open-source)
- **Observability**: Prometheus, Grafana, Alertmanager
- **AI**: Azure OpenAI (GPT-5.1) via Azure AI Foundry, Microsoft Agent Framework

## Code Standards

### Terraform
- Use Terraform 1.5+
- Always specify provider versions
- Use modules for reusable components
- Tag all resources with: environment, project, owner, cost-center
- Use Workload Identity (never service principal secrets)
- Enable private endpoints for all PaaS services

### Kubernetes
- Use Kustomize for environment overlays
- Always set resource limits and requests
- Run containers as non-root
- Configure liveness and readiness probes
- Apply network policies
- Use standard Kubernetes labels (app.kubernetes.io/*)

### Python
- Use Python 3.11+
- Use FastAPI for APIs
- Use Pydantic for validation
- Use structlog for logging
- Follow PEP 8 style guidelines

### Shell Scripts
- Use bash with strict mode (set -euo pipefail)
- Include usage instructions
- Validate inputs
- Use meaningful variable names

## File Locations

| Component | Location |
|-----------|----------|
| Backstage app | `backstage/` |
| Backstage K8s manifests | `backstage/k8s/` |
| AI Chat plugin | `backstage/plugins/ai-chat/` |
| Agent API (AI Chat) | `backstage/server/agent-api/` |
| Agent API (AI Impact) | `backstage/server/agent-api-impact/` |
| Agent API (MAF) | `backstage/server/agent-api-maf/` |
| Agent API (SK) | `backstage/server/agent-api-sk/` |
| Agent docker-compose | `backstage/server/docker-compose.yml` |
| Terraform modules | `terraform/modules/` |
| Environment configs | `terraform/environments/` |
| Helm values | `deploy/helm/` |
| Golden Path templates | `golden-paths/` |
| SDD intent templates | `golden-paths/common/templates/` |
| Agent specifications | `.github/agents/` |
| Agent skills | `.github/skills/` |
| Automation scripts | `scripts/` |
| Documentation | `docs/` |
| Context Platform Stack docs | `context-engineer/` |
| Prompt files | `.github/prompts/` |
| Instructions | `.github/instructions/` |
| Model routing config | `.github/model-routing.yaml` |
| SDD hooks | `.github/hooks/specky/` |
| OPA policies (K8s) | `policies/kubernetes/` |
| OPA policies (Terraform) | `policies/terraform/` |
| Grafana dashboards | `grafana/dashboards/` |
| MCP servers | `mcp-servers/src/tools/` |
| Agent memory (L3) | `backstage/server/agent-api/memory/` |
| Agent middleware (L5) | `backstage/server/agent-api/middleware/` |
| Agent identity (K8s) | `backstage/k8s/agent-identity.yaml` |
| Program skeleton | `CODEMAP.md` |
| Local dev (kind) | `local/` |

## Security Requirements

1. **Authentication**: Always use Workload Identity or Managed Identity
2. **Secrets**: Store in Azure Key Vault, never in code
3. **Network**: Use private endpoints, configure NSGs
4. **Scanning**: Run security scans in CI/CD (Trivy, tfsec, gitleaks)
5. **RBAC**: Follow least privilege principle

## Naming Conventions

- Resources: `{project}-{environment}-{resource}-{region}`
- Terraform: snake_case for variables, resources
- Kubernetes: kebab-case for names, labels
- Files: kebab-case for filenames

## Common Tasks

### Creating a new module
```bash
./scripts/create-module.sh <module-name>
```

### Deploying the platform (3 options)

**Option A — Agent-guided:**
```
@deploy Deploy the platform to dev environment
```

**Option B — Automated script:**
```bash
./scripts/deploy-full.sh --environment dev --dry-run
./scripts/deploy-full.sh --environment dev
```

**Option C — Manual:**
```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

### Running validation
```bash
./scripts/validate-prerequisites.sh
./scripts/validate-config.sh --environment dev
./scripts/validate-deployment.sh --environment dev
```

## Agent System

The platform uses **18 Copilot Chat Agents** in `.github/agents/` for interactive development assistance, **27 skills** for domain knowledge, **16 prompts** for one-shot shortcuts, and **8 instructions** for auto-applied coding standards.

### Agent Organization
- **@deploy**: Deployment orchestration, end-to-end platform deployment
- **@architect**: System architecture, AI Foundry, multi-agent design
- **@devops**: CI/CD, GitOps, MLOps, Golden Paths, pipelines
- **@docs**: Documentation generation and maintenance
- **@onboarding**: New team member onboarding and guidance
- **@platform**: Backstage portal, platform services, developer experience
- **@reviewer**: Code review, PR analysis, quality checks
- **@security**: Security policies, scanning, compliance
- **@sre**: Reliability engineering, incident response, monitoring
- **@terraform**: Infrastructure as Code, Terraform modules
- **@test**: Test generation, validation, quality assurance

### Skills Available
Agents can use skills from `.github/skills/` including: terraform-cli, kubectl-cli, azure-cli, argocd-cli, helm-cli, github-cli, validation-scripts, and more.

### Agent Handoffs
Agents support handoffs for workflow orchestration. Example: @terraform -> @devops -> @security -> @test

When generating code for agents:
- Follow the agent specification format in `.github/agents/`
- Include proper YAML frontmatter with `tools`, `infer`, `skills`, `handoffs`
- Define three-tier boundaries: ALWAYS / ASK FIRST / NEVER
- Reference skills for CLI operations
- Include clarifying questions before proceeding

## Context Engineering (L3)

The platform implements structured context management:

- **CODEMAP.md**: Program skeleton for agent comprehension (Semantic Density Principle)
- **Shared Context Store (CA-MCP)**: Cross-agent state in `backstage/server/agent-api/memory/context_store.py`
- **Three-Tier Memory**: Hot (CONSTITUTION.md, ~660 tokens), Warm (agent system prompt), Cold (knowledge base retrieval) in `backstage/server/agent-api/memory/tiers.py`
- **MCP Servers**: 12 tool files for documentation search and reference data
- **Skills**: 27 SKILL.md files with lazy loading (description always loaded, body on-demand)
- **Context Quality Audit**: `scripts/audit-context-quality.sh` measures context rot

## Intent Engineering (L4)

The platform enforces Spec-Driven Development (SDD):

- **CONSTITUTION.md**: Non-negotiable principles and trade-off hierarchy (template in `golden-paths/common/templates/`)
- **SPECIFICATION.md**: EARS-format machine-parseable requirements (template in `golden-paths/common/templates/`)
- **IMPLEMENTATION_PLAN.md**: Atomic task breakdown with [P]/[S] markers and human gates (template in `golden-paths/common/templates/`)
- **Scope Guard Hook**: `preToolUse` hook in `.github/hooks/specky/scripts/scope-guard.sh` blocks writes outside approved scope
- **Model Routing**: `.github/model-routing.yaml` maps SDLC phases to optimal models (Opus for spec, Sonnet for code, Haiku for boilerplate)
- **Intent Drift Metrics**: `scripts/measure-intent-drift.sh` computes health score

## Agentic Execution (L5)

The platform provides agent runtime governance:

- **Trajectory Logging**: Every tool call, decision, and outcome recorded in `backstage/server/agent-api/middleware/trajectory.py`
- **Cost Tracking**: Per-agent token usage and budget alerts in `backstage/server/agent-api/middleware/cost_tracker.py`
- **Agent Identity**: K8s ServiceAccounts, RBAC Roles, NetworkPolicy in `backstage/k8s/agent-identity.yaml`
- **7 Runtime Agents**: orchestrator, pipeline, sentinel, compass, guardian, lighthouse, forge
- **Observability APIs**: `/api/agents/trajectories`, `/api/agents/costs`, `/api/agents/context`

## Golden Paths

When creating or modifying Golden Path templates:
- Follow Backstage template format
- Include skeleton files
- Include SDD intent artifacts (CONSTITUTION.md, SPECIFICATION.md, IMPLEMENTATION_PLAN.md) from `golden-paths/common/templates/`
- Add comprehensive documentation
- Test scaffolding locally before registering
