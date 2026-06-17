output "namespace" {
  description = "Runners namespace"
  value       = kubernetes_namespace.runners.metadata[0].name
}

output "controller_service_account" {
  description = "Controller service account name"
  value       = "arc-controller"
}

output "runner_service_accounts" {
  description = "Runner service account names by group"
  value = {
    for name, sa in kubernetes_service_account.runner : name => sa.metadata[0].name
  }
}

output "runner_groups" {
  description = "Configured runner groups"
  value = {
    for name, group in var.runner_groups : name => {
      runner_group = group.runner_group
      min_runners  = group.min_runners
      max_runners  = group.max_runners
    }
  }
}

output "github_org" {
  description = "GitHub organization for runners"
  value       = var.github_org
}

output "scale_set_id" {
  description = "Runner scale set ID"
  value       = kubernetes_manifest.runner_scale_set.object.metadata.uid
}
