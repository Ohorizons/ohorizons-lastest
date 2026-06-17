# =============================================================================
# OPEN HORIZONS PLATFORM - OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# CORE
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "dns_name_servers" {
  description = "DNS name servers (configure at your registrar)"
  value       = module.networking.public_dns_zone_name_servers
}

# -----------------------------------------------------------------------------
# AKS CLUSTER
# -----------------------------------------------------------------------------

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "kube_config" {
  description = "Kubernetes config for kubectl"
  value       = module.aks.kube_config
  sensitive   = true
}

# -----------------------------------------------------------------------------
# SECURITY
# -----------------------------------------------------------------------------

output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = module.security.keyvault_name
}

output "keyvault_uri" {
  description = "URI of the Key Vault"
  value       = module.security.keyvault_uri
}

# -----------------------------------------------------------------------------
# OPTIONAL MODULES
# -----------------------------------------------------------------------------

output "postgresql_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = var.enable_databases ? module.databases[0].server_fqdn : null
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = var.enable_container_registry ? module.container_registry[0].login_server : null
}

output "argocd_url" {
  description = "ArgoCD dashboard URL"
  value       = var.enable_argocd ? "https://argocd.${var.domain_name}" : null
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = var.enable_observability ? module.observability[0].grafana_endpoint : null
}

output "ai_foundry_endpoint" {
  description = "Azure AI Foundry endpoint"
  value       = var.enable_ai_foundry ? module.ai_foundry[0].endpoint : null
}

# -----------------------------------------------------------------------------
# DEPLOYMENT SUMMARY
# -----------------------------------------------------------------------------

output "deployment_summary" {
  description = "Summary of deployed platform"
  value = {
    customer    = var.customer_name
    environment = var.environment
    location    = var.location
    mode        = var.deployment_mode

    h1_foundation = {
      aks            = true
      networking     = true
      security       = true
      databases      = var.enable_databases
      acr            = var.enable_container_registry
      defender       = var.enable_defender
      purview        = var.enable_purview
    }

    h2_enhancement = {
      argocd           = var.enable_argocd
      external_secrets = var.enable_external_secrets
      observability    = var.enable_observability
      github_runners   = var.enable_github_runners
    }

    h3_innovation = {
      ai_foundry = var.enable_ai_foundry
    }

    cross_cutting = {
      cost_management    = var.enable_cost_management
      disaster_recovery  = var.enable_disaster_recovery
    }
  }
}

output "next_steps" {
  description = "Post-deployment instructions"
  value = <<-EOT

    OPEN HORIZONS PLATFORM DEPLOYED SUCCESSFULLY!

    Next Steps:

    1. Get AKS credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}

    2. Verify cluster:
       kubectl get nodes
       kubectl get pods -A

    3. Access services:
       ${var.enable_argocd ? "ArgoCD:  https://argocd.${var.domain_name}" : ""}
       ${var.enable_observability ? "Grafana: kubectl port-forward svc/prometheus-grafana -n observability 3000:80" : ""}

    4. Run validation:
       ./scripts/validate-deployment.sh --environment ${var.environment}

  EOT
}