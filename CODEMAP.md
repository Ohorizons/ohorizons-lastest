# Open Horizons — Code Map

> Program skeleton for AI agent comprehension. Updated: 2026-04-23.
> Ref: Ustynov (2026) Semantic Density Principle, arXiv:2604.07502.

## Architecture

```
5-Layer Stack:
  L1 Cloud/Infra     → terraform/modules/ (16 modules)
  L2 Platform Eng     → backstage/ + argocd/ + policies/ + golden-paths/
  L3 Context Eng      → mcp-servers/ + .github/skills/ + .github/agents/
  L4 Intent Eng       → CONSTITUTION.md + golden-paths/common/templates/
  L5 Agentic Exec     → backstage/server/agent-api*/ + .github/agents/
```

## Entry Points

| Surface | Entry | Port |
|---------|-------|------|
| Backstage portal | backstage/packages/app/ | 7007 |
| Agent API (AI Chat) | backstage/server/agent-api/main.py | 8008 |
| Agent API (AI Impact) | backstage/server/agent-api-impact/main.py | 8011 |
| Agent API (MAF) | backstage/server/agent-api-maf/main.py | 8012 |
| Agent API (SK) | backstage/server/agent-api-sk/main.py | 8013 |
| MCP Ecosystem Server | mcp-servers/src/index.ts | stdio |

## Agent API Core Flow

```
POST /api/agents/chat
  → router.detect_agent(message)     # @mention > keyword > orchestrator
  → TrajectoryMiddleware.before()    # log intent + context snapshot
  → CostTracker.start()             # begin token counting
  → BaseAgent.handle(message)        # agentic loop
    → Azure OpenAI chat.completions  # with tool definitions
    → tool_call? → execute_tool()    # GitHub API, Backstage MCP, etc.
    → loop until no tool_calls       # multi-step reasoning
  → CostTracker.finish()            # record token totals per agent
  → TrajectoryMiddleware.after()    # log outcome + trajectory
  → SSE stream to frontend          # type: agent|text|tool_use|tool_result|done
```

## Runtime Agents (7)

| Agent | Role | Tools |
|-------|------|-------|
| orchestrator | Default fallback | github_api, backstage_mcp |
| pipeline | CI/CD diagnostics | github_api (workflow_runs, jobs) |
| sentinel | Test coverage, quality gates | github_api (check_runs, suites) |
| compass | Sprint planning, stories | github_api (create_issue, search) |
| guardian | Security scanning | github_api (advisories, dependabot) |
| lighthouse | SRE, monitoring | github_api (deployments, envs) |
| forge | Infrastructure, repos | github_api (repos, branches) |

## Terraform Modules (16)

| Module | Layer | Purpose |
|--------|-------|---------|
| aks-cluster | L1 | AKS + Workload Identity + RBAC + Defender |
| networking | L1 | VNet, subnets, NSGs, private endpoints |
| container-registry | L1 | ACR with geo-replication |
| databases | L1 | PostgreSQL Flexible Server |
| security | L1 | Key Vault, managed identities |
| ai-foundry | L1 | Azure AI Foundry workspace |
| observability | L2 | Log Analytics, App Insights |
| argocd | L2 | ArgoCD Helm deployment |
| backstage | L2 | Backstage Helm values |
| cost-management | L2 | Budget alerts, cost tags |
| defender | L2 | Microsoft Defender for Cloud |
| disaster-recovery | L2 | Velero backup config |
| external-secrets | L2 | External Secrets Operator |
| github-runners | L2 | Self-hosted Actions runners |
| naming | L2 | Resource naming convention |
| purview | L2 | Data governance catalog |

## Golden Paths (34)

- **H1 (6):** basic-cicd, documentation-site, infrastructure-provisioning, new-microservice, security-baseline, web-application
- **H2 (10):** ado-to-github-migration, api-gateway, api-microservice, batch-job, data-pipeline, event-driven-microservice, gitops-deployment, microservice, reusable-workflows, todo-app
- **H3 (18):** 7 core AI + 11 MCP server templates

## Guardrails

- **K8s:** 6 Gatekeeper templates + 6 constraints (labels, resources, privileged, non-root, registries, latest-tag)
- **Terraform:** OPA/Conftest (tags, TLS, encryption, public access, RBAC, cost)
- **ArgoCD:** env-specific sync (dev=auto, staging=gated, prod=manual)

## Key Config Files

| File | Purpose |
|------|---------|
| .github/copilot-instructions.md | Tier 1 hot memory (always loaded) |
| AGENTS.md | Agent system docs (18 agents, 27 skills, 16 prompts) |
| backstage/server/agent-api/CONSTITUTION.md | Agent intent artifact |
| .github/model-routing.yaml | SDLC model routing config |
| argocd/sync-policies.yaml | GitOps sync policy presets |
