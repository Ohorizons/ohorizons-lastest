terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    # Azure Managed Redis (Microsoft.Cache/redisEnterprise) is provisioned via
    # azapi because the classic azurerm_redis_cache resource targets the
    # retiring Azure Cache for Redis service. azapi 2.x uses native HCL `body`.
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.8"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
