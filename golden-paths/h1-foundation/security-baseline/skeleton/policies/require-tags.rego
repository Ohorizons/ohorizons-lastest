package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Deployment"
  not input.request.object.metadata.labels.app
  msg := "Deployments must have an app label"
}
