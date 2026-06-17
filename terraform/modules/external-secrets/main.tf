# =============================================================================
# OPEN HORIZONS PLATFORM - EXTERNAL SECRETS OPERATOR MODULE
# =============================================================================
#
# Deploys External Secrets Operator with Azure Key Vault integration.
# Uses Workload Identity for secure, secretless authentication.
#
# Features:
#   - External Secrets Operator via Helm
#   - Azure Key Vault ClusterSecretStore
#   - Workload Identity configuration
#   - RBAC for Key Vault access
#
# =============================================================================

# -----------------------------------------------------------------------------
# LOCAL VALUES
# -----------------------------------------------------------------------------

locals {
  eso_namespace     = var.namespace
  eso_release_name  = "external-secrets"
  secret_store_name = "${var.customer_name}-${var.environment}-secret-store"

  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "open-horizons-platform"
    "platform.open-horizons/tier" = "security"
  }
}

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

# -----------------------------------------------------------------------------
# MANAGED IDENTITY FOR ESO
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "eso" {
  name                = "id-${var.customer_name}-${var.environment}-eso"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Federated Identity Credential for Workload Identity
resource "azurerm_federated_identity_credential" "eso" {
  name                = "eso-federated-credential"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.eso.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${local.eso_namespace}:${local.eso_release_name}-controller"
}

# -----------------------------------------------------------------------------
# KEY VAULT ACCESS POLICY
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "eso" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.eso.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  certificate_permissions = [
    "Get",
    "List",
  ]
}

# Alternative: RBAC Role Assignment (if Key Vault uses RBAC)
resource "azurerm_role_assignment" "eso_secrets_user" {
  count                = var.use_key_vault_rbac ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.eso.principal_id
}

# -----------------------------------------------------------------------------
# KUBERNETES NAMESPACE
# -----------------------------------------------------------------------------

resource "kubernetes_namespace" "eso" {
  metadata {
    name = local.eso_namespace

    labels = merge(local.common_labels, {
      "name" = local.eso_namespace
    })

    annotations = {
      "meta.helm.sh/release-name"      = local.eso_release_name
      "meta.helm.sh/release-namespace" = local.eso_namespace
    }
  }
}

# -----------------------------------------------------------------------------
# EXTERNAL SECRETS OPERATOR - HELM RELEASE
# -----------------------------------------------------------------------------

resource "helm_release" "external_secrets" {
  name             = local.eso_release_name
  namespace        = kubernetes_namespace.eso.metadata[0].name
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.eso_chart_version
  create_namespace = false
  atomic           = true
  timeout          = 600

  values = [
    yamlencode({
      installCRDs = true

      serviceAccount = {
        create = true
        name   = "${local.eso_release_name}-controller"
        annotations = {
          "azure.workload.identity/client-id" = azurerm_user_assigned_identity.eso.client_id
        }
      }

      podLabels = {
        "azure.workload.identity/use" = "true"
      }

      webhook = {
        serviceAccount = {
          create = true
          name   = "${local.eso_release_name}-webhook"
        }
      }

      certController = {
        serviceAccount = {
          create = true
          name   = "${local.eso_release_name}-cert-controller"
        }
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }

      prometheus = {
        enabled = var.enable_prometheus_metrics
        service = {
          port = 8080
        }
      }

      nodeSelector = var.node_selector

      tolerations = var.tolerations
    })
  ]

  depends_on = [
    azurerm_federated_identity_credential.eso
  ]
}

# -----------------------------------------------------------------------------
# CLUSTER SECRET STORE - AZURE KEY VAULT
# -----------------------------------------------------------------------------

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = local.secret_store_name
      labels = merge(local.common_labels, {
        "app.kubernetes.io/name" = "azure-keyvault-store"
      })
    }
    spec = {
      provider = {
        azurekv = {
          authType = "WorkloadIdentity"
          vaultUrl = var.key_vault_uri
          tenantId = data.azurerm_client_config.current.tenant_id
          serviceAccountRef = {
            name      = "${local.eso_release_name}-controller"
            namespace = local.eso_namespace
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.external_secrets
  ]
}

# -----------------------------------------------------------------------------
# EXAMPLE EXTERNAL SECRET (Optional)
# -----------------------------------------------------------------------------

resource "kubernetes_manifest" "example_external_secret" {
  count = var.create_example_secret ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "platform-secrets-example"
      namespace = "default"
      labels    = local.common_labels
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = local.secret_store_name
      }
      target = {
        name           = "platform-secrets"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "github-token"
          remoteRef = {
            key = "github-pat"
          }
        },
        {
          secretKey = "acr-password"
          remoteRef = {
            key = "acr-password"
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.cluster_secret_store
  ]
}

# -----------------------------------------------------------------------------
# PUSH SECRET CONFIGURATION (Optional - for syncing secrets to Key Vault)
# -----------------------------------------------------------------------------

resource "kubernetes_manifest" "push_secret_store" {
  count = var.enable_push_secrets ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1alpha1"
    kind       = "PushSecret"
    metadata = {
      name      = "push-to-keyvault"
      namespace = local.eso_namespace
    }
    spec = {
      updatePolicy    = "Replace"
      deletionPolicy  = "Delete"
      refreshInterval = "1h"
      secretStoreRefs = [
        {
          name = local.secret_store_name
          kind = "ClusterSecretStore"
        }
      ]
      selector = {
        secret = {
          name = "secrets-to-push"
        }
      }
      data = [
        {
          match = {
            secretKey = "api-key"
            remoteRef = {
              remoteKey = "pushed-api-key"
            }
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.cluster_secret_store
  ]
}
