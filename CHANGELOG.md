# Changelog

All notable changes to the Open Horizons Platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.2.4] - 2026-05-07

### Security
- Re-enabled `yarn tsc` strict check in `release-images` workflow (removed 22 unused TS imports across 8 components).
- Added **cosign** keyless signing (sigstore) for every published container image.
- Added **CodeQL** workflow for JavaScript/TypeScript, Python, and GitHub Actions (`security-extended` queries + weekly schedule).
- Added **PR security scans** workflow: gitleaks, Trivy filesystem, Trivy IaC; SARIF uploaded to Security tab.
- Applied least-privilege top-level `permissions: contents: read` to 5 workflows that lacked them (agent-router, branch-protection, cd, issue-ops, validate-agents).
- Branch protection: enabled `enforce_admins`, required 6 status checks, kept code-owner reviews, dismiss-stale, linear history, conversation resolution.
- Enabled secret scanning + push protection + non-provider patterns + validity checks.

### Added
- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1).
- `release-images.yml` workflow: multi-arch (amd64+arm64) GHCR publish on every `vX.Y.Z` tag, with SBOM + SLSA provenance attestations and Trivy image scan.

### Changed
- All public-facing repository URLs updated from `Ohorizons/ohorizons-demo` to `Ohorizons/open-horizons-platform`.
- Default image tag in `install-wizard.sh` and Backstage catalogs bumped to `v7.2.4`.

### Published images (all public, multi-arch, signed)
- `ghcr.io/ohorizons/ohorizons-backstage:v7.2.4`
- `ghcr.io/ohorizons/ohorizons-agent-api:v7.2.4`
- `ghcr.io/ohorizons/ohorizons-agent-api-impact:v7.2.4`

## [7.2.2] - 2026-05-06

### Added
- Initial public release of `Ohorizons/open-horizons-platform` as the customer-facing forkable template.
- 34 Golden Paths (H1 Foundation, H2 Enhancement, H3 Innovation).
- 19 Copilot Chat Agents, 27 skills, 16 prompts, 8 instructions.
- 7 runtime agents (orchestrator, pipeline, sentinel, compass, guardian, lighthouse, forge).
- 12 MCP server tool files.
- 16 Terraform modules for Azure (AKS, networking, Key Vault, PostgreSQL, ACR, External Secrets, etc.).
- Backstage developer portal + ArgoCD GitOps + Prometheus/Grafana observability.
- Interactive `scripts/install-wizard.sh`.
- Full documentation under `docs/guides/` (Master Installation, Deployment, Wizard, Architecture, Troubleshooting, etc.).

## [Unreleased]

### Added
- Environment configuration files (dev, staging, prod tfvars)
- Helm values for ArgoCD and monitoring stack
- CHANGELOG.md for release tracking
- README files for all Terraform modules

### Changed
- Updated agent-router.yml with all 17 Copilot Chat Agents mapped
- Fixed soft_fail settings in CI workflow
- Updated documentation counts to reflect current state

### Fixed
- Security scans now properly block pipeline on vulnerabilities
- Missing outputs.tf for naming module

## [4.0.0] - 2025-12-15

### Added

#### Infrastructure (H1 Foundation)
- 18 Terraform modules for Azure infrastructure
  - aks-cluster: Azure Kubernetes Service with Workload Identity
  - ai-foundry: Azure AI Foundry (OpenAI, AI Search)
  - argocd: ArgoCD GitOps controller
  - container-registry: Azure Container Registry with geo-replication
  - cost-management: Cost analysis and budgets
  - databases: PostgreSQL, Redis, Cosmos DB
  - defender: Microsoft Defender for Cloud
  - disaster-recovery: Velero backup configuration
  - external-secrets: External Secrets Operator
  - github-runners: Self-hosted GitHub Actions runners
  - naming: Azure CAF naming conventions
  - networking: VNet, subnets, NSGs, private DNS
  - observability: Prometheus, Grafana, Loki, Alertmanager
  - purview: Microsoft Purview governance
  - backstage: Backstage Developer Portal
  - security: Key Vault, managed identities, RBAC

#### AI Agents (23 total)
- H1 Foundation (8 agents)
  - infrastructure-agent
  - networking-agent
  - security-agent
  - container-registry-agent
  - database-agent
  - defender-cloud-agent
  - purview-governance-agent

- H2 Enhancement (5 agents)
  - gitops-agent
  - golden-paths-agent
  - observability-agent
  - backstage-portal-agent
  - github-runners-agent

- H3 Innovation (4 agents)
  - ai-foundry-agent
  - mlops-pipeline-agent
  - sre-agent-setup
  - multi-agent-setup

- Cross-Cutting (6 agents)
  - migration-agent (v2.0.0 with Microsoft Playbook)
  - validation-agent
  - rollback-agent
  - cost-optimization-agent
  - github-app-agent
  - identity-federation-agent

#### Golden Path Templates (22 total)
- H1 Foundation (6 templates)
  - basic-cicd
  - documentation-site
  - infrastructure-provisioning
  - new-microservice
  - security-baseline
  - web-application

- H2 Enhancement (9 templates)
  - ado-to-github-migration (NEW - Microsoft Playbook aligned)
  - api-gateway
  - api-microservice
  - batch-job
  - data-pipeline
  - event-driven-microservice
  - gitops-deployment
  - microservice
  - reusable-workflows

- H3 Innovation (7 templates)
  - ai-evaluation-pipeline
  - copilot-extension
  - foundry-agent
  - mlops-pipeline
  - multi-agent-system
  - rag-application
  - sre-agent-integration

#### GitHub Configuration
- 28 Issue templates with T-shirt sizing
- 6 CI/CD workflows
- 3 Copilot chat modes (architect, reviewer, sre)
- 16 Copilot agents (onboarding, architect, platform, terraform, reviewer, devops, security, sre, test, docs, deploy)
- 16 skills (azure-cli, azure-infrastructure, terraform-cli, kubectl-cli, helm-cli, argocd-cli, github-cli, mcp-cli, database-management, observability-stack, ai-foundry-operations, validation-scripts, deploy-orchestration, prerequisites, backstage-deployment, codespaces-golden-paths)
- 3 instruction files (terraform, kubernetes, python)
- 7 prompts (create-service, review-code, generate-tests, deploy-service, deploy-platform, troubleshoot-incident, generate-docs)
- Branch protection workflow
- Dependabot configuration

#### Observability
- 3 Grafana dashboards
  - Platform overview
  - Golden path applications
  - Cost management
- 30+ Prometheus alerting rules
- Recording rules for SLO tracking

#### Documentation
- Comprehensive README
- Architecture Guide
- Deployment Guide
- Administrator Guide
- Troubleshooting Guide
- Module Reference
- Performance Tuning Guide
- 6 Operational Runbooks

#### Configuration
- 4 sizing profiles (small, medium, large, xlarge)
- LATAM region availability matrix
- 15 MCP server configurations

### Security
- OPA Gatekeeper policies
- Kubernetes constraints
- Terraform policy as code (Rego)
- Security scanning in CI/CD
- Workload Identity configuration

## [3.0.0] - 2025-06-01

### Added
- Initial Open Horizons architecture
- Basic Terraform modules
- ArgoCD integration
- Backstage portal setup

### Changed
- Migrated from Azure DevOps to GitHub

## [2.0.0] - 2025-01-15

### Added
- Azure infrastructure modules
- Basic CI/CD pipelines

## [1.0.0] - 2024-09-01

### Added
- Initial release
- Basic project structure

---

[Unreleased]: https://github.com/Ohorizons/agentic-devops-platform/compare/v4.0.0...HEAD
[4.0.0]: https://github.com/Ohorizons/agentic-devops-platform/releases/tag/v4.0.0
[3.0.0]: https://github.com/Ohorizons/agentic-devops-platform/releases/tag/v3.0.0
[2.0.0]: https://github.com/Ohorizons/agentic-devops-platform/releases/tag/v2.0.0
[1.0.0]: https://github.com/Ohorizons/agentic-devops-platform/releases/tag/v1.0.0
