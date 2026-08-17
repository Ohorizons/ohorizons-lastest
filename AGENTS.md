# Open Horizons Agent Instructions

Open Horizons is an open-source **Agentic DevOps Platform** on Azure AKS. It serves two personas through one Backstage portal: **Developer IDP** for services, golden paths, and docs, and **Agent IDP** for agent catalog, trajectories, cost, and governance.

## Architecture

The platform implements the Context Platform Stack:

```text
L5 Agentic Execution  -> backstage/server/agent-api*/ + middleware/ + .github/agents/
L4 Intent Engineering  -> golden-paths/common/templates/ + .github/prompts/ + repo-internal model-routing convention
L3 Context Engineering -> mcp-servers/ + backstage/server/agent-api/memory/ + .github/skills/ + CODEMAP.md
L2 Platform Engineering-> backstage/ + argocd/ + policies/ + golden-paths/ + grafana/
L1 Cloud/Infrastructure-> terraform/modules/ + backstage/k8s/
```

Adoption stages:

- **H1 Foundation:** AKS, networking, security, and databases.
- **H2 Enhancement:** ArgoCD, Backstage, observability, and Golden Paths.
- **H3 Innovation:** AI Chat, AI Impact, and agent capabilities.

## Current Container Tags

| Image | Tag | Registry |
| --- | --- | --- |
| `ohorizons-backstage` | `v7.2.6` | GHCR public |
| `ohorizons-agent-api` | `v7.2.6` | GHCR public |
| `ohorizons-agent-api-impact` | `v7.2.6` | GHCR public |
| `mcp-ecosystem` | `v7.2.5` | GHCR public |
| `ohorizons-agent-api-maf` | `v7.2.5` | GHCR public |
| `ohorizons-agent-api-sk` | `v7.2.5` | GHCR public |
| `ohorizons-foundry-agents` | `v7.2.5` | GHCR public |

Use tag format `v<semver>-<suffix>` and never use `:latest` in deployment manifests. The MCP ecosystem, MAF/SK agent APIs, and Foundry gateway ship on a separate cadence; pin them independently with `MCP_ECOSYSTEM_TAG`.

## Build, Deploy, and Validate

Render Kubernetes manifests after configuration changes:

```bash
./scripts/render-k8s.sh
```

Deploy the platform with the orchestrated script:

```bash
./scripts/deploy-full.sh --environment dev --dry-run
./scripts/deploy-full.sh --environment dev
```

For manual Terraform deployment, initialize from `terraform/` and keep the checked-in provider lock file:

```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars -out=h1.tfplan
terraform apply h1.tfplan
terraform apply -var-file=environments/dev.tfvars \
  -target=module.argocd -target=module.observability \
  -target=module.external_secrets -target=module.databases
```

The Kubernetes, Helm, and kubectl providers are configured from `module.aks` outputs. A single-pass `terraform apply` on an empty subscription fails at plan time; apply H1 first or use `scripts/deploy-full.sh`.

Run the existing validation scripts when relevant:

```bash
./scripts/validate-prerequisites.sh
./scripts/validate-config.sh --environment dev
./scripts/validate-deployment.sh --environment dev
```

## Repository Layout

| Component | Path |
| --- | --- |
| Backstage app | `backstage/` |
| Backstage Kubernetes manifests | `backstage/k8s/` |
| AI Chat plugin | `backstage/plugins/ai-chat/` |
| Agent API for AI Chat | `backstage/server/agent-api/` |
| Agent API for AI Impact | `backstage/server/agent-api-impact/` |
| Agent API for Microsoft Agent Framework | `backstage/server/agent-api-maf/` |
| Agent API for Semantic Kernel | `backstage/server/agent-api-sk/` |
| Foundry agents gateway | `foundry/agents-service/` |
| Foundry Kubernetes manifests | `foundry/k8s/` |
| Agent docker-compose | `backstage/server/docker-compose.yml` |
| Terraform modules | `terraform/modules/` |
| Terraform environments | `terraform/environments/` |
| Helm values | `deploy/helm/` |
| Golden Path templates | `golden-paths/` |
| SDD intent templates | `golden-paths/common/templates/` |
| Copilot agent specifications | `.github/agents/` |
| Agent skills | `.github/skills/` |
| Automation scripts | `scripts/` |
| Documentation | `docs/` |
| Prompt files | `.github/prompts/` |
| Scoped instruction files | `.github/instructions/` |
| Copilot CLI repo guard hook manifest | `.github/hooks/repo-guard.json` |
| Copilot CLI repo guard hook script | `.github/hooks/repo-guard.sh` |
| Repository-internal model routing convention | `.github/model-routing.yaml` |
| OPA policies for Kubernetes | `policies/kubernetes/` |
| OPA policies for Terraform | `policies/terraform/` |
| Grafana dashboards | `grafana/dashboards/` |
| Context Platform dashboards | `grafana/dashboards/context-platform/` |
| Architecture docs and ADRs | `docs/architecture/` |
| MCP server tools | `mcp-servers/src/tools/` |
| Agent memory implementation | `backstage/server/agent-api/memory/` |
| Agent middleware | `backstage/server/agent-api/middleware/` |
| Agent identity manifest | `backstage/k8s/agent-identity.yaml` |
| Program skeleton | `CODEMAP.md` |

## Non-Negotiable Conventions

- Use Workload Identity or Managed Identity for Azure access; do not introduce service principal secrets.
- Store secrets in Azure Key Vault or existing secret-management flows; never commit credentials.
- Prefer private endpoints for Azure PaaS services.
- Follow least-privilege RBAC for Azure, Kubernetes, GitHub, and Backstage integrations.
- Use resource names shaped as `{project}-{environment}-{resource}-{region}` where applicable.
- Use kebab-case for files and Kubernetes names, and snake_case for Terraform variables and resources.
- Use Kustomize overlays for Kubernetes environment differences.
- Keep deployment manifests pinned to explicit image tags.

Language and tool-specific standards live in scoped instruction files instead of this always-loaded file:

- @.github/instructions/terraform.instructions.md
- @.github/instructions/kubernetes.instructions.md
- @.github/instructions/python.instructions.md
- @.github/instructions/shell.instructions.md
- @.github/instructions/typescript.instructions.md
- @.github/instructions/github-actions.instructions.md
- @.github/instructions/dockerfile.instructions.md
- @.github/instructions/docker-compose.instructions.md
- @.github/instructions/issue-forms.instructions.md
- @.github/instructions/agent-files.instructions.md

## Context, Intent, and Execution

Context Engineering uses `CODEMAP.md`, `backstage/server/agent-api/memory/context_store.py`, `backstage/server/agent-api/memory/tiers.py`, `mcp-servers/src/tools/`, and `.github/skills/`. Audit context quality with `scripts/audit-context-quality.sh`.

Intent Engineering uses the templates in `golden-paths/common/templates/`, prompt shortcuts in `.github/prompts/`, repo guard hooks in `.github/hooks/repo-guard.json` and `.github/hooks/repo-guard.sh`, and drift measurement in `scripts/measure-intent-drift.sh`.

Agentic Execution records trajectory, cost, context, and hook data through `backstage/server/agent-api/middleware/trajectory.py`, `backstage/server/agent-api/middleware/cost_tracker.py`, and `backstage/server/agent-api/middleware/hooks.py`. The Foundry gateway enforces the same tool-use policy in `foundry/agents-service/app/tool_hooks.py`.

Runtime observability APIs include `/api/agents/trajectories`, `/api/agents/costs`, `/api/agents/context`, `/api/agents/hooks`, and `/api/agents/hooks/audit`.

## Golden Paths

When creating or modifying Golden Path templates:

- Follow Backstage template format.
- Include skeleton files.
- Include SDD artifacts from `golden-paths/common/templates/`.
- Add documentation.
- Test scaffolding locally before registration.

## Related Documentation

- [Deployment Guide](docs/guides/DEPLOYMENT_GUIDE.md)
- [Architecture Guide](docs/guides/ARCHITECTURE_GUIDE.md)
- [MCP Servers Usage](mcp-servers/USAGE.md)
- [Golden Paths](golden-paths/README.md)
- [Contributing](CONTRIBUTING.md)
