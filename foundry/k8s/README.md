# Foundry Agents — K8s deploy bundle

Apply order:

```bash
# 1. Namespace
oc apply -f namespace.yaml

# 2. Azure OpenAI credentials (mirror from foundry-agents-config)
oc create secret generic foundry-agents-azure-openai -n ai-services \
  --from-literal=AZURE_OPENAI_API_KEY="$(kubectl get secret foundry-agents-config -n backstage -o jsonpath='{.data.AZURE_OPENAI_API_KEY}' | base64 -d)" \
  --from-literal=AZURE_OPENAI_ENDPOINT="$(kubectl get secret foundry-agents-config -n backstage -o jsonpath='{.data.AZURE_OPENAI_ENDPOINT}' | base64 -d)"

# 3. Service config (non-sensitive). Replace SERVICE_API_KEY with a random value
#    or strip the field to disable auth.
oc apply -f secret-template.yaml

# 4. Deployment + Service + PDB
oc apply -f deployment.yaml

# 5. NetworkPolicy (Backstage-only ingress + egress to Azure OpenAI)
oc apply -f networkpolicy.yaml

# 6. Verify
oc get pods,svc -n ai-services -l app.kubernetes.io/name=foundry-agents
oc port-forward -n ai-services svc/foundry-agents 8080:8080 &
curl localhost:8080/v1/agents | jq
```

## Wire mcp-chat-backend to use this gateway

Add to `app-config-rhdh` ConfigMap (ns `backstage`):

```yaml
mcpChat:
  providers:
    - id: openai
      baseUrl: 'http://foundry-agents.ai-services.svc.cluster.local:8080/v1'
      token: ${FOUNDRY_AGENTS_API_KEY}   # value of SERVICE_API_KEY
      model: gpt-4o
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

Then re-enable `mcp-chat` and `mcp-chat-backend` in the dynamic-plugins
ConfigMap and reconcile the Backstage CR.
