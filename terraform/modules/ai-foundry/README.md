# AI Foundry Module

Azure AI Foundry integration for H3 Innovation workloads - a comprehensive enterprise AI platform.

## Overview

Azure AI Foundry is a unified hub for building, deploying, and managing AI solutions at scale. This module provisions the core Azure AI services that power the platform:

- **Multiple AI Providers:** Azure OpenAI (GPT-4, GPT-4o), with support for Anthropic Claude, Meta Llama, Mistral
- **AI Search:** Semantic search, vector embeddings, and knowledge retrieval
- **Content Safety:** Responsible AI controls, content filtering, and prompt shields
- **Agent Capabilities:** Infrastructure for building autonomous AI agents

## Features

- Azure OpenAI Service with model deployments
- Azure AI Search with semantic search and vector capabilities
- Azure AI Content Safety for responsible AI
- Private endpoint connectivity (enterprise security)
- Key Vault secrets integration
- Managed Identity authentication
- Diagnostic settings and monitoring

## Usage

```hcl
module "ai_foundry" {
  source = "./modules/ai-foundry"

  customer_name       = "threehorizons"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.networking.private_endpoints_subnet_id
  key_vault_id        = module.security.key_vault_id

  openai_config = {
    enabled  = true
    sku_name = "S0"
    models = [
      {
        name          = "gpt-4o"
        model_name    = "gpt-4o"
        model_version = "2024-05-13"
        capacity      = 10
        rai_policy    = "Microsoft.Default"
      },
      {
        name          = "text-embedding"
        model_name    = "text-embedding-3-large"
        model_version = "1"
        capacity      = 10
        rai_policy    = "Microsoft.Default"
      }
    ]
  }

  ai_search_config = {
    enabled                       = true
    sku_name                      = "standard"
    replica_count                 = 2
    partition_count               = 1
    public_network_access_enabled = false
    semantic_search_sku           = "standard"
  }

  content_safety_config = {
    enabled  = true
    sku_name = "S0"
  }

  private_dns_zone_ids = {
    openai            = module.networking.private_dns_zone_ids["privatelink.openai.azure.com"]
    search            = module.networking.private_dns_zone_ids["privatelink.search.windows.net"]
    cognitiveservices = module.networking.private_dns_zone_ids["privatelink.cognitiveservices.azure.com"]
  }

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name for resource naming | `string` | n/a | yes |
| environment | Environment (dev, staging, prod) | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| subnet_id | Subnet ID for private endpoints | `string` | n/a | yes |
| key_vault_id | Key Vault ID for storing secrets | `string` | n/a | yes |
| openai_config | OpenAI service configuration | `object` | n/a | yes |
| ai_search_config | AI Search configuration | `object` | n/a | yes |
| content_safety_config | Content Safety configuration | `object` | n/a | yes |
| private_dns_zone_ids | Map of private DNS zone IDs | `map(string)` | n/a | yes |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `""` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| openai_endpoint | OpenAI service endpoint |
| openai_id | OpenAI service resource ID |
| search_endpoint | AI Search endpoint |
| search_id | AI Search resource ID |
| content_safety_endpoint | Content Safety endpoint |

## Model Deployments

The module supports deploying multiple OpenAI models:
- GPT-4o for chat completions
- GPT-4 Turbo for advanced reasoning
- Text embeddings for vector search
- DALL-E 3 for image generation

## Security Considerations

- All services deployed with private endpoints
- Public network access disabled
- API keys stored in Key Vault
- RAI policies applied to model deployments
- Diagnostic logs sent to Log Analytics
