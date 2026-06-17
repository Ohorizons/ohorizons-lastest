# =============================================================================
# BACKSTAGE MODULE — OUTPUTS
# =============================================================================

output "namespace" {
  description = "Kubernetes namespace where Backstage is deployed"
  value       = kubernetes_namespace.backstage.metadata[0].name
}

output "portal_name" {
  description = "Portal name used for branding"
  value       = var.portal_name
}

output "helm_release_name" {
  description = "Helm release name"
  value       = helm_release.backstage.name
}

output "helm_release_status" {
  description = "Helm release status"
  value       = helm_release.backstage.status
}

output "service_name" {
  description = "Backstage Kubernetes service name"
  value       = "backstage"
}

output "service_port" {
  description = "Backstage service port"
  value       = 7007
}
