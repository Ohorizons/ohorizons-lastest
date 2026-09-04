# Golden Paths Templates

> **A solution created in partnership with Microsoft and GitHub**

This directory contains self-service templates for Backstage that enable developers to quickly scaffold new projects following platform standards.

## Directory Structure

```
open-horizons-templates/
├── h1-foundation/           # Foundation templates (7)
├── h2-enhancement/          # Enhancement templates (10)
├── h3-innovation/           # Innovation templates (18)
├── common/
│   ├── azure-infrastructure/   # Shared Azure deployment baseline
│   └── primitives/             # One Copilot primitive bundle per template
│       ├── profiles.json       # The per-template selection contract
│       ├── _local-agents/      # Open Horizons agents authored here
│       ├── _local-skills/      # Open Horizons skills authored here
│       └── <template>/         # static/ (verbatim) + context/ (rendered)
├── contracts/
│   └── scaffolder-actions.json # Actions the portal backend registers
└── scripts/                    # Catalog gates and generators
```

## Copilot primitives

Every template installs a Copilot primitive bundle into the repository it
generates. The bundles are **not interchangeable**: a Terraform template and an
MCP server template need different agents, skills, and instructions, and a
bundle that serves both equally serves neither well.

`common/primitives/profiles.json` is the contract. It declares an immutable pin
to the primitive source, a small universal base, and one context-specific
profile per template.

| Profile field | Meaning |
| --- | --- |
| `context` | What the generated repository is for. |
| `stack` | The technologies the primitives are selected against. |
| `agents`, `skills`, `instructions`, `prompts`, `hooks` | Additions on top of the base. |
| `delivery` | `control-plane` when the AEG installs the bundle instead of the scaffolder. |

Each profile is materialised into `common/primitives/<template>/`:

| Directory | Fetched with | Why |
| --- | --- | --- |
| `static/` | `fetch:plain` | Primitive documents contain `{{ ... }}` examples, so they must never pass through the templating engine. |
| `context/` | `fetch:template` | `AGENTS.md` and `.github/copilot-instructions.md` carry the generated repository's own name and owner. |

A generated repository therefore receives `.github/agents/`, `.github/skills/`,
`.github/instructions/`, `.github/prompts/`, `.github/hooks/`,
`.github/scripts/`, `.github/harness/`, `.github/copilot-instructions.md`, and
`AGENTS.md`, plus a `validate-primitives.py` it can run itself.

```bash
python3 scripts/build-primitives.py --check   # offline: completeness and drift
python3 scripts/build-primitives.py --build   # re-vendor from the pinned commit
```

## Catalog gates

| Command | What it proves |
| --- | --- |
| `./scripts/validate-scaffolder-templates.sh` | Action inputs match the schemas the backend accepts. |
| `python3 scripts/validate-templates.py` | Every template exists, parses, and its fetch sources resolve. |
| `node scripts/validate-template-language.js` | Every template **compiles and renders** with the Nunjucks configuration Backstage uses. |
| `python3 scripts/build-primitives.py --check` | Every template ships a complete bundle and actually fetches it. |
| `python3 scripts/validate-generated-infrastructure.py` | The rendered Terraform and Bicep initialise, validate, and build. |
| `python3 -m unittest discover -s tests -t .` | Each gate detects its own regression. |

## Template Categories

### H1 Foundation (7 templates)

Basic infrastructure and application templates:

| Template | Description |
|----------|-------------|
| `aeg-application` | Governed AEG application delivery |
| `basic-cicd` | Simple CI/CD pipeline |
| `documentation-site` | Documentation websites |
| `infrastructure-provisioning` | Terraform module scaffolding |
| `new-microservice` | Basic microservice starter |
| `security-baseline` | Security configuration |
| `web-application` | Full-stack web applications |

### H2 Enhancement (10 templates)

Advanced application patterns:

| Template | Description |
|----------|-------------|
| `ado-to-github-migration` | Azure DevOps to GitHub migration (Microsoft Playbook) |
| `api-gateway` | API Management configuration |
| `api-microservice` | RESTful API service |
| `batch-job` | Scheduled batch processing |
| `data-pipeline` | ETL with Databricks |
| `event-driven-microservice` | Event Hubs/Service Bus integration |
| `gitops-deployment` | ArgoCD application |
| `microservice` | Complete microservice with all features |
| `reusable-workflows` | GitHub Actions workflow library |

### H3 Innovation (18 templates)

AI/ML and advanced automation:

| Template | Description |
|----------|-------------|
| `ai-evaluation-pipeline` | Model evaluation framework |
| `copilot-extension` | GitHub Copilot extensions |
| `foundry-agent` | Azure AI Foundry agents |
| `mlops-pipeline` | Complete ML pipeline |
| `multi-agent-system` | Multi-agent orchestration |
| `rag-application` | RAG applications |
| `sre-agent-integration` | SRE automation |

## Template Structure

Each template contains:

```
template-name/
├── template.yaml          # Backstage scaffolder template
├── skeleton/              # Template files
│   ├── catalog-info.yaml  # Backstage catalog entry
│   ├── .github/           # GitHub workflows
│   └── src/               # Application source
└── README.md              # Template documentation
```

## Using Templates

> **End users (developers and tech leads):** Read the [Wizard Guide](../docs/guides/WIZARD_GUIDE.md) for the full step-by-step walkthrough of every wizard option, what gets generated, and how to activate the new repository.
>
> **Client operators installing the platform:** Read the [Client Installation Guide](../docs/guides/CLIENT_INSTALLATION.md).

### Azure Deployment Toggle

32 of the 34 templates expose a wizard parameter named `Provision Azure Infrastructure` (`deployToAzure`, default `true`). When checked, the generated repository receives:

- `deploy/azure/main.bicep` — Log Analytics, Application Insights, Storage baseline.
- `.github/workflows/azure-infrastructure.yml` — `what-if` and `apply` modes via OIDC.
- `scripts/setup-azure-oidc.sh` — One-time OIDC + secret bootstrap.

Templates `infrastructure-provisioning` and `rag-application` always provision Azure (their value proposition is the infrastructure itself) and therefore do not expose the toggle. See [Azure OIDC Setup](common/azure-infrastructure/docs/azure-oidc.md) for the helper script and the federated credentials it configures.

### Via Backstage Portal

1. Navigate to the Backstage portal
2. Click "Create" → "Choose a Template"
3. Select the desired template
4. Fill in the parameters
5. Review and create

### Via Backstage CLI

```bash
# Install Backstage CLI
npm install -g @backstage/cli

# Scaffold from template
backstage-cli create \
  --template golden-paths/h2-enhancement/microservice \
  --values name=my-service,owner=my-team
```

## Template Parameters

Common parameters across templates:

| Parameter | Description | Required |
|-----------|-------------|----------|
| `name` | Project/service name | Yes |
| `owner` | Team or owner | Yes |
| `description` | Project description | No |
| `repoUrl` | Repository URL | Yes |
| `system` | Parent system | No |

## Creating New Templates

### 1. Create Directory Structure

```bash
mkdir -p golden-paths/h2-enhancement/my-template/skeleton
```

### 2. Create template.yaml

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: my-template
  title: My Template
  description: Description of what this template creates
  tags:
    - recommended
    - python
spec:
  owner: platform-team
  type: service

  parameters:
    - title: Service Information
      required:
        - name
        - owner
      properties:
        name:
          title: Name
          type: string
          description: Service name
        owner:
          title: Owner
          type: string
          ui:field: OwnerPicker

  steps:
    - id: fetch
      name: Fetch Template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}

    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        repoUrl: ${{ parameters.repoUrl }}

    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: /catalog-info.yaml

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
```

### 3. Create Skeleton Files

Add template files in `skeleton/` using Nunjucks syntax:

```yaml
# skeleton/catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: ${{ values.name }}
  annotations:
    github.com/project-slug: ${{ values.repoUrl | replace("https://github.com/", "") }}
spec:
  type: service
  lifecycle: experimental
  owner: ${{ values.owner }}
```

## Validation

### Validate Template Syntax

```bash
# Run agent validation
./scripts/validate-agents.sh

# Check YAML syntax
yamllint golden-paths/
```

### Test Template Locally

```bash
# Use Backstage development server
cd backstage
yarn dev

# Navigate to /create and test template
```

## Related Documentation

- [Platform Agent](../.github/agents/platform.agent.md)
- [DevOps Agent](../.github/agents/devops.agent.md)
- [Backstage Scaffolder](https://backstage.io/docs/features/software-templates/)
