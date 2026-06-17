# Agent System — Open Horizons (Agentic DevOps Platform)

## Overview

The Open Horizons platform uses **GitHub Copilot Chat Agents** — a role-based AI assistant system that operates directly within VS Code / GitHub Copilot Chat. The platform includes **19 specialized agents**, **27 skills**, **16 prompts**, and **10 instructions** for deterministic, automated platform operations.

## Architecture

```text
.github/
├── agents/          # 19 role-based chat agents (.agent.md)
├── instructions/    # 10 code-generation instructions (.instructions.md)
├── prompts/         # 16 reusable prompts (.prompt.md)
├── skills/          # 27 operational skill sets (SKILL.md)
└── ISSUE_TEMPLATE/  # Issue templates
```

## Chat Agents

| Agent | File | Role |
| --- | --- | --- |
| **Deploy** | [deploy.agent.md](.github/agents/deploy.agent.md) | Deployment orchestration, end-to-end platform deployment |
| **Architect** | [architect.agent.md](.github/agents/architect.agent.md) | System architecture, AI Foundry, multi-agent design |
| **DevOps** | [devops.agent.md](.github/agents/devops.agent.md) | CI/CD, GitOps, MLOps, Golden Paths, pipelines |
| **Platform** | [platform.agent.md](.github/agents/platform.agent.md) | Backstage portal, platform services, developer experience |
| **Terraform** | [Terraform agent](.github/agents/terraform.agent.md) | Infrastructure as Code, Terraform modules |
| **Security** | [security.agent.md](.github/agents/security.agent.md) | Security policies, scanning, compliance |
| **SRE** | [sre.agent.md](.github/agents/sre.agent.md) | Reliability engineering, incident response, monitoring |
| **Reviewer** | [reviewer.agent.md](.github/agents/reviewer.agent.md) | Code review, PR analysis, quality checks |
| **Test** | [test.agent.md](.github/agents/test.agent.md) | Test generation, validation, quality assurance |
| **Docs** | [docs.agent.md](.github/agents/docs.agent.md) | Documentation generation and maintenance |
| **Backstage Expert** | [Backstage Expert agent](.github/agents/backstage-expert.agent.md) | Backstage portal deployment on AKS, GitHub auth, Golden Paths |
| **Azure Portal Deploy** | [Azure Portal Deploy agent](.github/agents/azure-portal-deploy.agent.md) | Azure AKS provisioning, Key Vault, PostgreSQL, ACR |
| **GitHub Integration** | [GitHub Integration agent](.github/agents/github-integration.agent.md) | GitHub App, org discovery, GHAS, Actions, Packages |
| **ADO Integration** | [ado-integration.agent.md](.github/agents/ado-integration.agent.md) | Azure DevOps PAT, repos, pipelines, boards |
| **Hybrid Scenarios** | [hybrid-scenarios.agent.md](.github/agents/hybrid-scenarios.agent.md) | GitHub + ADO coexistence scenarios |
| **Prompt Engineer** | [prompt.agent.md](.github/agents/prompt.agent.md) | Production-ready prompt engineering |
| **Compass** | [compass.agent.md](.github/agents/compass.agent.md) | Epic decomposition, user stories, sprint planning |
| **Pipeline** | [pipeline.agent.md](.github/agents/pipeline.agent.md) | CI/CD diagnostics, GitHub Actions failure analysis |
| **Sentinel** | [sentinel.agent.md](.github/agents/sentinel.agent.md) | Test coverage analysis, CI check runs, quality gates |

### How to Use

In VS Code with GitHub Copilot Chat, mention an agent by name:

```text
@deploy Deploy the platform to dev environment
@architect Design a microservice architecture for order processing
@devops Set up GitOps deployment with ArgoCD
@terraform Create a new AKS module with private networking
@security Review security posture for the platform
@sre Create an incident response runbook
```

## Prompts

The 16 prompt files in the workspace prompt folder provide one-shot shortcuts (`/name` in chat picker):

| Prompt | Agent | Purpose |
| --- | --- | --- |
| `/deploy-platform` | Deploy | End-to-end platform deployment |
| `/terraform` | Terraform | Write or validate Terraform modules |
| `/azure-infra` | Azure Portal Deploy | Provision AKS, Key Vault, PostgreSQL, ACR |
| `/backstage` | Backstage Expert | Deploy Backstage portal to AKS |
| `/security-review` | Security | OWASP, RBAC, secrets audit |
| `/architecture` | Architect | Design with WAF + Mermaid diagrams |
| `/ado-setup` | ADO Integration | Configure ADO PAT + pipelines |
| `/hybrid-setup` | Hybrid Scenarios | GitHub + ADO coexistence |
| `/create-service` | Platform | Scaffold a new microservice |
| `/deploy-service` | DevOps | Deploy a service to AKS |
| `/review-code` | Reviewer | Comprehensive code review |
| `/troubleshoot-incident` | SRE | Troubleshoot incidents |
| `/create-mcp-server` | — | Scaffold MCP server |
| `/analyze-checks` | Sentinel | Analyze CI check runs and PR status |
| `/decompose-epic` | Compass | Decompose epics into INVEST user stories |
| `/diagnose-pipeline` | Pipeline | Diagnose GitHub Actions pipeline failures |

## Instructions

The 10 instruction files in the workspace instructions folder auto-apply when editing matching file types:

| Instruction | Applies To |
| --- | --- |
| `agent-files` | `*.agent.md`, `*.prompt.md`, `*.instructions.md`, `SKILL.md` |
| `github-actions` | `.github/workflows/**/*.yml`, `.github/workflows/**/*.yaml` |
| `issue-forms` | `.github/ISSUE_TEMPLATE/**/*.yml`, `.github/ISSUE_TEMPLATE/**/*.yaml` |
| `kubernetes` | `deploy/**`, `argocd/**`, `backstage/k8s/**`, `kubernetes/**`, `k8s/**`, `helm/**` |
| `python` | `*.py`, `python/**` |
| `terraform` | `*.tf`, `terraform/**`, `*.tfvars` |
| `typescript` | `*.ts` |
| `dockerfile` | `Dockerfile` |
| `docker-compose` | `docker-compose.yml` |
| `mermaid-figjam` | `*.mmd`, `*.mermaid` |

## Skills

The 27 skills in the workspace skills folder provide domain-specific knowledge that agents load on demand:

| Skill | Description |
| --- | --- |
| `ai-foundry-operations` | Azure AI Foundry provisioning, model deployment, RAG |
| `argocd-cli` | ArgoCD CLI for GitOps workflows |
| `azure-cli` | Azure CLI resource management |
| `azure-infrastructure` | Azure architecture patterns and best practices |
| `backstage-deployment` | Backstage portal deployment on AKS and locally |
| `codespaces-golden-paths` | GitHub Codespaces devcontainer configs per Golden Path |
| `database-management` | Database ops and health monitoring |
| `deploy-orchestration` | End-to-end platform deployment orchestration |
| `docx-creator` | Word document generation with Microsoft enterprise branding |
| `figjam-diagrams` | FigJam diagrams with Mermaid and Microsoft brand colors |
| `github-cli` | GitHub CLI for repos and workflows |
| `helm-cli` | Helm CLI for Kubernetes packages |
| `issue-ops` | GitHub Issue-driven slash command dispatcher |
| `kubectl-cli` | Kubernetes CLI for AKS |
| `markdown-writer` | Professional Markdown documents |
| `mcp-cli` | Model Context Protocol server reference |
| `mcp-ecosystem` | 39 tools for live methodology and reference data |
| `observability-stack` | Prometheus, Grafana, Loki, Alertmanager |
| `pdf-creator` | Microsoft-branded PDF documents |
| `pptx-creator` | PowerPoint presentations with Microsoft enterprise branding |
| `prerequisites` | CLI tool validation and setup |
| `terraform-cli` | Terraform CLI for Azure infra |
| `validation-scripts` | Validation scripts for deployments |
| `xlsx-creator` | Excel workbooks with Microsoft enterprise branding |
| `pipeline-diagnostics` | GitHub Actions CI/CD failure analysis and remediation |
| `story-planning` | INVEST user story decomposition and GitHub Issues creation |
| `test-coverage` | Test coverage analysis, CI check runs, and quality gates |

## Related Documentation

- [Deployment Guide](docs/guides/DEPLOYMENT_GUIDE.md)
- [Architecture Guide](docs/guides/ARCHITECTURE_GUIDE.md)
- [MCP Servers Usage](mcp-servers/USAGE.md)
- [Golden Paths](golden-paths/README.md)
- [Contributing](CONTRIBUTING.md)
