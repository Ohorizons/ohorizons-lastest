---
name: ai-foundry-operations
description: "Azure AI Foundry — provisioning, model deployment, RAG configuration, and operational management. USE FOR: provision AI Foundry, deploy AI model, configure RAG, AI Foundry operations, OpenAI model deployment, AI workspace setup. DO NOT USE FOR: general Azure infrastructure (use azure-infrastructure), Terraform IaC (use terraform-cli), Kubernetes operations (use kubectl-cli)."
---

## When to Use
- Provision Azure AI Foundry resources
- Deploy and manage OpenAI models
- Configure RAG pipelines with AI Search
- Monitor token usage and costs
- Test model endpoints

## Prerequisites
- Azure CLI authenticated (`az login`)
- Subscription with AI services quota
- Terraform H3 modules applied (or manual provisioning)

## Provisioning

### 1. Create AI Foundry Resources (via Terraform)
```bash
# Deploy H3 Innovation layer (includes AI Foundry)
cd terraform
terraform plan -var-file=environments/dev.tfvars -var="enable_h3=true" -out=tfplan
terraform apply tfplan

# Or via bootstrap script
./scripts/platform-bootstrap.sh --horizon h3 --environment dev
```

### 2. Create Resources (via Azure CLI)
```bash
# Create Cognitive Services account (OpenAI)
az cognitiveservices account create \
  --name "${PROJECT}-${ENV}-openai" \
  --resource-group "${RG_NAME}" \
  --kind OpenAI \
  --sku S0 \
  --location eastus2 \
  --custom-domain "${PROJECT}-${ENV}-openai" \
  --tags environment="${ENV}" project="${PROJECT}"

# Create AI Search service
az search service create \
  --name "${PROJECT}-${ENV}-search" \
  --resource-group "${RG_NAME}" \
  --sku standard \
  --partition-count 1 \
  --replica-count 1

# Create model deployment (GPT-4o)
az cognitiveservices account deployment create \
  --name "${PROJECT}-${ENV}-openai" \
  --resource-group "${RG_NAME}" \
  --deployment-name gpt-4o \
  --model-name gpt-4o \
  --model-version "2024-05-13" \
  --model-format OpenAI \
  --sku-capacity 30 \
  --sku-name Standard
```

### 3. Configure Managed Identity Access
```bash
# Assign Cognitive Services User role to AKS identity
az role assignment create \
  --assignee "${AKS_IDENTITY_PRINCIPAL_ID}" \
  --role "Cognitive Services User" \
  --scope "/subscriptions/${SUB_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.CognitiveServices/accounts/${PROJECT}-${ENV}-openai"

# Get endpoint
az cognitiveservices account show \
  --name "${PROJECT}-${ENV}-openai" \
  --resource-group "${RG_NAME}" \
  --query "properties.endpoint" -o tsv
```

## Day-2 Operations

### Resource Management
```bash
# List AI Foundry workspaces
az ml workspace list -o table

# Show workspace details
az ml workspace show --name <workspace> --resource-group <rg>

# List compute resources
az ml compute list --workspace-name <workspace> --resource-group <rg>
```

### OpenAI Deployments
```bash
# List Cognitive Services accounts
az cognitiveservices account list -o table

# List deployments
az cognitiveservices account deployment list \
  --name <account> --resource-group <rg> -o table

# Check quota usage
az cognitiveservices usage list --location eastus2 -o table
```

### Model Testing
```bash
# Test chat completion
curl -X POST "https://<endpoint>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-15-preview" \
  -H "Content-Type: application/json" \
  -H "api-key: ${OPENAI_API_KEY}" \
  -d '{"messages":[{"role":"user","content":"Hello"}],"max_tokens":100}'

# Test with managed identity (from AKS pod)
curl -X POST "https://<endpoint>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-15-preview" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

## Project Files Reference
- **Terraform module:** `terraform/modules/ai-foundry/`
- **Golden Path templates:** `golden-paths/h3-innovation/` (7 AI templates)

## Best Practices
1. Configure content safety filters on all deployments
2. Implement rate limiting and retry logic
3. Use managed identity for authentication (never API keys in code)
4. Monitor token usage and set cost alerts
5. Enable diagnostic logging for compliance
6. Use private endpoints for production
7. Deploy models in LATAM-nearest region with quota

## Output Format
1. Command executed
2. Resource status
3. Deployment details
4. Recommendations

## Integration with Agents
Used by: @architect, @devops
