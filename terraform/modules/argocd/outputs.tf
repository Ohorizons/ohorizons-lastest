output "namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "hostname" {
  description = "ArgoCD hostname"
  value       = local.argocd_hostname
}

output "url" {
  description = "ArgoCD URL"
  value       = "https://${local.argocd_hostname}"
}

output "server_service" {
  description = "ArgoCD server service name"
  value       = "argocd-server"
}

output "platform_project" {
  description = "Platform AppProject name"
  value       = "platform"
}
