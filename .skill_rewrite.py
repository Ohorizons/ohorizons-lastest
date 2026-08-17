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
