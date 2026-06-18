# Agent System — Open Horizons (Agentic DevOps Platform)

## Overview

The Open Horizons platform uses **GitHub Copilot Chat Agents** — a role-based AI assistant system that operates directly within VS Code / GitHub Copilot Chat. The platform includes **9 deploy-managed agents**, **28 skills**, **9 prompts**, and **8 instructions** for deterministic, automated platform operations.

## Architecture

```text
.github/
├── agents/          # 9 deploy-managed chat agents (.agent.md)
├── instructions/    # 8 code-generation instructions (.instructions.md)
├── prompts/         # 9 reusable prompts (.prompt.md)
├── skills/          # 28 operational skill sets (SKILL.md)
└── ISSUE_TEMPLATE/  # Issue templates
```

## Chat Agents

| Agent | File | Role |
| --- | --- | --- |
| **Deploy** | [deploy.agent.md](.github/agents/deploy.agent.md) | Deployment orchestration, end-to-end platform deployment |
| **Terraform** | [Terraform agent](.github/agents/terraform.agent.md) | Infrastructure as Code, Terraform modules |
| **Security** | [security.agent.md](.github/agents/security.agent.md) | Security policies, scanning, compliance |
| **SRE** | [sre.agent.md](.github/agents/sre.agent.md) | Reliability engineering, incident response, monitoring |
| **Backstage Expert** | [Backstage Expert agent](.github/agents/backstage-expert.agent.md) | Backstage portal deployment on AKS, GitHub auth, Golden Paths |
| **Azure Portal Deploy** | [Azure Portal Deploy agent](.github/agents/azure-portal-deploy.agent.md) | Azure AKS provisioning, Key Vault, PostgreSQL, ACR |
| **GitHub Integration** | [GitHub Integration agent](.github/agents/github-integration.agent.md) | GitHub App, org discovery, GHAS, Actions, Packages |
| **ADO Integration** | [ado-integration.agent.md](.github/agents/ado-integration.agent.md) | Azure DevOps PAT, repos, pipelines, boards |
| **Hybrid Scenarios** | [hybrid-scenarios.agent.md](.github/agents/hybrid-scenarios.agent.md) | GitHub + ADO coexistence scenarios |

### How to Use

In VS Code with GitHub Copilot Chat, mention an agent by name:

```text
@deploy Deploy the platform to dev environment
@terraform Create a new AKS module with private networking
@security Review security posture for the platform
@sre Create an incident response runbook
```

## Prompts

The 9 prompt files in the workspace prompt folder provide one-shot shortcuts (`/name` in chat picker):

| Prompt | Agent | Purpose |
| --- | --- | --- |
| `/deploy-platform` | Deploy | End-to-end platform deployment |
| `/terraform` | Terraform | Write or validate Terraform modules |
| `/azure-infra` | Azure Portal Deploy | Provision AKS, Key Vault, PostgreSQL, ACR |
| `/backstage` | Backstage Expert | Deploy Backstage portal to AKS |
| `/security-review` | Security | OWASP, RBAC, secrets audit |
| `/ado-setup` | ADO Integration | Configure ADO PAT + pipelines |
| `/hybrid-setup` | Hybrid Scenarios | GitHub + ADO coexistence |
| `/troubleshoot-incident` | SRE | Troubleshoot incidents |
| `/create-mcp-server` | — | Scaffold MCP server |

## Instructions

The 8 instruction files in the workspace instructions folder auto-apply when editing matching file types:

| Instruction | Applies To |
| --- | --- |
| `agent-files` | `*.agent.md`, `*.prompt.md`, `*.instructions.md`, `SKILL.md` |
| `github-actions` | `.github/workflows/**/*.yml`, `.github/workflows/**/*.yaml` |
| `issue-forms` | `.github/ISSUE_TEMPLATE/**/*.yml`, `.github/ISSUE_TEMPLATE/**/*.yaml` |
| `kubernetes` | `deploy/**`, `argocd/**`, `backstage/k8s/**`, `kubernetes/**`, `k8s/**`, `helm/**` |
| `python` | `*.py`, `python/**` |
| `terraform` | `*.tf`, `terraform/**`, `*.tfvars` |
| `dockerfile` | `Dockerfile` |
| `docker-compose` | `docker-compose.yml` |

## Skills

The 28 skills in the workspace skills folder provide domain-specific knowledge that agents load on demand:

| Skill | Description |
| --- | --- |
| `agentic-architecture-patterns` | Agentic system architecture patterns |
| `ai-foundry-operations` | Azure AI Foundry provisioning, model deployment, RAG |
| `architecture-doc` | Architecture document validation |
| `argocd-cli` | ArgoCD CLI for GitOps workflows |
| `azure-architecture-diagrams` | Azure architecture diagrams |
| `azure-cli` | Azure CLI resource management |
| `azure-infrastructure` | Azure architecture patterns and best practices |
| `azure-managed-redis-cache` | Azure Managed Redis patterns |
| `backstage-deployment` | Backstage portal deployment on AKS and locally |
| `codespaces-golden-paths` | GitHub Codespaces devcontainer configs per Golden Path |
| `database-management` | Database ops and health monitoring |
| `deploy-orchestration` | End-to-end platform deployment orchestration |
| `foundry-agent-blueprint` | Azure AI Foundry agent blueprint |
| `github-cli` | GitHub CLI for repos and workflows |
| `helm-cli` | Helm CLI for Kubernetes packages |
| `issue-ops` | GitHub Issue-driven slash command dispatcher |
| `kubectl-cli` | Kubernetes CLI for AKS |
| `markdown-writer` | Professional Markdown documents |
| `mcp-ecosystem` | Live methodology and reference data |
| `observability-stack` | Prometheus, Grafana, Loki, Alertmanager |
| `pipeline-diagnostics` | GitHub Actions CI/CD failure analysis and remediation |
| `prerequisites` | CLI tool validation and setup |
| `requirements-engineer` | Requirements engineering |
| `sdd-spec-engineer` | Spec-driven development artifacts |
| `story-planning` | INVEST user story decomposition and GitHub Issues creation |
| `terraform-cli` | Terraform CLI for Azure infra |
| `test-coverage` | Test coverage analysis, CI check runs, and quality gates |
| `validation-scripts` | Validation scripts for deployments |

## Related Documentation

- [Deployment Guide](docs/guides/DEPLOYMENT_GUIDE.md)
- [Architecture Guide](docs/guides/ARCHITECTURE_GUIDE.md)
- [MCP Servers Usage](mcp-servers/USAGE.md)
- [Golden Paths](golden-paths/README.md)
- [Contributing](CONTRIBUTING.md)
