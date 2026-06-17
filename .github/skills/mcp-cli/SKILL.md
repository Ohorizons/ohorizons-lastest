---
name: mcp-cli
description: "Model Context Protocol server reference and operations. USE FOR: MCP server setup, MCP tool reference, MCP configuration, docker-compose MCP, MCP server troubleshooting. DO NOT USE FOR: general Docker operations, Kubernetes operations (use kubectl-cli), application deployment (use deploy-orchestration)."
---

## When to Use
- MCP server configuration reference
- Understanding available MCP capabilities
- Troubleshooting MCP server connections

## Prerequisites
- MCP servers configured in VS Code or GitHub Copilot
- Environment variables set for authentication

## Available MCP Servers

### Azure MCP Server
```json
{
  "command": "npx",
  "args": ["-y", "@anthropic/mcp-azure"],
  "env": {
    "AZURE_SUBSCRIPTION_ID": "${AZURE_SUBSCRIPTION_ID}"
  },
  "capabilities": [
    "az aks get-credentials",
    "az aks show",
    "az acr repository list",
    "az keyvault secret list",
    "az resource list"
  ]
}
```

### GitHub MCP Server
```json
{
  "command": "npx",
  "args": ["-y", "@anthropic/mcp-github"],
  "env": {
    "GITHUB_TOKEN": "${GITHUB_TOKEN}"
  },
  "capabilities": [
    "gh repo view",
    "gh issue list",
    "gh pr list",
    "gh workflow list"
  ]
}
```

### Kubernetes MCP Server
```json
{
  "command": "npx",
  "args": ["-y", "@anthropic/mcp-kubernetes"],
  "env": {
    "KUBECONFIG": "${KUBECONFIG}"
  },
  "capabilities": [
    "kubectl get",
    "kubectl describe",
    "kubectl logs",
    "kubectl apply"
  ]
}
```

## MCP Server Access by Agent

| Agent | Allowed MCP Servers | Access Level |
|-------|---------------------|--------------|
| architect | azure-readonly | Read-only |
| platform | azure, kubernetes, helm | Full |
| terraform | azure, terraform | Full |
| devops | azure, github, kubernetes | Full |
| security | azure-readonly | Read-only |
| sre | azure, kubernetes | Full |
| reviewer | github | Read-only |

## Best Practices
1. Use environment variables for credentials
2. Create read-only variants for discovery agents
3. Document server access per agent
4. Limit capabilities per server
5. Monitor MCP server invocations

## Integration with Agents
Used by: All agents with MCP configuration
