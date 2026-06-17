# =============================================================================
# OPEN HORIZONS PLATFORM - ROOT TERRAFORM CONFIGURATION
# =============================================================================
#
# This is the main entry point that orchestrates all platform modules.
#
# Deployment Order:
#   1. Networking (VNet, subnets, NSGs, private DNS)
#   2. Security (Key Vault, managed identities)
#   3. AKS Cluster
#   4. Databases (PostgreSQL, Redis)
#   5. AI Foundry (OpenAI, AI Search, Content Safety)
#   6. Observability (Prometheus, Grafana)
#   7. ArgoCD (GitOps controller)
#
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.45"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5.40"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }

  # Backend configuration - uncomment and configure for your environment
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "open-horizons.tfstate"
  # }
}

# =============================================================================
# PROVIDERS
# =============================================================================

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.azure_subscription_id
}

provider "azuread" {
  tenant_id = var.azure_tenant_id
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  load_config_file       = false
}

# =============================================================================
# VARIABLES — defined in variables.tf
# =============================================================================

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}-${var.environment}"

  common_tags = merge(var.tags, {
    "open-horizons/customer"        = var.customer_name
    "open-horizons/environment"     = var.environment
    "open-horizons/deployment-mode" = var.deployment_mode
    "open-horizons/managed-by"      = "terraform"
    "open-horizons/version"         = "1.0.0"
  })

  # Deployment mode configurations
  deployment_configs = {
    express = {
      aks_node_count    = 3
      aks_node_size     = "Standard_D4s_v5"
      enable_ha         = false
      enable_monitoring = true
      enable_databases  = true
      enable_ai         = false
    }
    standard = {
      aks_node_count    = 5
      aks_node_size     = "Standard_D4s_v5"
      enable_ha         = true
      enable_monitoring = true
      enable_databases  = true
      enable_ai         = true
    }
    enterprise = {
      aks_node_count    = 10
      aks_node_size     = "Standard_D8s_v5"
      enable_ha         = true
      enable_monitoring = true
      enable_databases  = true
      enable_ai         = true
    }
  }

  config = local.deployment_configs[var.deployment_mode]
}

# =============================================================================
# RESOURCE GROUP
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# MODULE: NETWORKING
# =============================================================================

module "networking" {
  source = "./modules/networking"

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  vnet_cidr = "10.0.0.0/16"

  subnet_config = {
    aks_nodes_cidr         = "10.0.0.0/22"
    aks_pods_cidr          = "10.0.16.0/20"
    private_endpoints_cidr = "10.0.4.0/24"
    bastion_cidr           = "10.0.5.0/26"
    app_gateway_cidr       = "10.0.6.0/24"
  }

  enable_bastion     = var.deployment_mode == "enterprise"
  enable_app_gateway = var.deployment_mode == "enterprise"

  dns_zone_name   = var.domain_name
  create_dns_zone = true

  tags = local.common_tags
}

# =============================================================================
# MODULE: SECURITY
# =============================================================================

module "security" {
  source = "./modules/security"

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.azure_tenant_id

  aks_oidc_issuer_url = module.aks.oidc_issuer_url

  key_vault_config = {
    sku_name                      = "standard"
    soft_delete_retention_days    = 90
    purge_protection_enabled      = var.environment == "prod"
    enable_rbac_authorization     = true
    public_network_access_enabled = false
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      ip_rules                   = []
      virtual_network_subnet_ids = [module.networking.subnet_ids.aks_nodes]
    }
  }

  admin_group_id      = var.admin_group_id
  subnet_id           = module.networking.subnet_ids.private_endpoints
  private_dns_zone_id = module.networking.private_dns_zone_ids.keyvault

  workload_identities = {
    "backstage" = {
      namespace                   = "backstage"
      service_account             = "backstage"
      key_vault_role              = "Key Vault Secrets User"
      additional_role_assignments = []
    }
    "argocd" = {
      namespace                   = "argocd"
      service_account             = "argocd-server"
      key_vault_role              = "Key Vault Secrets User"
      additional_role_assignments = []
    }
  }

  tags = local.common_tags

  depends_on = [module.networking]
}

# =============================================================================
# MODULE: AKS
# =============================================================================

module "aks" {
  source = "./modules/aks-cluster"

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  kubernetes_version = "1.29"

  network_config = {
    vnet_id         = module.networking.vnet_id
    nodes_subnet_id = module.networking.subnet_ids.aks_nodes
    pods_subnet_id  = module.networking.subnet_ids.aks_pods
    network_plugin  = "azure"
    network_policy  = "calico"
    service_cidr    = "10.1.0.0/16"
    dns_service_ip  = "10.1.0.10"
  }

  default_node_pool = {
    name                = "system"
    node_count          = local.config.aks_node_count
    vm_size             = local.config.aks_node_size
    min_count           = local.config.aks_node_count
    max_count           = local.config.aks_node_count * 2
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    max_pods            = 110
    enable_auto_scaling = true
    zones               = local.config.enable_ha ? ["1", "2", "3"] : null
  }

  additional_node_pools = var.deployment_mode == "enterprise" ? {
    "workload" = {
      name                = "workload"
      node_count          = 5
      vm_size             = "Standard_D4s_v5"
      min_count           = 3
      max_count           = 20
      enable_auto_scaling = true
      max_pods            = 110
      node_labels = {
        "workload-type" = "application"
      }
      node_taints = []
      zones       = ["1", "2", "3"]
    }
  } : {}

  enable_workload_identity       = true
  enable_azure_policy            = true
  enable_defender                = var.environment == "prod"
  enable_image_cleaner           = true
  enable_cost_analysis           = true
  enable_vertical_pod_autoscaler = true

  admin_group_ids = [var.admin_group_id]

  private_dns_zone_id = module.networking.private_dns_zone_ids.aks

  tags = local.common_tags

  depends_on = [module.networking]
}

# =============================================================================
# MODULE: DATABASES
# =============================================================================

module "databases" {
  source = "./modules/databases"
  count  = var.enable_databases ? 1 : 0

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  subnet_id = module.networking.subnet_ids.private_endpoints

  private_dns_zone_ids = {
    postgres = module.networking.private_dns_zone_ids.postgres
    redis    = module.networking.private_dns_zone_ids.redis
  }

  postgresql_config = {
    enabled               = true
    sku_name              = var.deployment_mode == "express" ? "B_Standard_B1ms" : "GP_Standard_D2s_v3"
    storage_mb            = 32768
    version               = "16"
    admin_username        = "pgadmin"
    backup_retention_days = var.environment == "prod" ? 35 : 7
    geo_redundant_backup  = var.environment == "prod"
    high_availability     = local.config.enable_ha
    databases             = ["backstage"]
  }

  redis_config = {
    enabled             = true
    sku_name            = var.deployment_mode == "express" ? "Basic" : "Standard"
    family              = "C"
    capacity            = var.deployment_mode == "express" ? 0 : 1
    enable_non_ssl_port = false
    minimum_tls_version = "1.2"
    maxmemory_policy    = "volatile-lru"
  }

  key_vault_id = module.security.key_vault_id

  tags = local.common_tags

  depends_on = [module.networking, module.security]
}

# =============================================================================
# MODULE: AI FOUNDRY (H3)
# =============================================================================

module "ai_foundry" {
  source = "./modules/ai-foundry"
  count  = var.enable_ai_foundry && local.config.enable_ai ? 1 : 0

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.ai_foundry_location
  resource_group_name = azurerm_resource_group.main.name

  subnet_id = module.networking.subnet_ids.private_endpoints

  private_dns_zone_ids = {
    openai            = module.networking.private_dns_zone_ids.openai
    cognitiveservices = module.networking.private_dns_zone_ids.cognitiveservices
    search            = module.networking.private_dns_zone_ids.search
  }

  openai_config = {
    enabled  = true
    sku_name = "S0"
    models = [
      {
        name          = "gpt-4o"
        model_name    = "gpt-4o"
        model_version = "2024-05-13"
        capacity      = var.deployment_mode == "enterprise" ? 60 : 30
        rai_policy    = "Microsoft.Default"
      },
      {
        name          = "gpt-4o-mini"
        model_name    = "gpt-4o-mini"
        model_version = "2024-07-18"
        capacity      = 100
        rai_policy    = "Microsoft.Default"
      },
      {
        name          = "text-embedding-3-large"
        model_name    = "text-embedding-3-large"
        model_version = "1"
        capacity      = 100
        rai_policy    = "Microsoft.Default"
      }
    ]
  }

  ai_search_config = {
    enabled                       = true
    sku_name                      = var.deployment_mode == "enterprise" ? "standard2" : "standard"
    replica_count                 = var.deployment_mode == "enterprise" ? 2 : 1
    partition_count               = 1
    semantic_search_sku           = "standard"
    public_network_access_enabled = false
  }

  content_safety_config = {
    enabled  = true
    sku_name = "S0"
  }

  key_vault_id               = module.security.key_vault_id
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.networking, module.security]
}

# =============================================================================
# MODULE: OBSERVABILITY
# =============================================================================

module "observability" {
  source = "./modules/observability"
  count  = var.enable_observability ? 1 : 0

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  aks_cluster_id = module.aks.cluster_id

  grafana_admin_group_id  = var.admin_group_id
  grafana_viewer_group_id = ""

  enable_container_insights = true
  retention_days            = var.environment == "prod" ? 90 : 30

  alert_email_receivers = var.alert_emails

  tags = local.common_tags

  depends_on = [module.aks]
}

# =============================================================================
# MODULE: ARGOCD
# =============================================================================

module "argocd" {
  source = "./modules/argocd"
  count  = var.enable_argocd ? 1 : 0

  customer_name = var.customer_name
  environment   = var.environment
  namespace     = "argocd"

  chart_version = "5.51.0"

  domain_name = var.domain_name
  github_org  = var.github_org

  github_app_id            = var.github_app_id
  github_app_client_id     = var.github_app_client_id
  github_app_client_secret = var.github_app_client_secret

  admin_password_hash = var.argocd_admin_password

  ha_enabled     = local.config.enable_ha
  ingress_class  = "nginx"
  cluster_issuer = "letsencrypt-prod"

  azure_ad_admin_group_id = var.admin_group_id

  tags = local.common_tags

  depends_on = [module.aks, module.security]
}

# =============================================================================
# MODULE: CONTAINER REGISTRY (H1)
# =============================================================================

module "container_registry" {
  source = "./modules/container-registry"
  count  = var.enable_container_registry ? 1 : 0

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  sku                       = var.deployment_mode == "express" ? "Standard" : "Premium"
  zone_redundancy_enabled   = var.deployment_mode == "enterprise"
  admin_enabled             = false
  public_network_access_enabled = var.deployment_mode == "express"

  subnet_id           = module.networking.subnet_ids.private_endpoints
  private_dns_zone_id = module.networking.private_dns_zone_ids.acr

  aks_kubelet_identity_id = module.aks.kubelet_identity.object_id

  tags = local.common_tags

  depends_on = [module.networking, module.aks]
}

# =============================================================================
# MODULE: EXTERNAL SECRETS (H2)
# =============================================================================

module "external_secrets" {
  source = "./modules/external-secrets"
  count  = var.enable_external_secrets ? 1 : 0

  namespace        = "external-secrets"
  chart_version    = "0.9.9"
  key_vault_name   = module.security.keyvault_name
  tenant_id        = var.azure_tenant_id

  tags = local.common_tags

  depends_on = [module.aks, module.security]
}

# =============================================================================
# MODULE: GITHUB RUNNERS (H2)
# =============================================================================

module "github_runners" {
  source = "./modules/github-runners"
  count  = var.enable_github_runners ? 1 : 0

  namespace                   = "github-runners"
  github_org                  = var.github_org
  github_app_id               = var.github_app_id
  github_app_installation_id  = var.github_app_installation_id
  github_app_private_key      = var.github_app_private_key
  runner_scale_set_name       = "arc-runners"
  min_runners                 = 1
  max_runners                 = var.deployment_mode == "enterprise" ? 10 : 5

  tags = local.common_tags

  depends_on = [module.aks]
}

# =============================================================================
# MODULE: DEFENDER (H1 — Optional)
# =============================================================================

module "defender" {
  source = "./modules/defender"
  count  = var.enable_defender ? 1 : 0

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  enable_container_plan     = true
  enable_servers_plan       = var.deployment_mode == "enterprise"
  enable_storage_plan       = var.deployment_mode == "enterprise"
  enable_key_vault_plan     = true
  enable_dns_plan           = false

  tags = local.common_tags
}

# =============================================================================
# MODULE: PURVIEW (H1 — Optional)
# =============================================================================

module "purview" {
  source = "./modules/purview"
  count  = var.enable_purview ? 1 : 0

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  subnet_id           = module.networking.subnet_ids.private_endpoints
  admin_group_id      = var.admin_group_id

  tags = local.common_tags

  depends_on = [module.networking]
}

# =============================================================================
# MODULE: COST MANAGEMENT (Cross-cutting)
# =============================================================================

module "cost_management" {
  source = "./modules/cost-management"
  count  = var.enable_cost_management ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  subscription_id     = var.azure_subscription_id
  budget_amount       = var.budget_amount
  alert_thresholds    = [50, 75, 90, 100]
  alert_emails        = var.alert_emails

  tags = local.common_tags
}

# =============================================================================
# MODULE: DISASTER RECOVERY (Cross-cutting)
# =============================================================================

module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  count  = var.enable_disaster_recovery ? 1 : 0

  customer_name       = var.customer_name
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name

  primary_location   = var.location
  secondary_location = var.dr_location

  enable_aks_dr               = var.deployment_mode == "enterprise"
  enable_database_replication = true
  enable_storage_replication  = true

  tags = local.common_tags
}

# =============================================================================
# OUTPUTS — defined in outputs.tf
# =============================================================================
