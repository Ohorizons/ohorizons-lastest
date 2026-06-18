# Foundry Agents — Kubernetes deploy bundle

The L6 harness gateway that fronts Azure AI Foundry. Runs in the `ai-services`
namespace on AKS. Two deploy paths are supported:

- **GitOps (recommended):** the ArgoCD Application `argocd/apps/foundry-agents.yaml`
  syncs this directory. Gated to H3 (`enable_foundry_agents=true`).
- **Manual:** apply the manifests in order, as below.

## Manual apply order

```bash
# 1. Namespace
kubectl apply -f namespace.yaml

# 2. Azure OpenAI credentials (mirror from the backstage namespace, or provide
#    via External Secrets Operator / Workload Identity in production).
kubectl create secret generic foundry-agents-azure-openai -n ai-services \
  --from-literal=AZURE_OPENAI_API_KEY="$(kubectl get secret foundry-agents-config -n backstage -o jsonpath='{.data.AZURE_OPENAI_API_KEY}' | base64 -d)" \
  --from-literal=AZURE_OPENAI_ENDPOINT="$(kubectl get secret foundry-agents-config -n backstage -o jsonpath='{.data.AZURE_OPENAI_ENDPOINT}' | base64 -d)"

# 3. Service config (non-sensitive). Replace SERVICE_API_KEY with a random value
#    or strip the field to disable auth.
kubectl apply -f secret-template.yaml

# 4. Deployment + Service + PDB
kubectl apply -f deployment.yaml

# 5. NetworkPolicy (Backstage-only ingress + egress to Azure OpenAI)
kubectl apply -f networkpolicy.yaml

# 6. Verify
kubectl get pods,svc -n ai-services -l app.kubernetes.io/name=foundry-agents
kubectl port-forward -n ai-services svc/foundry-agents 8080:8080 &
curl localhost:8080/v1/agents | jq
```

> EXTENSION_POINT: in production, replace the manual secret in step 2 with
> External Secrets Operator backed by Key Vault and Workload Identity. Partners
> wire the client identity during onboarding.

## Wire the ai-chat backend to use this gateway

The `ai-chat` Backstage plugin and its `agent-api` backend speak the OpenAI
Chat Completions protocol, so they point at this gateway directly. Add to the
Backstage `app-config` (namespace `backstage`):

```yaml
aiChat:
  providers:
    - id: openai
      baseUrl: 'http://foundry-agents.ai-services.svc.cluster.local:8080/v1'
      token: ${FOUNDRY_AGENTS_API_KEY}   # value of SERVICE_API_KEY
      model: gpt-5.1
  mcpServers:
    - id: software-catalog
      name: Software Catalog
      url: 'http://localhost:7007/api/software-catalog-mcp-tool/v1'
      type: streamable-http
    - id: techdocs
      name: TechDocs
      url: 'http://localhost:7007/api/techdocs-mcp-tool/v1'
      type: streamable-http
```

Restart the Backstage deployment to pick up the new `app-config`.
