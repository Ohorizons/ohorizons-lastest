---
name: observability-stack
description: "Observability stack — deploy Prometheus, Grafana, Loki, and Alertmanager, plus day-2 monitoring operations. USE FOR: deploy Prometheus, configure Grafana, setup Loki, Alertmanager rules, monitoring dashboards, observability troubleshooting. DO NOT USE FOR: application logging code, Terraform IaC (use terraform-cli), CI/CD pipelines (use @devops)."
---

## When to Use
- Deploy observability stack (Prometheus, Grafana, Alertmanager)
- Configure monitoring for platform components
- Create and manage Grafana dashboards
- Configure alerting rules and notification channels
- Troubleshoot with metrics and logs

## Prerequisites
- kubectl access to target cluster
- Helm 3.12+ installed
- AKS cluster deployed (H1 Foundation)

## Installation & Deployment

### 1. Deploy kube-prometheus-stack
```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack with project values
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values deploy/helm/monitoring/values.yaml \
  --wait --timeout 15m

# Verify all pods are running
kubectl get pods -n monitoring
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=monitoring -n monitoring --timeout=600s
```

### 2. Deploy Custom Dashboards
```bash
# Create ConfigMap from project dashboards
kubectl create configmap grafana-dashboards \
  --namespace monitoring \
  --from-file=grafana/dashboards/ \
  --dry-run=client -o yaml | kubectl apply -f -

# Label for Grafana sidecar auto-discovery
kubectl label configmap grafana-dashboards \
  --namespace monitoring \
  grafana_dashboard=1
```

### 3. Deploy Custom Alert Rules
```bash
# Apply Prometheus alerting rules
kubectl apply -f prometheus/alerting-rules.yaml -n monitoring

# Apply recording rules
kubectl apply -f prometheus/recording-rules.yaml -n monitoring

# Validate rules syntax
promtool check rules prometheus/alerting-rules.yaml
promtool check rules prometheus/recording-rules.yaml
```

### 4. Verify Installation
```bash
# Check all components
kubectl get pods -n monitoring

# Port-forward Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Port-forward Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'

# Verify Grafana datasources
curl -s -u admin:prom-operator http://localhost:3000/api/datasources | jq '.[].name'
```

## Day-2 Operations

### Prometheus Operations
```bash
# Check Prometheus status
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

# Port forward Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Query Prometheus API
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result'

# Check targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
```

### Grafana Operations
```bash
# Check Grafana status
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Port forward Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# List data sources
curl -s -u admin:prom-operator http://localhost:3000/api/datasources | jq '.[].name'
```

### Alert Management
```bash
# Check alertmanager
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

# List active alerts
curl -s http://localhost:9093/api/v2/alerts | jq '.[].labels.alertname'

# Validate Prometheus rules
promtool check rules prometheus/alerting-rules.yaml
```

### Troubleshooting
```bash
# Check Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=100

# Check Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=100

# Check for scrape errors
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up") | {job: .labels.job, health, lastError}'
```

## Project Files Reference
- **Helm values:** `deploy/helm/monitoring/values.yaml`
- **Alerting rules:** `prometheus/alerting-rules.yaml`
- **Recording rules:** `prometheus/recording-rules.yaml`
- **Grafana dashboards:** `grafana/dashboards/`
- **Terraform module:** `terraform/modules/observability/`

## Best Practices
1. Use ServiceMonitors for scrape configuration
2. Set appropriate retention periods (15d default)
3. Configure alert routing correctly (PagerDuty for critical, Teams for warning)
4. Use recording rules for expensive queries
5. Enable persistent storage for Prometheus and Grafana
6. Configure Entra ID SSO for Grafana
7. Monitor ArgoCD and Backstage scrape targets

## Output Format
1. Command executed
2. Monitoring status summary
3. Active alerts if any
4. Recommendations

## Integration with Agents
Used by: @sre, @devops
