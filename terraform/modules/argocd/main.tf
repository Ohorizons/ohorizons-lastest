# =============================================================================
# OPEN HORIZONS PLATFORM - ARGOCD TERRAFORM MODULE
# =============================================================================
#
# Installs and configures ArgoCD on AKS for GitOps deployments.
#
# Features:
#   - HA deployment (3 replicas)
#   - GitHub SSO integration
#   - RBAC with Azure AD groups
#   - ApplicationSet controller
#   - Notifications (Slack, Teams)
#   - Prometheus metrics
#   - Ingress with TLS
#
# =============================================================================

# NOTE: Terraform block is in versions.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  argocd_hostname = "argocd.${var.domain_name}"

  replicas = var.ha_enabled ? 3 : 1

  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "open-horizons/customer"      = var.customer_name
    "open-horizons/environment"   = var.environment
  }
}

# =============================================================================
# NAMESPACE
# =============================================================================

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = merge(local.common_labels, {
      "app.kubernetes.io/name" = "argocd"
    })
  }
}

# =============================================================================
# SECRETS
# =============================================================================

resource "kubernetes_secret" "github_app" {
  metadata {
    name      = "argocd-github-app"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "dex.github.clientId"     = var.github_app_client_id
    "dex.github.clientSecret" = var.github_app_client_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "notifications" {
  count = var.slack_webhook_url != "" || var.teams_webhook_url != "" ? 1 : 0

  metadata {
    name      = "argocd-notifications-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "slack-token"       = var.slack_webhook_url
    "teams-webhook-url" = var.teams_webhook_url
  }

  type = "Opaque"
}

# =============================================================================
# HELM RELEASE
# =============================================================================

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    # -------------------------------------------------------------------------
    # Global Configuration
    # -------------------------------------------------------------------------
    global = {
      domain = local.argocd_hostname

      logging = {
        format = "json"
        level  = "info"
      }
    }

    # -------------------------------------------------------------------------
    # Controller
    # -------------------------------------------------------------------------
    controller = {
      replicas = local.replicas

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

      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }

      topologySpreadConstraints = var.ha_enabled ? [
        {
          maxSkew           = 1
          topologyKey       = "topology.kubernetes.io/zone"
          whenUnsatisfiable = "ScheduleAnyway"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name" = "argocd-application-controller"
            }
          }
        }
      ] : []
    }

    # -------------------------------------------------------------------------
    # Server
    # -------------------------------------------------------------------------
    server = {
      replicas = local.replicas

      autoscaling = {
        enabled     = var.ha_enabled
        minReplicas = local.replicas
        maxReplicas = 5
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      # Ingress configuration
      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class

        annotations = {
          "cert-manager.io/cluster-issuer"                 = var.cluster_issuer
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
          "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
        }

        hosts = [local.argocd_hostname]

        tls = [
          {
            secretName = "argocd-server-tls"
            hosts      = [local.argocd_hostname]
          }
        ]
      }

      # Extra args
      extraArgs = [
        "--insecure" # TLS termination at ingress
      ]

      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }

      topologySpreadConstraints = var.ha_enabled ? [
        {
          maxSkew           = 1
          topologyKey       = "topology.kubernetes.io/zone"
          whenUnsatisfiable = "ScheduleAnyway"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name" = "argocd-server"
            }
          }
        }
      ] : []
    }

    # -------------------------------------------------------------------------
    # Repo Server
    # -------------------------------------------------------------------------
    repoServer = {
      replicas = local.replicas

      autoscaling = {
        enabled     = var.ha_enabled
        minReplicas = local.replicas
        maxReplicas = 5
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }

      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    }

    # -------------------------------------------------------------------------
    # Application Set Controller
    # -------------------------------------------------------------------------
    applicationSet = {
      enabled  = true
      replicas = var.ha_enabled ? 2 : 1

      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }

      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    }

    # -------------------------------------------------------------------------
    # Notifications Controller
    # -------------------------------------------------------------------------
    notifications = {
      enabled = var.slack_webhook_url != "" || var.teams_webhook_url != ""

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }

      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }

      # Notification templates
      templates = {
        "template.app-deployed" = <<-EOT
          message: |
            {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application *{{.app.metadata.name}}* is now running new version.
            {{if ne .serviceType "slack"}}✅{{end}}
          slack:
            attachments: |
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#18be52",
                "fields": [
                  {
                    "title": "Sync Status",
                    "value": "{{.app.status.sync.status}}",
                    "short": true
                  },
                  {
                    "title": "Repository",
                    "value": "{{.app.spec.source.repoURL}}",
                    "short": true
                  }
                ]
              }]
        EOT

        "template.app-sync-failed" = <<-EOT
          message: |
            {{if eq .serviceType "slack"}}:x:{{end}} Application *{{.app.metadata.name}}* sync failed.
            {{if ne .serviceType "slack"}}❌{{end}}
          slack:
            attachments: |
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#E96D76",
                "fields": [
                  {
                    "title": "Sync Status",
                    "value": "{{.app.status.sync.status}}",
                    "short": true
                  },
                  {
                    "title": "Message",
                    "value": "{{.app.status.operationState.message}}",
                    "short": false
                  }
                ]
              }]
        EOT
      }

      # Notification triggers
      triggers = {
        "trigger.on-deployed" = <<-EOT
          - when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
            oncePer: app.status.sync.revision
            send: [app-deployed]
        EOT

        "trigger.on-sync-failed" = <<-EOT
          - when: app.status.operationState.phase in ['Error', 'Failed']
            send: [app-sync-failed]
        EOT
      }
    }

    # -------------------------------------------------------------------------
    # Redis (for HA)
    # -------------------------------------------------------------------------
    redis-ha = {
      enabled = var.ha_enabled

      haproxy = {
        enabled = true
      }
    }

    redis = {
      enabled = !var.ha_enabled
    }

    # -------------------------------------------------------------------------
    # Dex (SSO)
    # -------------------------------------------------------------------------
    dex = {
      enabled = true

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }

    # -------------------------------------------------------------------------
    # Config
    # -------------------------------------------------------------------------
    configs = {
      # Admin password
      secret = {
        argocdServerAdminPassword = var.admin_password_hash
      }

      # CM configuration
      cm = {
        # URL
        "url" = "https://${local.argocd_hostname}"

        # Dex configuration for GitHub SSO
        "dex.config" = yamlencode({
          connectors = [
            {
              type = "github"
              id   = "github"
              name = "GitHub"
              config = {
                clientID     = "$dex.github.clientId"
                clientSecret = "$dex.github.clientSecret"
                orgs = [
                  {
                    name = var.github_org
                  }
                ]
              }
            }
          ]
        })

        # Resource tracking
        "application.resourceTrackingMethod" = "annotation"

        # Health assessments
        "resource.customizations.health.argoproj.io_Application" = <<-EOT
          hs = {}
          hs.status = "Healthy"
          hs.message = ""
          if obj.status ~= nil then
            if obj.status.health ~= nil then
              hs.status = obj.status.health.status
              if obj.status.health.message ~= nil then
                hs.message = obj.status.health.message
              end
            end
          end
          return hs
        EOT
      }

      # RBAC configuration
      rbac = {
        "policy.default" = "role:readonly"

        "policy.csv" = <<-EOT
          # Admin access for GitHub org admins
          g, ${var.github_org}:platform-admins, role:admin
          
          # Read-only for all org members
          g, ${var.github_org}:*, role:readonly
          
          # Team-specific access (team name = ArgoCD project)
          p, role:team-member, applications, get, */*, allow
          p, role:team-member, applications, sync, */*, allow
          p, role:team-member, applications, action/*, */*, allow
          p, role:team-member, logs, get, */*, allow
        EOT

        "scopes" = "[groups]"
      }

      # Parameters
      params = {
        "server.insecure" = true # TLS at ingress level
      }

      # Repository credentials (template)
      credentialTemplates = {
        "github-https" = {
          url      = "https://github.com/${var.github_org}"
          password = "$github-app-client-secret"
          username = "not-used"
        }
      }
    }
  })]

  depends_on = [
    kubernetes_secret.github_app,
    kubernetes_secret.notifications
  ]
}

# =============================================================================
# PLATFORM PROJECT
# =============================================================================

resource "kubectl_manifest" "platform_project" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform"
      namespace = var.namespace
      labels    = local.common_labels
    }
    spec = {
      description = "Open Horizons Platform Components"

      sourceRepos = [
        "https://github.com/${var.github_org}/*",
        "https://charts.jetstack.io",
        "https://kubernetes.github.io/ingress-nginx",
        "https://prometheus-community.github.io/helm-charts",
        "https://grafana.github.io/helm-charts",
        "https://jaegertracing.github.io/helm-charts",
        "https://charts.bitnami.com/bitnami",
        "registry-1.docker.io"
      ]

      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]

      clusterResourceWhitelist = [
        { group = "", kind = "Namespace" },
        { group = "", kind = "PersistentVolume" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRole" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRoleBinding" },
        { group = "apiextensions.k8s.io", kind = "CustomResourceDefinition" },
        { group = "admissionregistration.k8s.io", kind = "ValidatingWebhookConfiguration" },
        { group = "admissionregistration.k8s.io", kind = "MutatingWebhookConfiguration" },
        { group = "networking.k8s.io", kind = "IngressClass" },
        { group = "storage.k8s.io", kind = "StorageClass" },
        { group = "cert-manager.io", kind = "ClusterIssuer" },
        { group = "monitoring.coreos.com", kind = "*" }
      ]

      namespaceResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
    }
  })

  depends_on = [helm_release.argocd]
}

# =============================================================================
# OUTPUTS
# =============================================================================


