# =============================================================================
# EXTERNAL SECRETS OPERATOR MODULE - OUTPUTS
# =============================================================================

output "namespace" {
  value       = kubernetes_namespace.eso.metadata[0].name
  description = "Kubernetes namespace where ESO is installed"
}

output "managed_identity_id" {
  value       = azurerm_user_assigned_identity.eso.id
  description = "Resource ID of the managed identity for ESO"
}

output "managed_identity_client_id" {
  value       = azurerm_user_assigned_identity.eso.client_id
  description = "Client ID of the managed identity for ESO"
}

output "managed_identity_principal_id" {
  value       = azurerm_user_assigned_identity.eso.principal_id
  description = "Principal ID of the managed identity for ESO"
}

output "cluster_secret_store_name" {
  value       = kubernetes_manifest.cluster_secret_store.manifest.metadata.name
  description = "Name of the ClusterSecretStore resource"
}

output "helm_release_name" {
  value       = helm_release.external_secrets.name
  description = "Name of the Helm release"
}

output "helm_release_version" {
  value       = helm_release.external_secrets.version
  description = "Version of the installed Helm chart"
}

output "service_account_name" {
  value       = "${local.eso_release_name}-controller"
  description = "Name of the ESO controller service account"
}

output "external_secret_example" {
  value       = var.create_example_secret ? "platform-secrets" : null
  description = "Name of the example Kubernetes secret (if created)"
}
