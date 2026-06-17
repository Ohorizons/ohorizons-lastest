# =============================================================================
# AGENTIC DEVOPS PLATFORM — BACKSTAGE MODULE
# =============================================================================
# Deploys upstream Backstage on AKS via Helm.
# Supports custom portal name, GitHub App auth, PostgreSQL, and TechDocs.
# =============================================================================

locals {
  common_labels = {
    "app.kubernetes.io/part-of"    = "backstage"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/component"  = "developer-portal"
  }
  portal_name = var.portal_name
}

# --- Namespace ---
resource "kubernetes_namespace" "backstage" {
  metadata {
    name   = var.namespace
    labels = local.common_labels
  }
}

# --- GitHub App Secret ---
resource "kubernetes_secret" "github_app" {
  metadata {
    name      = "backstage-github-app"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "app-id"        = var.github_app_id
    "client-id"     = var.github_app_client_id
    "client-secret" = var.github_app_client_secret
    "private-key"   = var.github_app_private_key
  }

  type = "Opaque"
}

# --- PostgreSQL Connection Secret ---
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "backstage-db-credentials"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "host"     = var.database_host
    "port"     = tostring(var.database_port)
    "user"     = var.database_user
    "password" = var.database_password
  }

  type = "Opaque"
}

# --- Helm Release ---
resource "helm_release" "backstage" {
  name       = "backstage"
  namespace  = kubernetes_namespace.backstage.metadata[0].name
  repository = "https://backstage.github.io/charts"
  chart      = "backstage"
  version    = var.backstage_chart_version

  values = [yamlencode({
    backstage = {
      replicas = var.replicas

      image = {
        registry   = var.image_registry
        repository = var.image_repository
        tag        = var.image_tag
      }

      command = ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]

      resources = {
        requests = {
          cpu    = "250m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
      }

      extraEnvVars = [
        { name = "APP_BASE_URL", value = var.base_url },
        { name = "POSTGRES_HOST", valueFrom = { secretKeyRef = { name = kubernetes_secret.db_credentials.metadata[0].name, key = "host" } } },
        { name = "POSTGRES_PORT", valueFrom = { secretKeyRef = { name = kubernetes_secret.db_credentials.metadata[0].name, key = "port" } } },
        { name = "POSTGRES_USER", valueFrom = { secretKeyRef = { name = kubernetes_secret.db_credentials.metadata[0].name, key = "user" } } },
        { name = "POSTGRES_PASSWORD", valueFrom = { secretKeyRef = { name = kubernetes_secret.db_credentials.metadata[0].name, key = "password" } } },
        { name = "GITHUB_APP_ID", valueFrom = { secretKeyRef = { name = kubernetes_secret.github_app.metadata[0].name, key = "app-id" } } },
        { name = "GITHUB_APP_CLIENT_ID", valueFrom = { secretKeyRef = { name = kubernetes_secret.github_app.metadata[0].name, key = "client-id" } } },
        { name = "GITHUB_APP_CLIENT_SECRET", valueFrom = { secretKeyRef = { name = kubernetes_secret.github_app.metadata[0].name, key = "client-secret" } } },
        { name = "GITHUB_APP_PRIVATE_KEY", valueFrom = { secretKeyRef = { name = kubernetes_secret.github_app.metadata[0].name, key = "private-key" } } },
      ]
    }

    service = {
      type = "ClusterIP"
      ports = {
        backend    = 7007
        targetPort = "backend"
      }
    }

    postgresql = {
      enabled = false
    }
  })]

  wait    = true
  timeout = 600
}

# --- Ingress (optional) ---
resource "kubernetes_ingress_v1" "backstage" {
  count = var.ingress_enabled ? 1 : 0

  metadata {
    name      = "backstage-ingress"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels    = local.common_labels
    annotations = {
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"  = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "backstage-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "backstage"
              port {
                number = 7007
              }
            }
          }
        }
      }
    }
  }
}
