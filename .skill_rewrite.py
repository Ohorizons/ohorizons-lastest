from pathlib import Path
root = Path('.github/skills')
files = {}
files['helm-cli'] = '''---
name: helm-cli
description: "Use when managing Helm packages for Kubernetes: repo add/update, template rendering, chart linting, install, upgrade, rollback, uninstall, and release inspection. Produces validated Helm commands, rendered manifests, release status, and rollback guidance. DO NOT USE FOR: kubectl operations (use kubectl-cli), ArgoCD sync (use argocd-cli), Terraform IaC (use terraform-cli). Triggers include \"install this Helm chart\", \"upgrade the monitoring release\", \"rollback a Helm release\", and \"lint these Helm values\"."
---

# Helm CLI

Use this skill to operate Helm charts for Open Horizons Kubernetes services, especially monitoring values in `deploy/helm/monitoring/values.yaml` and other chart values under `deploy/helm/`. It produces a safe command plan, dry-run output, release status, and the exact command to run after approval.

> [!NOTE]
> This skill depends on the `helm` CLI, `kubectl` access to the target AKS or kind cluster, configured Kubernetes credentials, and authenticated chart registry access when private charts are used. It does not use an MCP server by default.

## When to invoke

- "Install the kube-prometheus-stack chart with our repo values."
- "Upgrade the monitoring Helm release in the monitoring namespace."
- "Rollback the last Helm upgrade because Grafana is unhealthy."
- "Render the Helm templates before we deploy."
- "Check which Helm releases are installed in the cluster."

## Prerequisites

- `helm version` succeeds with Helm 3.x.
- `kubectl config current-context` points to the intended cluster.
- The target namespace is known and exists, or the user approved namespace creation.
- Values files exist, for example `deploy/helm/monitoring/values.yaml`.
- For external charts, the chart repository URL is known and reachable.

## Workflow steps

### Step 1: Confirm scope and current state

1. Identify the release name, namespace, chart, and values file.
2. Show the active cluster and namespace before any change:

```bash
kubectl config current-context
helm list -A
```

3. For monitoring work, verify the repo values file exists:

```bash
test -f deploy/helm/monitoring/values.yaml
```

### Step 2: Prepare chart repositories

Use explicit repository names and URLs. Keep repository setup separate from release mutation.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo prometheus-community/kube-prometheus-stack
```

### Step 3: Validate and render before mutation

Render templates and lint the chart or local chart path before install or upgrade.

```bash
helm lint prometheus-community/kube-prometheus-stack --values deploy/helm/monitoring/values.yaml
helm template monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values deploy/helm/monitoring/values.yaml
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values deploy/helm/monitoring/values.yaml \
  --dry-run
```

### Step 4: Classify release risk

| Risk | Meaning |
| --- | --- |
| High | Uninstall, rollback across major chart versions, CRD changes, or production namespace mutation. |
| Medium | Upgrade or install with persistent volumes, ingress, RBAC, or service account changes. |
| Low | Repository update, list, status, history, lint, template, or dry-run only. |

### Step 5: User confirmation gate

```text
Helm action: <install|upgrade|rollback|uninstall>
Release: <release>
Namespace: <namespace>
Cluster context: <context>
Values: deploy/helm/monitoring/values.yaml
Risk: <High|Medium|Low>
Proceed with the Helm mutation? (y/n)
```

> [!IMPORTANT]
> Only run `helm install`, `helm upgrade`, `helm rollback`, or `helm uninstall` after an explicit affirmative response. On a negative, ambiguous, or missing response, do not mutate the cluster; output the dry-run findings and stop.

### Step 6: Execute the approved operation

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values deploy/helm/monitoring/values.yaml \
  --wait --timeout 15m
```

For rollback, inspect history first and then run only the approved revision.

```bash
helm history monitoring --namespace monitoring
helm rollback monitoring <revision> --namespace monitoring --wait --timeout 10m
```

### Step 7: Verify release health

```bash
helm status monitoring --namespace monitoring
kubectl get pods -n monitoring
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

## Error handling

| Situation | Action |
| --- | --- |
| Helm repo is unreachable | Stop before mutation and report the failed URL and command output. |
| Values file is missing | Ask for the correct values path; do not substitute a default. |
| Dry-run fails | Report the template or schema error and skip mutation. |
| Release is stuck pending | Run `helm status`, `helm history`, and namespace events; recommend rollback only after approval. |
| Namespace is missing | Include `--create-namespace` only when the user approves namespace creation. |

## Output template

```markdown
## Helm Operation Report

**Release:** <release>
**Namespace:** <namespace>
**Cluster context:** <context>
**Action:** <lint|template|install|upgrade|rollback|uninstall>
**Risk:** <High|Medium|Low>

### Commands Run
- `<command>`

### Validation
- Lint: <passed|failed|not run>
- Dry-run: <passed|failed|not run>
- Release status: <status>

### Findings
- <finding>

### Next Steps
1. <next step>
```

## Quality gate

- [ ] Confirmed cluster context before any mutation.
- [ ] Verified every referenced values file exists.
- [ ] Ran `helm lint` or documented why lint was not applicable.
- [ ] Ran `helm template` or `helm upgrade --install --dry-run` before mutation.
- [ ] Received explicit approval before install, upgrade, rollback, or uninstall.
- [ ] Verified release status and pod health after approved mutation.
'''
files['issue-ops'] = '''---
name: issue-ops
description: "Use when dispatching GitHub Issue slash commands through the IssueOps workflow, validating dispatcher mappings, or explaining /validate and /check-agents automation. Produces a command safety review, dispatcher execution plan, and GitHub issue comment output. DO NOT USE FOR: manual script execution (use validation-scripts), Backstage deployment (use backstage-deployment), full platform deployment (use deploy-orchestration). Triggers include \"run /validate from an issue\", \"dispatch this slash command\", \"check the IssueOps mapping\", and \"why did /check-agents fail\"."
---

# Issue Ops

Use this skill to operate the repository's IssueOps dispatcher, which maps slash commands in GitHub issue comments to approved automation through `.github/workflows/issue-ops.yml` and `.github/skills/issue-ops/dispatcher.py`. It produces a command review, a safe dispatch decision, and the expected issue comment result.

> [!NOTE]
> This skill depends on GitHub Actions, the `gh` CLI for inspection, repository write permissions for issue comments, and the local dispatcher `.github/skills/issue-ops/dispatcher.py`. It does not require a separate MCP server.

## When to invoke

- "Run /validate on this deployment issue."
- "Explain why the IssueOps slash command failed."
- "Check whether /check-agents is safe to dispatch."
- "Validate the IssueOps workflow before we use it."
- "Show the output that the dispatcher will post back to the issue."

## Prerequisites

- `.github/workflows/issue-ops.yml` exists and listens for issue comments that start with `/`.
- `.github/skills/issue-ops/dispatcher.py` exists and contains the active `COMMAND_MAP`.
- The mapped script in `COMMAND_MAP` exists before dispatch; if it does not exist, the dispatcher must fail safely.
- `gh auth status` succeeds when inspecting issues or workflow runs.
- The target issue and repository are known.

## Workflow steps

### Step 1: Identify the requested command

1. Read only the first slash-command line from the issue body or comment.
2. Confirm it is one of the dispatcher-supported commands in `.github/skills/issue-ops/dispatcher.py`.
3. Reject commands with shell chaining, command substitution, redirection, or unapproved flags.

```bash
python3 .github/skills/issue-ops/dispatcher.py
```

Run the dispatcher only through the workflow or with controlled `ISSUE_BODY` in a safe local check.

### Step 2: Verify workflow and script anchors

```bash
test -f .github/workflows/issue-ops.yml
test -f .github/skills/issue-ops/dispatcher.py
test -f .github/skills/validation-scripts/scripts/validate-deployment.sh
test -f .github/skills/validation-scripts/scripts/validate-agents.py
```

### Step 3: Classify command risk

| Risk | Meaning |
| --- | --- |
| High | Command can create, update, or comment on GitHub artifacts, or can trigger deployment validation against live infrastructure. |
| Medium | Command reads live workflow, cluster, or deployment state and posts summarized output. |
| Low | Local parser inspection or dry-run analysis with no GitHub or infrastructure side effects. |

### Step 4: User confirmation gate

```text
IssueOps command: <slash command>
Repository: <owner>/<repo>
Issue: #<number>
Mapped dispatcher: .github/skills/issue-ops/dispatcher.py
Risk: <High|Medium|Low>
Proceed with dispatching and posting the result to GitHub? (y/n)
```

> [!IMPORTANT]
> Only dispatch IssueOps commands or post GitHub comments after an explicit affirmative response. On a negative, ambiguous, or missing response, do not dispatch; output the planned command and stop.

### Step 5: Dispatch through GitHub Actions

Use the workflow path as the authoritative execution surface. Inspect workflow runs and logs with `gh`.

```bash
gh run list --workflow issue-ops.yml --limit 10
gh run view <run-id> --log-failed
```

### Step 6: Verify result comment and failures

1. Confirm the workflow posted a result comment to the issue.
2. If the dispatcher reports `Script not found`, treat the command as safely rejected.
3. If validation failed, hand off remediation to `validation-scripts`, `kubectl-cli`, or `pipeline-diagnostics` based on the failing command output.

## Error handling

| Situation | Action |
| --- | --- |
| Unknown slash command | Return the supported commands from `COMMAND_MAP`; do not execute anything. |
| Mapped script is missing | Report the missing path from dispatcher output and stop. |
| Arguments contain unsafe shell syntax | Reject the command and ask for plain flags or values. |
| GitHub authentication fails | Ask the operator to run `gh auth login` or configure workflow permissions. |
| Workflow run fails | Use `gh run view <run-id> --log-failed` and summarize the failing step. |

## Output template

```markdown
## IssueOps Dispatch Report

**Repository:** <owner>/<repo>
**Issue:** #<number>
**Command:** `<slash command>`
**Risk:** <High|Medium|Low>

### Dispatcher Mapping
- Dispatcher: `.github/skills/issue-ops/dispatcher.py`
- Workflow: `.github/workflows/issue-ops.yml`
- Mapped script exists: <yes|no>

### Execution Result
- Workflow run: <id or not run>
- Status: <success|failure|blocked>
- Posted comment: <yes|no>

### Findings
- <finding>
```

## Quality gate

- [ ] Confirmed the command is in `.github/skills/issue-ops/dispatcher.py`.
- [ ] Verified mapped script existence before dispatch or documented safe rejection.
- [ ] Rejected unsafe shell syntax in arguments.
- [ ] Received explicit approval before dispatching or posting comments.
- [ ] Reviewed workflow logs for failed dispatches.
'''
files['kubectl-cli'] = '''---
name: kubectl-cli
description: "Use when operating Kubernetes resources on AKS or kind with kubectl: get, describe, logs, events, diff, dry-run, apply, delete, rollout, and namespace troubleshooting. Produces command plans, cluster evidence, health summaries, and remediation steps. DO NOT USE FOR: Helm charts (use helm-cli), ArgoCD sync (use argocd-cli), Azure resource provisioning (use azure-cli). Triggers include \"check pod health\", \"apply these Kubernetes manifests\", \"delete this resource\", and \"debug the Backstage deployment\"."
---

# Kubectl CLI

Use this skill for direct Kubernetes inspection and carefully approved resource changes in Open Horizons namespaces and manifests such as `backstage/k8s/`, `argocd/apps/`, and `foundry/k8s/`. It produces cluster evidence, a risk-ranked action plan, and post-change verification.

> [!NOTE]
> This skill depends on `kubectl`, a valid `KUBECONFIG`, `kubelogin` for Azure AKS authentication when applicable, and RBAC permissions for the target namespace. It does not use an MCP server by default.

## When to invoke

- "Check whether Backstage pods are healthy."
- "Apply the manifests under backstage/k8s."
- "Delete a failed Kubernetes job after confirming the namespace."
- "Show events for the monitoring namespace."
- "Debug image pull errors in the ai-services namespace."

## Prerequisites

- `kubectl version --client` succeeds.
- `kubectl config current-context` shows the intended AKS or kind cluster.
- The namespace is explicit for namespace-scoped resources.
- Manifest paths exist, for example `backstage/k8s/agent-identity.yaml`.
- The user has approved any apply, delete, scale, patch, or rollout restart action.

## Workflow steps

### Step 1: Confirm context and namespace

```bash
kubectl config current-context
kubectl get namespaces
kubectl get nodes -o wide
```

Never assume the namespace. If the user did not provide one, inspect likely Open Horizons namespaces and ask for confirmation before mutation.

### Step 2: Inspect current resource health

```bash
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
kubectl get pods -n backstage -o wide
kubectl get events -n backstage --sort-by='.lastTimestamp'
kubectl describe deployment -n backstage backstage
```

Use logs only for the named pod or label selector.

```bash
kubectl logs -n backstage deployment/backstage --tail=100
kubectl logs -n ai-services deployment/agent-api --tail=100
```

### Step 3: Validate manifests before mutation

```bash
kubectl apply -f backstage/k8s/ --dry-run=client -o yaml
kubectl diff -f backstage/k8s/
```

For generated manifests, render them first with the repo script and then inspect the output path produced by the script.

```bash
./scripts/render-k8s.sh
```

### Step 4: Classify Kubernetes risk

| Risk | Meaning |
| --- | --- |
| High | `delete`, `patch`, `scale`, `rollout restart`, namespace changes, or apply to production. |
| Medium | `apply` to non-production, changes to RBAC, NetworkPolicy, ServiceAccount, or ingress. |
| Low | `get`, `describe`, `logs`, `events`, `top`, `diff`, or client dry-run. |

### Step 5: User confirmation gate

```text
Kubernetes action: <apply|delete|patch|scale|rollout restart>
Cluster context: <context>
Namespace: <namespace>
Manifest or resource: <path-or-kind/name>
Risk: <High|Medium|Low>
Proceed with the Kubernetes mutation? (y/n)
```

> [!IMPORTANT]
> Only run mutating `kubectl` commands after an explicit affirmative response. On a negative, ambiguous, or missing response, do not mutate the cluster; output the dry-run or diff findings and stop.

### Step 6: Execute the approved action

```bash
kubectl apply -f backstage/k8s/ --server-side
kubectl rollout status deployment/backstage -n backstage --timeout=300s
```

For deletion, use an exact resource identity and namespace.

```bash
kubectl delete <kind>/<name> -n <namespace> --grace-period=30
```

### Step 7: Verify after mutation

```bash
kubectl get all -n backstage -o wide
kubectl get events -n backstage --sort-by='.lastTimestamp'
kubectl rollout status deployment/backstage -n backstage --timeout=300s
```

## Error handling

| Situation | Action |
| --- | --- |
| No current context | Stop and ask the operator to configure AKS credentials. |
| Namespace not found | List namespaces and require explicit namespace selection before mutation. |
| Dry-run or diff fails | Report validation errors and skip mutation. |
| RBAC forbidden | Report required verb, resource, and namespace from the error. |
| Pods crash after apply | Collect `describe`, previous logs, and events; do not auto-delete resources. |

## Output template

```markdown
## Kubectl Operation Report

**Cluster context:** <context>
**Namespace:** <namespace>
**Action:** <get|describe|logs|diff|apply|delete>
**Risk:** <High|Medium|Low>

### Evidence
- Pods: <summary>
- Events: <summary>
- Rollout: <summary>

### Commands Run
- `<command>`

### Findings
- <finding>

### Next Steps
1. <next step>
```

## Quality gate

- [ ] Confirmed current Kubernetes context.
- [ ] Used explicit namespace for namespace-scoped resources.
- [ ] Verified manifest paths exist before referencing them.
- [ ] Ran dry-run or diff before apply.
- [ ] Received explicit approval before any mutating command.
- [ ] Verified rollout, pods, and events after mutation.
'''
# continuing in appended file for remaining skills
files['markdown-writer'] = '''---
name: markdown-writer
description: "Use when creating or restructuring Markdown documents such as README, ADR, specification, guide, changelog, runbook, RFC, technical documentation, or PPTX/PowerPoint-to-Markdown reading editions. Produces Markdown with YAML frontmatter, versioning, change log, table of contents, references, and quality checks. DO NOT USE FOR: editable draw.io/SVG architecture diagrams with official icons (use azure-architecture-diagrams), Mermaid architecture document validation/Definition-of-Done checks (use architecture-doc), creating PPTX presentations, Word documents, PDFs, or image-only diagrams. Triggers include \"write a README\", \"create an ADR\", \"draft a guide\", and \"convert PPTX to Markdown\"."
---

# Markdown Writer

Use this skill to create professional Markdown deliverables in English with stable structure, metadata, readable prose, and repository-aware file placement. It produces a complete document draft or rewrite, plus a quality report for frontmatter, headings, links, code fences, and references.

> [!NOTE]
> This skill depends on file-system write access for requested Markdown outputs and, for PowerPoint conversion, `markitdown` or an available MarkItDown MCP tool. It does not require cloud authentication unless the source material is stored behind an authenticated service.

## When to invoke

- "Write a README for this component."
- "Create an ADR for this architecture decision."
- "Draft a deployment guide in Markdown."
- "Convert this PowerPoint deck into a Markdown reading edition."
- "Rewrite this runbook with a table of contents and references."

## Prerequisites

- The document type is known: README, ADR, specification, guide, changelog, runbook, RFC, or general technical document.
- The destination path is known or can be inferred from existing repository conventions such as `docs/`, `docs/guides/`, or `docs/architecture/`.
- Source material is available in the workspace or provided by the user.
- For PPTX conversion, the source deck path exists and speaker notes are preserved when the converter exposes them.

## Workflow steps

### Step 1: Confirm document intent and destination

1. Identify audience, purpose, status, owner, and expected output path.
2. Inspect nearby documents under `docs/`, `docs/guides/`, and `docs/architecture/` for naming and structure conventions.
3. Do not create a new planning file unless the user requested a document artifact.

### Step 2: Select the document structure

Use one of these structures and avoid placeholder sections.

| Document type | Required sections |
| --- | --- |
| README | Overview, Quick Start, Prerequisites, Installation, Usage, Configuration, Contributing, License. |
| ADR | Status, Context, Decision, Consequences, References. |
| Specification | Overview, Scope, Requirements, Design, Security, Testing, References. |
| Guide | Overview, Prerequisites, Step-by-step Instructions, Troubleshooting, References. |
| Runbook | Overview, Symptoms, Diagnosis, Resolution, Prevention, Escalation, References. |

### Step 3: Write mandatory frontmatter

```yaml
---
title: "Document Title"
description: "One-sentence summary of the document purpose."
author: "Open Horizons"
date: "YYYY-MM-DD"
version: "1.0.0"
status: "draft"
tags: ["open-horizons"]
---
```

### Step 4: Build the Markdown body

- Use exactly one `#` H1.
- Include a change log for versioned documents.
- Include a table of contents for documents with more than three major sections.
- Keep paragraphs under four sentences.
- Use descriptive links and a `## References` section.
- Specify a language on every fenced code block.

### Step 5: Convert PPTX decks when requested

1. Use MarkItDown first when available.
2. Treat raw extraction as source material, not final output.
3. Preserve every slide in order, including speaker notes.
4. Remove extraction noise such as image placeholders, repeated headers, and page numbers.
5. Render each slide as readable prose with a short `Shown on the slide:` list only when useful.

### Step 6: Classify document risk

| Risk | Meaning |
| --- | --- |
| High | Public-facing, compliance, security, architecture, or release documentation. |
| Medium | Team guide, runbook, specification, or ADR with operational impact. |
| Low | Internal draft, formatting-only rewrite, or local conversion. |

### Step 7: Review and save

Before writing, confirm overwrite intent if the target file already exists. For new files, use the repository's existing documentation tree, not an ad hoc location.

## Error handling

| Situation | Action |
| --- | --- |
| Destination path is unclear | Propose the closest existing docs directory and wait for direction if multiple choices exist. |
| Source PPTX cannot be parsed | Report the converter error and preserve any partial extracted text separately in the response only. |
| Existing document would be overwritten | Ask for explicit overwrite approval or choose a new filename. |
| Missing source references | Mark claims as assumptions or omit them. |
| Broken internal link | Fix the link if the target exists; otherwise report it in the quality section. |

## Output template

```markdown
## Markdown Delivery Report

**Document:** <title>
**Type:** <README|ADR|Guide|Runbook|Specification|Other>
**Path:** <path>
**Status:** <draft|review|approved>

### Structure
- Frontmatter: <present|missing>
- H1 count: <count>
- Table of contents: <present|not needed|missing>
- References: <present|missing>

### Quality Findings
- <finding>

### Next Steps
1. <next step>
```

## Quality gate

- [ ] YAML frontmatter includes title, description, author, date, version, status, and tags.
- [ ] Exactly one H1 is present.
- [ ] Heading levels do not skip.
- [ ] Table of contents is present when needed.
- [ ] Code fences specify a language.
- [ ] Links are descriptive and references are cited.
- [ ] No placeholder text remains.
- [ ] No emojis or pictographs are present.
'''
files['mcp-ecosystem'] = '''---
name: mcp-ecosystem
description: "Use when querying the local MCP Ecosystem reference server for live upstream documentation, methodology, templates, Backstage resources, GitHub Copilot customization, Microsoft Learn, Azure CAF/WAF, VS Code docs, GitHub docs, Anthropic docs, or SDD/spec-kit guidance. Produces sourced reference lookups, tool selection, server health checks, and AI Chat wiring guidance. DO NOT USE FOR: general web search, live cloud or repository operations, infra MCP servers such as Azure/GitHub/Terraform/Kubernetes/Helm, or non-reference queries. Triggers include \"search Microsoft Learn through MCP\", \"use the ecosystem server\", \"ground this in Backstage docs\", and \"list MCP ecosystem tools\"."
---

# MCP Ecosystem

Use this skill to operate the Open Horizons local MCP Ecosystem reference server implemented in `mcp-servers/src/tools/`. The server exposes 79 documentation tools across 17 modules and helps agents ground SDD, Backstage, GitHub, Microsoft Learn, Azure CAF/WAF, VS Code, and Anthropic answers in upstream sources.

> [!NOTE]
> This skill depends on the MCP Ecosystem server at `http://localhost:3100/mcp`, Node.js, Docker when using `mcp-servers/` local compose workflows, optional `GH_TOKEN` for higher GitHub API limits, and `.github/mcp.json` registration. It does not perform live cloud mutations.

## When to invoke

- "Search Microsoft Learn through the MCP Ecosystem server."
- "Ground this Backstage template answer in official docs."
- "List the tools exposed by mcp-ecosystem."
- "Check whether AI Chat can call the ecosystem tools."
- "Use spec-kit methodology from the local MCP server."

## Prerequisites

- `mcp-servers/src/tools/` exists and contains the registered tool modules.
- `.github/mcp.json` includes `mcp-ecosystem` with URL `http://localhost:3100/mcp`.
- For local runtime, `mcp-servers/README.md`, `mcp-servers/USAGE.md`, and `mcp-servers/ARCHITECTURE.md` exist.
- Optional `GH_TOKEN` is configured when GitHub-backed documentation tools need higher rate limits.
- The query is a reference/documentation task, not a cloud operation.

## Workflow steps

### Step 1: Confirm this is a reference lookup

Use this server for documentation and methodology. Do not use it for Azure, GitHub, Terraform, Kubernetes, or Helm operations that need live state.

### Step 2: Verify server registration and health

```bash
test -f .github/mcp.json
test -d mcp-servers/src/tools
curl -s http://localhost:3100/health
```

If the server is not running locally, use the repo's documented workflow.

```bash
cd mcp-servers
make up
make health
```

### Step 3: Select the narrowest tool family

| Need | Tool family |
| --- | --- |
| SDD and spec-kit | `speckit_*` |
| Backstage docs, catalog, templates, plugins, UI | `backstagedocs_*`, `backstageplugins_*`, `backstageui_*` |
| Microsoft Learn, CAF, WAF | `mslearn_*`, `caf_*`, `waf_*` |
| GitHub docs and Copilot customization | `ghdocs_*`, `copilotdocs_*` |
| VS Code docs | `vscode_*` |
| Anthropic and Claude docs | `anthropicdocs_*`, `anthropics_*` |

### Step 4: Call list or search before fetching a page

List all tools with JSON-RPC over HTTP.

```bash
curl -s http://localhost:3100/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

Call a specific tool only after selecting the narrowest match.

```bash
curl -s http://localhost:3100/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"speckit_get_phases","arguments":{}}}'
```

### Step 5: Classify reference confidence

| Confidence | Meaning |
| --- | --- |
| High | Fetched directly from an official upstream source through a targeted ecosystem tool. |
| Medium | Search result snippet from an official source that needs a follow-up fetch. |
| Low | Server unavailable, stale cache, or query answered without ecosystem grounding. |

### Step 6: Wire AI Chat only with existing anchors

Use the existing client at `backstage/server/agent-api/tools/mcp_ecosystem.py`. In-cluster runtime uses the `mcp-ecosystem` service described in `mcp-servers/ARCHITECTURE.md`.

## Error handling

| Situation | Action |
| --- | --- |
| Server health check fails | Start with `cd mcp-servers && make up`, then rerun `make health`. |
| Tool is not found | Call `tools/list` and select an available tool; do not invent tool names. |
| GitHub rate limit is hit | Set `GH_TOKEN` and retry after cache or rate-limit recovery. |
| Cache may be stale | Report cache staleness and fetch the specific page again when possible. |
| Query needs live infrastructure state | Stop and route to the appropriate CLI skill instead. |

## Output template

```markdown
## MCP Ecosystem Lookup Report

**Query:** <query>
**Server:** `http://localhost:3100/mcp`
**Tools used:** <tool names>
**Confidence:** <High|Medium|Low>

### Sources
- <source URL or tool result reference>

### Answer
<grounded answer>

### Gaps
- <missing source or follow-up>
```

## Quality gate

- [ ] Confirmed the task is reference lookup, not live operations.
- [ ] Verified `.github/mcp.json` and `mcp-servers/src/tools/` anchors.
- [ ] Used `tools/list` when the exact tool was unclear.
- [ ] Cited official upstream sources returned by the tool.
- [ ] Reported cache or server availability limitations.
- [ ] Kept counts aligned with source: 17 modules and 79 tools.
'''
files['observability-stack'] = '''---
name: observability-stack
description: "Use when deploying or operating the Open Horizons observability stack: Prometheus, Grafana, Alertmanager, Loki-adjacent logging checks, dashboards, service monitors, alert rules, and day-2 monitoring diagnostics. Produces deployment plans, Helm/Kubernetes commands, dashboard and alert validation, and health reports. DO NOT USE FOR: application logging code, Terraform IaC (use terraform-cli), CI/CD pipelines (use deploy-orchestration). Triggers include \"deploy monitoring\", \"configure Grafana dashboards\", \"check Prometheus targets\", and \"troubleshoot alerts\"."
---

# Observability Stack

Use this skill to deploy, validate, and troubleshoot Open Horizons monitoring assets using `deploy/helm/monitoring/values.yaml`, `deploy/helm/service-monitors.yaml`, `deploy/helm/sre-alerts.yaml`, `grafana/dashboards/`, and `terraform/modules/observability/`. It produces a risk-ranked plan, approved commands, and a health report.

> [!NOTE]
> This skill depends on `kubectl`, `helm`, cluster credentials, access to the monitoring namespace, and Grafana or Prometheus credentials from the approved secret store. It does not use an MCP server by default.

## When to invoke

- "Deploy the observability stack to the cluster."
- "Check whether Prometheus targets are healthy."
- "Load the dashboards from grafana/dashboards."
- "Validate the SRE alert rules."
- "Troubleshoot why Grafana is not reachable."

## Prerequisites

- `kubectl config current-context` points to the intended cluster.
- `helm version` succeeds.
- `deploy/helm/monitoring/values.yaml` exists.
- `deploy/helm/service-monitors.yaml` and `deploy/helm/sre-alerts.yaml` exist when applying Open Horizons monitoring resources.
- `grafana/dashboards/` exists for dashboard inventory.

## Workflow steps

### Step 1: Inspect current monitoring state

```bash
kubectl get namespaces
kubectl get pods -n monitoring
helm list -n monitoring
kubectl get pods -n observability
```

Use whichever namespace exists. Do not create or mutate namespaces until the confirmation gate.

### Step 2: Validate repository monitoring assets

```bash
test -f deploy/helm/monitoring/values.yaml
test -f deploy/helm/service-monitors.yaml
test -f deploy/helm/sre-alerts.yaml
test -d grafana/dashboards
```

### Step 3: Preview Helm deployment

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values deploy/helm/monitoring/values.yaml \
  --dry-run
```

### Step 4: Preview Kubernetes monitoring resources

```bash
kubectl apply -f deploy/helm/service-monitors.yaml --dry-run=client -o yaml
kubectl apply -f deploy/helm/sre-alerts.yaml --dry-run=client -o yaml
kubectl diff -f deploy/helm/service-monitors.yaml
kubectl diff -f deploy/helm/sre-alerts.yaml
```

### Step 5: Classify observability risk

| Risk | Meaning |
| --- | --- |
| High | Installing or upgrading monitoring stack, changing alert routes, deleting PVCs, or modifying production alerts. |
| Medium | Applying ServiceMonitor, PrometheusRule, dashboard ConfigMap, or scrape configuration changes. |
| Low | Reading pods, targets, dashboards, logs, events, or rendering dry-runs. |

### Step 6: User confirmation gate

```text
Observability action: <install|upgrade|apply-rules|apply-dashboards>
Cluster context: <context>
Namespace: <monitoring|observability>
Assets: deploy/helm/monitoring/values.yaml, deploy/helm/service-monitors.yaml, deploy/helm/sre-alerts.yaml, grafana/dashboards/
Risk: <High|Medium|Low>
Proceed with observability mutation? (y/n)
```

> [!IMPORTANT]
> Only install, upgrade, apply, delete, or modify observability resources after an explicit affirmative response. On a negative, ambiguous, or missing response, do not mutate the cluster; output dry-run findings and stop.

### Step 7: Execute approved deployment or update

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values deploy/helm/monitoring/values.yaml \
  --wait --timeout 15m
kubectl apply -f deploy/helm/service-monitors.yaml
kubectl apply -f deploy/helm/sre-alerts.yaml
```

### Step 8: Verify health and targets

```bash
kubectl get pods -n monitoring
kubectl get servicemonitor -A
kubectl get prometheusrule -A
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Then query Prometheus locally when the port-forward is running.

```bash
curl -s 'http://localhost:9090/api/v1/targets'
```

## Error handling

| Situation | Action |
| --- | --- |
| Monitoring namespace is absent | Treat install as High risk and require approval before creating it. |
| Helm dry-run fails | Report values or chart errors and stop before mutation. |
| CRDs are missing | Install or upgrade kube-prometheus-stack only after approval. |
| Prometheus targets are down | Report target labels, scrape URL, and last error. |
| Grafana credentials are unavailable | Do not guess credentials; request retrieval from the approved secret store. |

## Output template

```markdown
## Observability Report

**Cluster context:** <context>
**Namespace:** <namespace>
**Action:** <inspect|install|upgrade|apply|troubleshoot>
**Risk:** <High|Medium|Low>

### Asset Validation
- `deploy/helm/monitoring/values.yaml`: <present|missing>
- `deploy/helm/service-monitors.yaml`: <present|missing>
- `deploy/helm/sre-alerts.yaml`: <present|missing>
- `grafana/dashboards/`: <present|missing>

### Health
- Prometheus: <status>
- Grafana: <status>
- Alertmanager: <status>
- Targets: <summary>

### Findings
- <finding>
```

## Quality gate

- [ ] Confirmed cluster context and monitoring namespace.
- [ ] Verified all referenced monitoring files and directories exist.
- [ ] Ran Helm dry-run before install or upgrade.
- [ ] Ran Kubernetes dry-run or diff before applying rules or monitors.
- [ ] Received explicit approval before mutating monitoring resources.
- [ ] Verified pods, ServiceMonitors, PrometheusRules, and targets after mutation.
'''
files['pipeline-diagnostics'] = '''---
name: pipeline-diagnostics
description: "Use when diagnosing GitHub Actions CI/CD failures, failed workflow runs, build errors, deploy job failures, skipped workflows, queue delays, and failed job logs. Produces workflow evidence, failed step identification, root-cause analysis, and remediation steps. DO NOT USE FOR: test analysis (use test-coverage), Kubernetes operations (use kubectl-cli), Helm charts (use helm-cli). Triggers include \"diagnose this workflow failure\", \"why did CI fail\", \"inspect failed GitHub Actions logs\", and \"debug the deploy pipeline\"."
---

# Pipeline Diagnostics

Use this skill to analyze GitHub Actions workflow runs from real `gh` output and repository workflow files under `.github/workflows/`. It produces a concise diagnosis with failed job, failed step, likely root cause, and the next remediation owner.

> [!NOTE]
> This skill depends on the `gh` CLI, authenticated GitHub access, and workflow visibility for the target repository. It does not use an MCP server by default.

## When to invoke

- "Diagnose this failed GitHub Actions run."
- "Why did the deploy pipeline fail?"
- "Inspect the failed job logs for this workflow."
- "Explain why the workflow was skipped."
- "Find the root cause of this CI error."

## Prerequisites

- `gh auth status` succeeds.
- The repository owner/name, workflow name, run ID, branch, or PR number is known.
- `.github/workflows/` exists in the repository.
- The user wants CI/CD diagnosis rather than test coverage analysis or Kubernetes troubleshooting.

## Workflow steps

### Step 1: Identify the run

```bash
gh run list --limit 10
gh run list --status failure --limit 5
```

If the user provides a PR, inspect checks first.

```bash
gh pr checks <pr-number>
```

### Step 2: Fetch failed job evidence

```bash
gh run view <run-id>
gh run view <run-id> --log-failed
```

Collect workflow name, run number, branch, event, failed job, failed step, and the first actionable error line.

### Step 3: Classify failure severity

| Severity | Meaning |
| --- | --- |
| Critical | Required check blocks merge or deployment, security scan failed, or release workflow failed. |
| High | Main CI failed on a protected branch or repeat failure affects multiple PRs. |
| Medium | PR-only failure with clear remediation and no production impact. |
| Low | Skipped, cancelled, neutral, or documentation-only check issue. |

### Step 4: Diagnose by pattern

| Pattern | Evidence | Next action |
| --- | --- | --- |
| Dependency install | Fails in `npm ci`, `pip install`, or package restore | Check lock file and registry errors. |
| Build or compile | Type, import, or compiler error | Identify file and line, then fix or hand off to code owner. |
| Test failure | Test runner reports failed tests | Use `test-coverage` for detailed test analysis. |
| Docker failure | `docker build` or push error | Check Dockerfile paths, image tags, and registry auth. |
| Deployment failure | `kubectl`, `helm`, or Azure step failed | Route to `kubectl-cli`, `helm-cli`, or `azure-cli`. |

### Step 5: Recommend rerun only when appropriate

Rerun failed jobs only when evidence indicates flake, transient infrastructure, or external service failure.

```bash
gh run rerun <run-id> --failed
```

## Error handling

| Situation | Action |
| --- | --- |
| Run ID is missing | List recent runs and ask the user to identify the target if ambiguous. |
| GitHub auth fails | Ask the operator to run `gh auth login`; do not infer logs. |
| Logs are unavailable | Use run summary, job status, and workflow file evidence; state the limitation. |
| Failure is a test assertion | Stop CI diagnosis and use `test-coverage` for test-specific analysis. |
| Failure is a live cluster error | Summarize the pipeline evidence and route to `kubectl-cli` or `helm-cli`. |

## Output template

```markdown
## Pipeline Diagnosis

**Workflow:** <workflow>
**Run:** <run-id>
**Branch:** <branch>
**Event:** <event>
**Severity:** <Critical|High|Medium|Low>

### Failed Job and Step
| Job | Step | Conclusion | Evidence |
| --- | --- | --- | --- |
| <job> | <step> | <conclusion> | <log excerpt> |

### Root Cause
<analysis>

### Remediation
1. <step>

### Handoff
- <skill or owner>
```

## Quality gate

- [ ] Used real `gh` run or PR check data.
- [ ] Identified workflow, run, failed job, and failed step.
- [ ] Included one actionable log excerpt or stated why logs were unavailable.
- [ ] Classified severity.
- [ ] Recommended rerun only when justified by evidence.
'''
files['prerequisites'] = '''---
name: prerequisites
description: "Use when validating local or CI prerequisites for Open Horizons deployments: CLI presence, versions, authentication, Azure/GitHub access, Docker, Node.js, and optional ArgoCD or kubelogin readiness. Produces a prerequisite checklist, missing-tool report, and installation guidance. DO NOT USE FOR: deployment orchestration (use deploy-orchestration), Terraform operations (use terraform-cli), Kubernetes operations (use kubectl-cli). Triggers include \"validate prerequisites\", \"check my CLI tools\", \"am I ready to deploy\", and \"install missing tools\"."
allowed-tools:
- shell
---

# Prerequisites

Use this skill to validate the operator workstation or CI runner before Open Horizons deployment. It produces a tool and authentication report using the repository scripts `scripts/validate-prerequisites.sh`, `.github/skills/prerequisites/scripts/validate-prerequisites.sh`, and `.github/skills/prerequisites/scripts/validate-cli-prerequisites.sh`.

> [!NOTE]
> This skill depends on shell access, Bash 4 or newer for the skill-local scripts, and installed or installable CLIs such as `az`, `terraform`, `kubectl`, `helm`, `gh`, `jq`, `yq`, `git`, and `curl`. It does not use an MCP server.

## When to invoke

- "Validate prerequisites before deployment."
- "Check whether this machine has the required CLIs."
- "Am I authenticated to Azure and GitHub?"
- "Show what tools are missing for Open Horizons."
- "Prepare a runner for platform validation."

## Prerequisites

- Shell execution is allowed.
- The repository root is the working directory.
- For authentication checks, the operator expects `az account show` and `gh auth status` to be meaningful.
- Installing missing tools requires explicit user approval and package-manager access.

## Workflow steps

### Step 1: Run the repository prerequisite validator

```bash
./scripts/validate-prerequisites.sh
```

### Step 2: Run skill-local validators when deeper CLI detail is needed

```bash
.github/skills/prerequisites/scripts/validate-prerequisites.sh
.github/skills/prerequisites/scripts/validate-cli-prerequisites.sh
```

### Step 3: Inspect required tool categories

| Category | Tools |
| --- | --- |
| Cloud and IaC | `az`, `terraform` |
| Kubernetes | `kubectl`, `helm`, `kubelogin`, `argocd` |
| GitHub | `gh`, `git` |
| Utilities | `jq`, `yq`, `curl` |
| Local runtime | `docker`, `node`, `npx` |

### Step 4: Classify readiness

| Severity | Meaning |
| --- | --- |
| Critical | Required tool missing or Azure/GitHub auth unavailable for requested deployment. |
| High | Required version is too old or cluster auth helper is missing. |
| Medium | Optional but recommended tool is missing. |
| Low | Cosmetic warning or version could not be parsed but tool runs. |

### Step 5: User confirmation gate for installation

```text
Missing tools: <tools>
Install command or package manager: <command>
Scope: local workstation or CI runner
Proceed with installing missing prerequisites? (y/n)
```

> [!IMPORTANT]
> Only install tools or modify the local environment after an explicit affirmative response. On a negative, ambiguous, or missing response, do not install anything; output the missing-tool report and stop.

### Step 6: Re-run validation after approved installation

```bash
./scripts/validate-prerequisites.sh
```

## Error handling

| Situation | Action |
| --- | --- |
| Bash version is too old | Report that Bash 4 or newer is required for skill-local scripts. |
| `az` is not authenticated | Ask the operator to run `az login` and select the correct subscription. |
| `gh` is not authenticated | Ask the operator to run `gh auth login`. |
| Package manager is unavailable | Provide manual install links or commands without executing them. |
| Script exits non-zero | Preserve the failed section and list exact missing tools. |

## Output template

```markdown
## Prerequisites Report

**Environment:** <local|CI>
**Overall readiness:** <Ready|Blocked|Partial>

### Tool Status
| Tool | Status | Version | Required action |
| --- | --- | --- | --- |
| <tool> | <present|missing|auth-needed> | <version> | <action> |

### Findings
- <finding>

### Next Steps
1. <step>
```

## Quality gate

- [ ] Ran `./scripts/validate-prerequisites.sh` or explained why it could not run.
- [ ] Verified the skill-local script paths exist before referencing them.
- [ ] Reported missing tools and authentication gaps separately.
- [ ] Did not install anything without explicit approval.
- [ ] Re-ran validation after any approved installation.
'''
files['requirements-engineer'] = '''---
name: requirements-engineer
description: "Use when eliciting, analyzing, complementing, or validating functional and non-functional requirements before SDD initialization. Produces FRD and NFRD artifacts, gap analysis, assumptions, priorities, measurable acceptance signals, and a Specky handoff block. DO NOT USE FOR: code, implementation, or CONSTITUTION.md generation, which belongs to sdd_init or sdd-spec-engineer. Triggers include \"write requirements\", \"create an FRD\", \"create an NFRD\", \"validate these requirements\", and \"prepare input for sdd_init\"."
---

# Requirements Engineer

Use this skill to turn raw product input into production-grade Functional Requirements Document (FRD) and Non-Functional Requirements Document (NFRD) content ready for Spec-Driven Development. It produces gap analysis, critical questions, assumptions, prioritized requirements, validation results, and a handoff block for `sdd_init`.

> [!NOTE]
> This skill depends on user-provided product context and repository templates under `golden-paths/common/templates/` when aligning with Open Horizons SDD conventions. It does not shell out to a CLI or require an MCP server by default.

## When to invoke

- "Write the FRD and NFRD for this feature."
- "Validate these requirements before sdd_init."
- "Turn these notes into measurable requirements."
- "Find gaps in this product brief."
- "Prepare Specky input from this epic."

## Prerequisites

- Raw notes, problem statement, PRD, user story, or stakeholder description is available.
- The project type can be identified as greenfield, brownfield, modernization, legacy migration, API, mobile, data platform, SaaS, internal tool, CLI, or infrastructure.
- Critical scope boundaries, user roles, and primary user actions are known or can be asked as at most three questions.
- The output path is known if files are to be created.

## Workflow steps

### Step 1: Classify project type

| Type | Signal | Required emphasis |
| --- | --- | --- |
| Greenfield | New product or build from scratch | Success criteria and non-goals. |
| Brownfield | Existing system or extension | Current state, delta scope, backward compatibility. |
| Modernization | Rewrite, migrate, or modernize | Source system, parity, cutover, rollback. |
| API or platform | API, SDK, developer portal | Consumers, versioning, rate limits. |
| SaaS | Tenant or subscription language | Tenant isolation and onboarding. |
| Infrastructure | Platform, AKS, Terraform, environment | Operational constraints and access model. |

### Step 2: Detect critical gaps

Ask at most three questions for missing critical facts. Document all other assumptions.

| Gap | Severity | Action |
| --- | --- | --- |
| User roles and permissions | Critical | Ask before writing final requirements. |
| Primary user action | Critical | Ask before writing final requirements. |
| Scope boundary | Critical | Ask before writing final requirements. |
| Authentication strategy | High | Assume only if the user accepts the assumption. |
| Performance target | High | Propose measurable defaults and mark as assumptions. |

### Step 3: Write functional requirements

Rules for every FR:

- State what the system must do, not how it is implemented.
- Use `must` in FR text.
- Include priority P0, P1, P2, or P3.
- Include an observable acceptance signal.
- Organize by domain, not by UI screen or implementation layer.

### Step 4: Write non-functional requirements

Include measurable targets for performance, security, availability, testability, CI/CD, observability, accessibility, localization, data retention, compliance, and technology constraints.

### Step 5: Validate the artifacts

| Severity | Meaning |
| --- | --- |
| Critical | Missing role, primary action, scope boundary, or testable P0 requirement. |
| High | Vague quality target, missing security method, or no deployment context. |
| Medium | Weak assumption, missing non-goal, or unclear priority. |
| Low | Formatting or terminology issue. |

### Step 6: Produce Specky handoff

Use the existing SDD templates in `golden-paths/common/templates/` as downstream context. Do not generate `CONSTITUTION.md`; hand off to `sdd-spec-engineer` or `sdd_init`.

## Error handling

| Situation | Action |
| --- | --- |
| Critical context is missing | Ask up to three focused questions and pause finalization. |
| User asks for implementation | Redirect to SDD or implementation workflow after requirements are approved. |
| Requirements include technology choices | Move them to NFRD technology constraints unless they are true business constraints. |
| Too many P0 items | Recommend scope reduction to 5-15 P0 requirements. |
| Acceptance signal is vague | Rewrite with observable pass/fail criteria. |

## Output template

```markdown
## Requirements Delivery Report

**Project:** <name>
**Project type:** <type>
**Artifacts:** FRD, NFRD
**Readiness for sdd_init:** <Yes|No>

### Gap Analysis
| Gap | Severity | Resolution |
| --- | --- | --- |
| <gap> | <severity> | <resolution> |

### Summary
- Functional requirements: <count>
- Non-functional requirements: <count>
- Assumptions: <count>

### Specky Handoff
FRD: <path-or-title>
NFRD: <path-or-title>
Feature name: <kebab-case>
Open questions: <questions>
```

## Quality gate

- [ ] Project type is identified.
- [ ] Critical gaps are resolved or explicitly blocked.
- [ ] Every FR uses `must` and has priority plus acceptance signal.
- [ ] NFRs are measurable and include deployment context.
- [ ] Assumptions are documented with consequences.
- [ ] Specky handoff is present and does not create `CONSTITUTION.md`.
'''
files['sdd-spec-engineer'] = '''---
name: sdd-spec-engineer
description: "Use when orchestrating Spec-Driven Development from approved requirements into SDD artifacts: specification, design, task plan, traceability matrix, EARS acceptance criteria, Mermaid architecture, and pre-implementation quality gates. Produces SPECIFICATION, DESIGN, TASKS, and ANALYSIS-style deliverables for coding-agent handoff. DO NOT USE FOR: standalone FRD/NFRD authoring before sdd_init (use requirements-engineer), INVEST user story decomposition or GitHub Issue creation (use story-planning), Foundry runtime/provisioning detail (use ai-foundry-operations or foundry-agent-blueprint), or general agentic architecture trade-off decisions (use agentic-architecture-patterns). Triggers include \"spec this\", \"run SDD\", \"create a task plan\", and \"write EARS requirements\"."
---

# SDD Spec Engineer

Use this skill to transform approved requirements into Spec-Driven Development artifacts using EARS notation and the repository templates in `golden-paths/common/templates/`. It produces traceable specification, design, tasks with `[P]` markers, and a quality-gate analysis suitable for coding-agent handoff.

> [!NOTE]
> This skill depends on repository references `.github/skills/sdd-spec-engineer/references/ears-notation.md`, `.github/skills/sdd-spec-engineer/references/spec-templates.md`, and SDD templates in `golden-paths/common/templates/`. It does not require a CLI or MCP server by default.

## When to invoke

- "Spec this feature using SDD."
- "Create EARS requirements and a design for this change."
- "Generate a task plan with parallel markers."
- "Analyze this spec for traceability gaps."
- "Prepare implementation handoff after requirements approval."

## Prerequisites

- FRD/NFRD or equivalent approved requirements exist.
- Scope boundaries and non-goals are known.
- `golden-paths/common/templates/CONSTITUTION.md`, `golden-paths/common/templates/SPECIFICATION.md`, and `golden-paths/common/templates/IMPLEMENTATION_PLAN.md` exist.
- Reference files under `.github/skills/sdd-spec-engineer/references/` exist.

## Workflow steps

### Step 1: Load SDD references

Read `.github/skills/sdd-spec-engineer/references/ears-notation.md` and `.github/skills/sdd-spec-engineer/references/spec-templates.md` before authoring.

### Step 2: Confirm feature scope

1. Name the feature with a sequential folder-friendly slug such as `001-feature-name`.
2. Confirm included and excluded requirements.
3. Identify constraints from the approved NFRD.

### Step 3: Write EARS requirements

Use only these patterns:

- Ubiquitous: `The <system> shall <response>.`
- Event-driven: `When <trigger>, the <system> shall <response>.`
- State-driven: `While <state>, the <system> shall <response>.`
- Unwanted behavior: `If <condition>, then the <system> shall <response>.`
- Optional feature: `Where <feature is included>, the <system> shall <response>.`

### Step 4: Produce design and task artifacts

- Design includes architecture overview, Mermaid diagram, components, data model, interfaces, risks, and trade-offs.
- Tasks are atomic, sequenced, and trace to requirements.
- Use `[P]` only for tasks that can run in parallel without file or state conflicts.

### Step 5: Classify specification findings

| Severity | Meaning |
| --- | --- |
| Critical | Requirement has no task, task has no requirement, or acceptance criteria are not testable. |
| High | Design omits security, data model, or integration needed by P0 requirements. |
| Medium | Task ordering, naming, or parallel marker issue. |
| Low | Formatting, wording, or traceability table polish. |

### Step 6: Pre-implementation gate

```text
Artifacts ready: Requirements, Design, Tasks, Analysis
Traceability: <complete|incomplete>
Open questions: <count>
Proceed to implementation handoff? (y/n)
```

> [!IMPORTANT]
> Only hand off to implementation after explicit approval and a complete traceability matrix. On a negative, ambiguous, or missing response, stop at the artifact review and list unresolved gaps.

## Error handling

| Situation | Action |
| --- | --- |
| Requirements are missing | Route to `requirements-engineer` before SDD artifact generation. |
| EARS criteria are vague | Rewrite into one atomic, observable EARS sentence. |
| Mermaid diagram is malformed | Simplify the diagram and validate syntax before delivery. |
| Task lacks traceability | Add requirement references or remove the task. |
| Too many sequential tasks | Recheck independence and mark safe tasks with `[P]`. |

## Output template

```markdown
## SDD Artifact Report

**Feature:** <feature-slug>
**Artifacts:** <Requirements|Design|Tasks|Analysis>
**Traceability:** <complete|incomplete>

### Findings
| Finding | Severity | Fix |
| --- | --- | --- |
| <finding> | <severity> | <fix> |

### Handoff
- Requirements approved: <yes|no>
- Design reviewed: <yes|no>
- Tasks ready: <yes|no>
- Open questions: <questions>
```

## Quality gate

- [ ] Loaded EARS and spec template references.
- [ ] Used only EARS acceptance patterns.
- [ ] Included design, tasks, and analysis where requested.
- [ ] Every requirement traces to at least one design component and task.
- [ ] Every task traces to a requirement.
- [ ] Implementation handoff is gated on explicit approval.
'''
files['story-planning'] = '''---
name: story-planning
description: "Use when decomposing epics into INVEST user stories, mapping personas, writing acceptance criteria, grooming backlog items, or creating GitHub Issues for sprint-ready work. Produces story maps, issue bodies, labels, duplicate checks, and optional GitHub Issues. DO NOT USE FOR: test analysis (use test-coverage), pipeline diagnostics (use pipeline-diagnostics), Azure infrastructure design (use azure-infrastructure). Triggers include \"decompose this epic\", \"write user stories\", \"create GitHub issues for these stories\", and \"prepare sprint backlog\"."
---

# Story Planning

Use this skill to decompose epics into INVEST-compliant user stories and, after approval, create GitHub Issues with consistent labels and acceptance criteria. It produces a story map, duplicate-check summary, issue-ready Markdown bodies, and optional `gh issue create` commands.

> [!NOTE]
> This skill depends on the `gh` CLI and authenticated GitHub access when creating or inspecting GitHub Issues. It does not use an MCP server by default.

## When to invoke

- "Break this epic into user stories."
- "Create GitHub Issues for these stories."
- "Check whether these stories meet INVEST."
- "Prepare sprint-ready backlog items."
- "Find duplicate issues before we create new stories."

## Prerequisites

- Epic description, target personas, and expected business outcome are available.
- Repository owner/name is known for GitHub Issue operations.
- `gh auth status` succeeds if querying or creating issues.
- Labels are known or can be proposed, such as `user-story`, `epic:<name>`, and `priority:<level>`.

## Workflow steps

### Step 1: Understand the epic

Capture problem, target users, desired outcome, constraints, and out-of-scope items.

### Step 2: Identify personas

Common Open Horizons personas include Developer, SRE, Platform Engineer, Tech Lead, Product Owner, Security Engineer, and Backstage Portal Admin.

### Step 3: Decompose into INVEST stories

| INVEST criterion | Check |
| --- | --- |
| Independent | Story can deliver value without hidden dependency. |
| Negotiable | Implementation details are not over-specified. |
| Valuable | Benefit is clear to a persona or business goal. |
| Estimable | Scope is clear enough for team estimation. |
| Small | Fits within one sprint. |
| Testable | Acceptance criteria are observable. |

### Step 4: Check for duplicate issues

```bash
gh issue list --search "<keywords>" --state open
gh issue list --label "epic:<name>" --state open
```

### Step 5: Classify story readiness

| Severity | Meaning |
| --- | --- |
| Critical | Story lacks persona, value, or acceptance criteria. |
| High | Duplicate likely exists or story is too large for a sprint. |
| Medium | Labels, priority, or dependency needs refinement. |
| Low | Wording or formatting issue. |

### Step 6: User confirmation gate for GitHub Issue creation

```text
Repository: <owner>/<repo>
Epic: <epic>
Stories to create: <count>
Labels: user-story, epic:<name>, priority:<level>
Proceed with creating GitHub Issues? (y/n)
```

> [!IMPORTANT]
> Only create GitHub Issues after an explicit affirmative response. On a negative, ambiguous, or missing response, do not create issues; output the issue-ready story bodies and stop.

### Step 7: Create approved issues

```bash
gh issue create --title "Story: <title>" --body "<markdown body>" --label "user-story,epic:<name>,priority:<level>"
```

## Error handling

| Situation | Action |
| --- | --- |
| Epic lacks persona or value | Ask a focused question before creating stories. |
| More than eight stories are needed | Recommend splitting the epic. |
| Duplicate issue exists | Link the duplicate and do not create a new issue unless approved. |
| GitHub auth fails | Ask the operator to run `gh auth login`. |
| Label does not exist | Create issue without the missing label only if the user approves; otherwise stop. |

## Output template

```markdown
## Epic Decomposition Report

**Epic:** <name>
**Personas:** <personas>
**Stories:** <count>
**GitHub Issues Created:** <yes|no>

### Stories
| # | Title | Persona | INVEST status | Labels |
| --- | --- | --- | --- | --- |
| 1 | <title> | <persona> | <pass|needs work> | `user-story` |

### Duplicate Check
- <result>

### Next Steps
1. <step>
```

## Quality gate

- [ ] Every story has persona, capability, and benefit.
- [ ] Every story has 3-5 acceptance criteria.
- [ ] INVEST criteria were checked.
- [ ] Duplicate issues were searched before creation.
- [ ] No story point estimates were invented.
- [ ] Explicit approval was received before creating GitHub Issues.
'''
files['terraform-cli'] = '''---
name: terraform-cli
description: "Use when running or preparing Terraform operations for Azure infrastructure: fmt, validate, init, plan, apply, destroy, state inspection, module checks, and IaC security review. Produces formatted commands, plan summaries, risk classification, and approval-gated apply or destroy steps. DO NOT USE FOR: Azure CLI operations (use azure-cli), Kubernetes operations (use kubectl-cli), Helm charts (use helm-cli). Triggers include \"run terraform plan\", \"validate Terraform\", \"apply this plan\", and \"inspect Terraform state\"."
---

# Terraform CLI

Use this skill to operate Open Horizons Terraform under `terraform/`, including modules in `terraform/modules/` and environment variables in `terraform/environments/dev.tfvars`. It produces safe command sequences, plan summaries, state inspection guidance, and explicit approval gates for apply or destroy.

> [!NOTE]
> This skill depends on Terraform 1.5 or newer, Azure authentication through `az` or workload identity, access to the configured backend, and environment-specific tfvars under `terraform/environments/`. It does not use an MCP server by default.

## When to invoke

- "Run terraform plan for dev."
- "Validate the Terraform modules."
- "Apply the approved Terraform plan."
- "Inspect Terraform state for the AKS module."
- "Destroy this environment after approval."

## Prerequisites

- `terraform version` succeeds.
- `az account show` or the configured workload identity is available.
- `terraform/modules/` and `terraform/environments/dev.tfvars` exist.
- The target environment is known.
- Apply and destroy actions have explicit user approval.

## Workflow steps

### Step 1: Confirm scope and backend posture

```bash
cd terraform
terraform version
terraform fmt -check -recursive -diff
terraform init -backend=false
terraform validate
```

### Step 2: Create a plan

Use the repo's phased deployment guidance for empty subscriptions: H1 first, then H2 modules.

```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars -out=h1.tfplan
terraform show h1.tfplan
```

### Step 3: Inspect state read-only when needed

```bash
cd terraform
terraform state list
terraform state show '<resource-address>'
```

### Step 4: Classify Terraform risk

| Risk | Meaning |
| --- | --- |
| High | Destroy actions, replacement of AKS/network/database resources, backend changes, or production apply. |
| Medium | Adds or updates Azure resources, RBAC, Key Vault, networking, or Kubernetes/Helm providers. |
| Low | `fmt`, `validate`, `plan`, `show`, or read-only state inspection. |

### Step 5: User confirmation gate

```text
Terraform action: <apply|destroy>
Working directory: terraform/
Environment file: terraform/environments/dev.tfvars
Plan file: <planfile>
Risk: <High|Medium|Low>
Proceed with Terraform mutation? (y/n)
```

> [!IMPORTANT]
> Only run `terraform apply` or `terraform destroy` after an explicit affirmative response and a saved plan review. On a negative, ambiguous, or missing response, do not mutate infrastructure; output the plan summary and stop.

### Step 6: Execute approved apply

```bash
cd terraform
terraform apply h1.tfplan
```

For H2 module apply after H1 outputs exist:

```bash
cd terraform
terraform apply -var-file=environments/dev.tfvars \
  -target=module.argocd \
  -target=module.observability \
  -target=module.external_secrets \
  -target=module.databases
```

### Step 7: Verify with repository validation scripts

```bash
./scripts/validate-config.sh --environment dev
./scripts/validate-deployment.sh --environment dev
```

## Error handling

| Situation | Action |
| --- | --- |
| `terraform init` fails | Report backend or provider error and stop before planning. |
| Validation fails | Report file and diagnostic; do not plan until fixed. |
| Plan includes unexpected destroy | Reclassify High risk and require explicit approval. |
| Provider needs AKS outputs on empty subscription | Use phased H1 then H2 apply as documented. |
| State lock is held | Report lock ID and owner; do not force-unlock without explicit approval. |

## Output template

```markdown
## Terraform Operation Report

**Working directory:** `terraform/`
**Environment:** <env>
**Action:** <fmt|validate|plan|apply|destroy|state>
**Risk:** <High|Medium|Low>

### Plan Summary
- Add: <count>
- Change: <count>
- Destroy: <count>

### Commands Run
- `<command>`

### Findings
- <finding>
```

## Quality gate

- [ ] Ran `terraform fmt -check -recursive -diff`.
- [ ] Ran `terraform validate`.
- [ ] Used an existing tfvars file under `terraform/environments/`.
- [ ] Reviewed a saved plan before mutation.
- [ ] Received explicit approval before apply or destroy.
- [ ] Ran relevant validation scripts after approved apply.
'''
files['test-coverage'] = '''---
name: test-coverage
description: "Use when analyzing test coverage, GitHub check runs, PR quality gates, failed tests, coverage regressions, merge readiness, and test improvement recommendations. Produces check-run summaries, coverage findings, severity classification, and actionable test remediation. DO NOT USE FOR: pipeline diagnostics (use pipeline-diagnostics), security review (use @security), deployment orchestration (use @deploy). Triggers include \"analyze test coverage\", \"why are PR checks failing\", \"review quality gate\", and \"find coverage gaps\"."
---

# Test Coverage

Use this skill to analyze tests, coverage, and PR quality gates using real GitHub Checks and PR evidence. It produces a check summary, coverage risk assessment, failed-test analysis, and targeted recommendations.

> [!NOTE]
> This skill depends on the `gh` CLI, authenticated GitHub access, and repository check-run or PR visibility. It does not use an MCP server by default.

## When to invoke

- "Analyze test coverage for this PR."
- "Why are PR checks failing?"
- "Review merge readiness from checks and reviews."
- "Find coverage gaps introduced by this change."
- "Summarize failed tests from GitHub checks."

## Prerequisites

- `gh auth status` succeeds.
- Repository owner/name and PR number, branch, or commit SHA are known.
- Check runs exist for the target ref.
- Coverage artifacts or check output are available if coverage percentage is requested.

## Workflow steps

### Step 1: Fetch check-run evidence

```bash
gh pr checks <pr-number>
gh api repos/<owner>/<repo>/commits/<ref>/check-runs --jq '.check_runs[] | {name, status, conclusion}'
```

### Step 2: Inspect failed or coverage-related checks

```bash
gh api repos/<owner>/<repo>/check-runs/<check-run-id>
gh pr view <pr-number> --json reviews,commits,statusCheckRollup
```

### Step 3: Classify quality risk

| Severity | Meaning |
| --- | --- |
| Critical | Required test or coverage check failed and blocks merge. |
| High | Coverage regression or repeat test failure on protected branch. |
| Medium | Non-required test failure, flaky test, or missing coverage evidence. |
| Low | Skipped, neutral, cancelled, or informational check. |

### Step 4: Diagnose common patterns

| Pattern | Evidence | Recommendation |
| --- | --- | --- |
| Flaky test | Same test alternates pass and fail | Stabilize timing, test data, and external dependencies. |
| Environment mismatch | CI fails but local pass is reported | Align runtime versions and environment variables. |
| Coverage regression | Coverage below threshold | Add tests for changed branches and error paths. |
| Required check failure | Merge blocked by check policy | Fix the failing check rather than bypassing. |

### Step 5: Escalate when failure is not test-specific

- Use `pipeline-diagnostics` for workflow, dependency install, or build-step failures.
- Use `kubectl-cli` or `helm-cli` for deployment checks that fail inside tests.

## Error handling

| Situation | Action |
| --- | --- |
| Check data is unavailable | State the limitation and inspect PR status rollup if available. |
| GitHub auth fails | Ask the operator to run `gh auth login`. |
| Failure is a workflow infrastructure issue | Route to `pipeline-diagnostics`. |
| Coverage report is missing | Report that coverage cannot be quantified and list needed artifact or check name. |
| PR number is ambiguous | List open PRs and ask for the target if multiple match. |

## Output template

```markdown
## Test Coverage and Quality Report

**Repository:** <owner>/<repo>
**Ref or PR:** <ref-or-pr>
**Severity:** <Critical|High|Medium|Low>

### Check Summary
| Check | Status | Conclusion | Required | Notes |
| --- | --- | --- | --- | --- |
| <check> | <status> | <conclusion> | <yes|no|unknown> | <notes> |

### Coverage Findings
- <finding>

### Recommendations
1. <recommendation>
```

## Quality gate

- [ ] Used real check-run, PR, or coverage artifact data.
- [ ] Separated test failures from pipeline infrastructure failures.
- [ ] Classified severity and merge impact.
- [ ] Identified failed check names and conclusions.
- [ ] Recommended concrete tests or coverage improvements.
- [ ] No emojis or pictographs are present in the report.
'''
files['validation-scripts'] = '''---
name: validation-scripts
description: "Use when running Open Horizons repository validation scripts for prerequisites, configuration, deployment health, naming, agent customization, documentation, or post-deploy checks. Produces command results, pass/fail summaries, and remediation guidance. DO NOT USE FOR: Terraform validation (use terraform-cli), Kubernetes checks (use kubectl-cli), Helm operations (use helm-cli). Triggers include \"run validation scripts\", \"validate deployment\", \"validate config\", \"check agents\", and \"post-deploy validation\"."
---

# Validation Scripts

Use this skill to run existing Open Horizons validation scripts without inventing new tooling. It produces command transcripts, pass/fail summaries, and remediation guidance for repository, deployment, and Copilot customization validation.

> [!NOTE]
> This skill depends on Bash, Python 3 for `.github/skills/validation-scripts/scripts/validate-agents.py`, and any CLIs required by the specific validation script. It does not use an MCP server by default.

## When to invoke

- "Run validation scripts before deployment."
- "Validate the dev configuration."
- "Run post-deploy health checks."
- "Validate Copilot agents and skills."
- "Check Azure naming conventions."

## Prerequisites

- The repository root is the working directory.
- The script path exists before execution.
- Required CLIs for the selected script are installed.
- Target environment is known when the script requires `--environment`.

## Workflow steps

### Step 1: Select the existing script

| Task | Script |
| --- | --- |
| Prerequisites | `scripts/validate-prerequisites.sh` |
| Configuration | `scripts/validate-config.sh` |
| Deployment health | `scripts/validate-deployment.sh` |
| Documentation | `scripts/validate-docs.sh` |
| Agent and skill metadata | `.github/skills/validation-scripts/scripts/validate-agents.py` |
| Azure naming | `.github/skills/validation-scripts/scripts/validate-naming.sh` |

### Step 2: Verify script existence

```bash
test -f scripts/validate-prerequisites.sh
test -f scripts/validate-config.sh
test -f scripts/validate-deployment.sh
test -f scripts/validate-docs.sh
test -f .github/skills/validation-scripts/scripts/validate-agents.py
test -f .github/skills/validation-scripts/scripts/validate-naming.sh
```

### Step 3: Run the narrowest validation

```bash
./scripts/validate-prerequisites.sh
./scripts/validate-config.sh --environment dev
./scripts/validate-deployment.sh --environment dev
python3 .github/skills/validation-scripts/scripts/validate-agents.py --strict
```

### Step 4: Classify validation findings

| Severity | Meaning |
| --- | --- |
| Critical | Validation exits non-zero for deployment readiness, strict metadata, or required tools. |
| High | Environment config drift or unhealthy required component. |
| Medium | Optional component missing or warning with documented workaround. |
| Low | Informational recommendation. |

### Step 5: Report and route remediation

Do not edit unrelated code from this skill. Route Terraform, Kubernetes, Helm, or pipeline failures to the matching skill.

## Error handling

| Situation | Action |
| --- | --- |
| Script path is missing | Report the missing path and stop; do not invent a replacement. |
| Permission denied | Run with `bash <script>` if executable bit is missing, or report chmod need. |
| Required CLI missing | Use `prerequisites` to resolve tool availability. |
| Deployment validation fails | Summarize failing H1/H2/H3 check and route to the relevant operational skill. |
| Strict agent validation fails | Report exact file and frontmatter error from validator output. |

## Output template

```markdown
## Validation Report

**Script:** <path>
**Command:** `<command>`
**Exit code:** <code>
**Severity:** <Critical|High|Medium|Low>

### Summary
- Passed: <count-or-summary>
- Failed: <count-or-summary>
- Warnings: <count-or-summary>

### Findings
- <finding>

### Remediation
1. <step>
```

## Quality gate

- [ ] Used only existing validation scripts.
- [ ] Verified script paths exist before referencing them.
- [ ] Ran the narrowest script that covers the requested validation.
- [ ] Captured exit code and important output.
- [ ] Routed remediation to the correct domain skill.
'''
