# Open Horizons Platform - Administrator Guide

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** Platform Administrators, SRE Teams, DevOps Engineers

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Daily Operations](#2-daily-operations)
3. [Monitoring and Alerting](#3-monitoring-and-alerting)
4. [Scaling Operations](#4-scaling-operations)
5. [Backup and Recovery](#5-backup-and-recovery)
6. [Secret Management](#6-secret-management)
7. [User Management](#7-user-management)
8. [Certificate Management](#8-certificate-management)
9. [Cost Management](#9-cost-management)
10. [Security Operations](#10-security-operations)
11. [Maintenance Windows](#11-maintenance-windows)
12. [Incident Response](#12-incident-response)
13. [Runbook: Common Procedures](#13-runbook-common-procedures)

---

## 1. Introduction

### What is This Guide?

This Administrator Guide provides everything you need to **operate and maintain** the Open Horizons platform on a day-to-day basis. It covers routine tasks, monitoring, troubleshooting, and incident response.

> 💡 **Different from Other Guides**
>
> - **Deployment Guide:** How to install the platform (one-time)
> - **Architecture Guide:** How the platform is designed (reference)
> - **Administrator Guide (this):** How to operate the platform (daily)
> - **Troubleshooting Guide:** How to fix specific problems (when issues occur)

### Who Should Read This?

| Role | What You'll Learn |
|------|-------------------|
| **Platform Administrators** | Day-to-day platform operations |
| **SRE Engineers** | Reliability and monitoring |
| **DevOps Engineers** | CI/CD and deployment operations |
| **Security Engineers** | Security operations and compliance |
| **On-Call Engineers** | Incident response procedures |

### Quick Reference Card

Keep this handy for daily operations:

![Quick Reference](../assets/admin-quick-reference.svg)

---

## 2. Daily Operations

### 2.1 Daily Health Check

> 💡 **Why Daily Health Checks?**
>
> Catching problems early prevents outages. A 5-minute daily check can prevent
> hours of emergency response later.

**Run this script every morning:**

```bash
#!/bin/bash
# Save as: daily-health-check.sh
# Run with: ./daily-health-check.sh

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           OPEN HORIZONS DAILY HEALTH CHECK                       ║"
echo "║           $(date)                                                 ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1: CLUSTER HEALTH
# ─────────────────────────────────────────────────────────────────────────────
echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│  1. CLUSTER NODES                                                   │"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

# Get node status
NODE_STATUS=$(kubectl get nodes --no-headers 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "  ❌ ERROR: Cannot connect to cluster!"
    echo "     → Run: az aks get-credentials --resource-group <rg> --name <aks>"
    exit 1
fi

# Count nodes by status
TOTAL_NODES=$(echo "$NODE_STATUS" | wc -l | tr -d ' ')
READY_NODES=$(echo "$NODE_STATUS" | grep -c " Ready ")
NOT_READY=$(echo "$NODE_STATUS" | grep -c -v " Ready ")

if [ "$READY_NODES" -eq "$TOTAL_NODES" ]; then
    echo "  ✅ All $TOTAL_NODES nodes are Ready"
else
    echo "  ⚠️  $NOT_READY of $TOTAL_NODES nodes are NOT Ready!"
    echo ""
    kubectl get nodes | grep -v " Ready "
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2: PROBLEM PODS
# ─────────────────────────────────────────────────────────────────────────────
echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│  2. PROBLEM PODS                                                    │"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

# Find pods not in Running or Succeeded state
PROBLEM_PODS=$(kubectl get pods -A --no-headers 2>/dev/null | grep -v -E "Running|Completed|Succeeded")
PROBLEM_COUNT=$(echo "$PROBLEM_PODS" | grep -c "." || echo "0")

if [ -z "$PROBLEM_PODS" ] || [ "$PROBLEM_COUNT" -eq 0 ]; then
    echo "  ✅ No problem pods found"
else
    echo "  ⚠️  Found $PROBLEM_COUNT problem pods:"
    echo ""
    echo "  NAMESPACE              NAME                              STATUS"
    echo "  ─────────────────────────────────────────────────────────────────"
    echo "$PROBLEM_PODS" | head -10 | awk '{printf "  %-20s %-35s %s\n", $1, $2, $4}'
    if [ "$PROBLEM_COUNT" -gt 10 ]; then
        echo "  ... and $((PROBLEM_COUNT - 10)) more"
    fi
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3: ARGOCD APPLICATIONS
# ─────────────────────────────────────────────────────────────────────────────
echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│  3. ARGOCD APPLICATIONS                                             │"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

APPS=$(kubectl get applications -n argocd --no-headers 2>/dev/null)
if [ -z "$APPS" ]; then
    echo "  ℹ️  No ArgoCD applications found (ArgoCD may not be installed)"
else
    SYNCED=$(echo "$APPS" | grep -c "Synced.*Healthy" || echo "0")
    TOTAL_APPS=$(echo "$APPS" | wc -l | tr -d ' ')

    if [ "$SYNCED" -eq "$TOTAL_APPS" ]; then
        echo "  ✅ All $TOTAL_APPS applications are Synced and Healthy"
    else
        echo "  ⚠️  Some applications need attention:"
        echo ""
        echo "  APPLICATION            SYNC       HEALTH"
        echo "  ─────────────────────────────────────────────────────────────────"
        kubectl get applications -n argocd --no-headers | grep -v "Synced.*Healthy" | \
            awk '{printf "  %-24s %-10s %s\n", $1, $2, $3}'
    fi
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4: RESOURCE USAGE
# ─────────────────────────────────────────────────────────────────────────────
echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│  4. RESOURCE USAGE                                                  │"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

# Check if metrics-server is available
kubectl top nodes &>/dev/null
if [ $? -ne 0 ]; then
    echo "  ℹ️  Metrics server not available (kubectl top won't work)"
else
    echo "  NODE                    CPU      MEMORY"
    echo "  ─────────────────────────────────────────────────────────────────"
    kubectl top nodes --no-headers 2>/dev/null | \
        awk '{
            cpu_pct = $3; mem_pct = $5;
            cpu_warn = (cpu_pct > 80) ? "⚠️" : "✓";
            mem_warn = (mem_pct > 85) ? "⚠️" : "✓";
            printf "  %-24s %s %-6s %s %-6s\n", $1, cpu_warn, cpu_pct, mem_warn, mem_pct
        }'
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5: RECENT WARNINGS
# ─────────────────────────────────────────────────────────────────────────────
echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│  5. RECENT WARNING EVENTS (Last 1 Hour)                             │"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

WARNINGS=$(kubectl get events -A --field-selector type=Warning \
    --sort-by='.lastTimestamp' 2>/dev/null | tail -5)

if [ -z "$WARNINGS" ]; then
    echo "  ✅ No recent warning events"
else
    echo "  Recent warnings:"
    echo ""
    echo "$WARNINGS" | awk 'NR>1 {printf "  • [%s] %s: %s\n", $1, $5, $7}'
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6: EXTERNAL SECRETS
# ─────────────────────────────────────────────────────────────────────────────
echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│  6. EXTERNAL SECRETS STATUS                                         │"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

ES_STATUS=$(kubectl get externalsecrets -A --no-headers 2>/dev/null)
if [ -z "$ES_STATUS" ]; then
    echo "  ℹ️  No External Secrets configured"
else
    SYNCED_ES=$(echo "$ES_STATUS" | grep -c "SecretSynced" || echo "0")
    TOTAL_ES=$(echo "$ES_STATUS" | wc -l | tr -d ' ')

    if [ "$SYNCED_ES" -eq "$TOTAL_ES" ]; then
        echo "  ✅ All $TOTAL_ES External Secrets are synced"
    else
        echo "  ⚠️  Some External Secrets need attention:"
        echo "$ES_STATUS" | grep -v "SecretSynced" | \
            awk '{printf "  • %s/%s - Status: %s\n", $1, $2, $4}'
    fi
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    HEALTH CHECK COMPLETE                          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
```

**Understanding the output:**

| Symbol | Meaning | Action Required |
|--------|---------|-----------------|
| ✅ | Everything OK | None |
| ⚠️ | Warning | Investigate soon |
| ❌ | Error | Investigate immediately |
| ℹ️ | Information | For your awareness |

### 2.2 Key Metrics to Monitor

> 💡 **What Metrics Should I Watch?**
>
> These are the most important metrics that indicate platform health.
> Set up alerts for these in Grafana/Prometheus.

| Metric | Normal Range | Warning Threshold | Critical Threshold | What It Means |
|--------|--------------|-------------------|--------------------|---------------|
| **Node CPU** | < 70% | > 80% | > 90% | Nodes are overloaded |
| **Node Memory** | < 75% | > 85% | > 95% | Risk of OOM kills |
| **Pod Restarts** | 0-2/hour | > 5/hour | > 10/hour | Application instability |
| **API Server Latency** | < 200ms | > 500ms | > 1s | Control plane issues |
| **Failed Pods** | 0 | > 0 | > 5 | Application failures |
| **PV Usage** | < 70% | > 80% | > 90% | Storage running out |
| **Certificate Expiry** | > 30 days | < 30 days | < 7 days | TLS cert expiring |

### 2.3 Daily Tasks Checklist

Print this and check off each item:

![Daily Operations Checklist](../assets/admin-daily-checklist.svg)

---

## 3. Monitoring and Alerting

### 3.1 Accessing Monitoring Tools

> 💡 **How to Access Dashboards**
>
> All monitoring tools run inside the Kubernetes cluster. You access them
> by "port-forwarding" - creating a tunnel from your computer to the service.

#### Grafana (Dashboards and Visualization)

```bash
# Step 1: Start port-forward to Grafana
kubectl port-forward svc/prometheus-grafana -n observability 3000:80

# Step 2: Get the admin password
kubectl get secret prometheus-grafana -n observability \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo

# Step 3: Open browser to http://localhost:3000
# Username: admin
# Password: (from step 2)
```

**What you'll see in Grafana:**

![Grafana Dashboard Overview](../assets/admin-grafana-overview.svg)

#### Prometheus (Metrics Query)

```bash
# Start port-forward to Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090

# Open browser to http://localhost:9090
```

**Useful PromQL Queries:**

```promql
# CPU usage by node (percentage)
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage by node (percentage)
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Pod restart count in last hour
increase(kube_pod_container_status_restarts_total[1h])

# HTTP request rate by service
sum(rate(http_requests_total[5m])) by (service)

# HTTP error rate (5xx) by service
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
```

#### ArgoCD (GitOps Deployments)

```bash
# Start port-forward to ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Open browser to https://localhost:8080
# Username: admin
# Password: (from above command)
```

### 3.2 Alert Configuration

> 💡 **How Alerts Work**
>
> 1. Prometheus evaluates alert rules continuously
> 2. When a rule matches, Prometheus fires an alert to Alertmanager
> 3. Alertmanager groups similar alerts and routes them
> 4. You receive notification via Slack, PagerDuty, email, etc.

**Alert Severity Levels:**

| Severity | Response Time | Who to Notify | Examples |
|----------|---------------|---------------|----------|
| **Critical** | Immediate (< 15 min) | On-call + escalation | Platform down, data loss risk |
| **Warning** | Same day (< 4 hours) | On-call | High CPU, approaching limits |
| **Info** | Next business day | Team channel | FYI events, non-urgent |

**Configuring Alert Routes:**

File: `prometheus/alertmanager-config.yaml`

```yaml
# This configures WHERE alerts go based on severity
route:
  # Default receiver
  receiver: 'slack-notifications'

  # Group alerts by these labels
  group_by: ['alertname', 'namespace']

  # Wait before sending (to group similar alerts)
  group_wait: 30s

  # How long to wait before sending new alerts in the same group
  group_interval: 5m

  # How often to resend alerts that are still firing
  repeat_interval: 4h

  # Child routes - more specific matching
  routes:
    # Critical alerts go to PagerDuty
    - match:
        severity: critical
      receiver: 'pagerduty'
      repeat_interval: 15m

    # Warning alerts go to Slack
    - match:
        severity: warning
      receiver: 'slack-notifications'

    # Info alerts are logged only
    - match:
        severity: info
      receiver: 'null'

receivers:
  # PagerDuty for critical alerts
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}'

  # Slack for warnings
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/XXX/YYY/ZZZ'
        channel: '#platform-alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  # Null receiver (drops alerts)
  - name: 'null'
```

### 3.3 Creating Custom Alerts

**Example: Alert when HTTP error rate exceeds 1%**

```yaml
# Add to prometheus/alerting-rules.yaml
groups:
  - name: application-alerts
    rules:
      # Alert: High HTTP Error Rate
      - alert: HighHTTPErrorRate
        # PromQL expression that triggers the alert
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
            /
            sum(rate(http_requests_total[5m])) by (service)
          ) > 0.01

        # How long condition must be true before alerting
        for: 5m

        # Labels for routing
        labels:
          severity: warning
          team: platform

        # Human-readable information
        annotations:
          summary: "High HTTP error rate for {{ $labels.service }}"
          description: |
            Service {{ $labels.service }} has an error rate of
            {{ $value | humanizePercentage }} (threshold: 1%).

            Runbook: https://wiki.company.com/runbooks/high-error-rate
          dashboard: "https://grafana.company.com/d/api-dashboard"
```

**Alert Best Practices:**

| Do | Don't |
|----|-------|
| ✅ Set meaningful `for` duration (avoid flapping) | ❌ Alert on every blip |
| ✅ Include runbook links in annotations | ❌ Leave operators guessing |
| ✅ Route by severity to appropriate channels | ❌ Send everything to PagerDuty |
| ✅ Alert on symptoms (error rate high) | ❌ Alert on causes (CPU high) |
| ✅ Test alerts before deploying | ❌ Find out alerts don't work during incident |

---

## 4. Scaling Operations

### 4.1 Understanding Autoscaling

> 💡 **Types of Autoscaling**
>
> The platform supports three types of autoscaling:
> - **HPA (Horizontal Pod Autoscaler):** Scales pods within a deployment
> - **VPA (Vertical Pod Autoscaler):** Adjusts pod resource requests
> - **Cluster Autoscaler:** Adds/removes nodes from the cluster

![Autoscaling Hierarchy](../assets/admin-autoscaling-hierarchy.svg)

### 4.2 Manual Node Scaling

> ⚠️ **When to Scale Manually**
>
> Usually, let the Cluster Autoscaler handle scaling. Manual scaling is for:
> - Preparing for known traffic spikes
> - Cost optimization (scaling down during off-hours)
> - Emergency situations

**Scale cluster nodes:**

```bash
# View current node count
kubectl get nodes | wc -l

# Scale the workload node pool
az aks nodepool scale \
  --resource-group rg-threehorizons-dev \
  --cluster-name aks-threehorizons-dev \
  --name workload \
  --node-count 5

# Verify new nodes are Ready
watch kubectl get nodes
```

**Understanding the scaling process:**

![Node Scaling Timeline](../assets/admin-node-scaling-timeline.svg)

### 4.3 Configuring Horizontal Pod Autoscaler

**Create an HPA for a deployment:**

```yaml
# Example: Autoscale based on CPU usage
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
  namespace: production
spec:
  # Target deployment
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app

  # Min and max replicas
  minReplicas: 3
  maxReplicas: 20

  # Scaling triggers
  metrics:
    # Scale when CPU usage > 70%
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70

    # Scale when memory usage > 80%
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80

  # Scale-down settings (prevent flapping)
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
      policies:
        - type: Percent
          value: 50       # Max 50% reduction at once
          periodSeconds: 60
```

**Apply and verify:**

```bash
# Apply the HPA
kubectl apply -f my-app-hpa.yaml

# Check HPA status
kubectl get hpa -n production

# Watch HPA in action
kubectl get hpa -n production -w
```

**Expected output:**

```
NAME         REFERENCE           TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
my-app-hpa   Deployment/my-app   23%/70%   3         20        5          2m
```

---

## 5. Backup and Recovery

### 5.1 What Gets Backed Up

> 💡 **Backup Strategy**
>
> We use a "belt and suspenders" approach:
> - **Terraform state:** In Azure Storage (versioned)
> - **Git:** All configs in version control
> - **Velero:** Kubernetes resources and PV snapshots
> - **Azure Backup:** Managed services (PostgreSQL, etc.)

![Backup Architecture](../assets/admin-backup-architecture.svg)

### 5.2 Velero Backup Commands

**Check backup status:**

```bash
# List all backups
velero backup get

# Check backup details
velero backup describe <backup-name>

# Check backup logs
velero backup logs <backup-name>
```

**Create manual backup:**

```bash
# Backup everything
velero backup create full-backup-$(date +%Y%m%d)

# Backup specific namespace
velero backup create myapp-backup-$(date +%Y%m%d) \
  --include-namespaces myapp-production

# Backup with specific labels
velero backup create critical-apps-$(date +%Y%m%d) \
  --selector app.kubernetes.io/part-of=critical
```

### 5.3 Restore Procedures

> ⚠️ **Before Restoring**
>
> 1. Communicate to stakeholders that restoration is happening
> 2. Ensure you have the right backup identified
> 3. Decide: restore to same namespace or new namespace?

**Restore from backup:**

```bash
# List available backups
velero backup get

# Restore entire backup
velero restore create --from-backup full-backup-20241210

# Restore specific namespace
velero restore create --from-backup full-backup-20241210 \
  --include-namespaces production

# Restore to different namespace (create mapping)
velero restore create --from-backup full-backup-20241210 \
  --namespace-mappings production:production-restored

# Check restore status
velero restore describe <restore-name>
```

**Disaster Recovery Runbook:**

![Disaster Recovery Steps](../assets/admin-dr-steps.svg)

---

## 6. Secret Management

### 6.1 Understanding Secret Flow

> 💡 **Where Secrets Live**
>
> - **Azure Key Vault:** Source of truth for all secrets
> - **External Secrets Operator:** Syncs secrets to Kubernetes
> - **Kubernetes Secrets:** What applications actually read

![Secret Management Flow](../assets/admin-secret-management-flow.svg)

### 6.2 Managing Secrets in Key Vault

**Add a new secret:**

```bash
# Set secret in Key Vault
az keyvault secret set \
  --vault-name kv-threehorizons-dev \
  --name "database-password" \
  --value "super-secret-password-123"

# Verify secret was created
az keyvault secret show \
  --vault-name kv-threehorizons-dev \
  --name "database-password" \
  --query "value"
```

**Create ExternalSecret to sync it:**

```yaml
# externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secrets
  namespace: my-app
spec:
  # How often to sync
  refreshInterval: 1h

  # Which secret store to use
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-key-vault

  # Target Kubernetes Secret
  target:
    name: my-app-secrets

  # What to sync
  data:
    # Local key name : Key Vault secret name
    - secretKey: DATABASE_PASSWORD
      remoteRef:
        key: database-password

    - secretKey: API_KEY
      remoteRef:
        key: my-app-api-key
```

**Apply and verify:**

```bash
# Apply the ExternalSecret
kubectl apply -f externalsecret.yaml

# Check sync status
kubectl get externalsecret my-app-secrets -n my-app

# Verify Kubernetes Secret was created
kubectl get secret my-app-secrets -n my-app

# View secret contents (base64 encoded)
kubectl get secret my-app-secrets -n my-app -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d
```

### 6.3 Secret Rotation

> 💡 **Why Rotate Secrets?**
>
> - Compliance requirements
> - After personnel changes
> - After suspected compromise
> - Best practice: every 90 days

**Secret rotation procedure:**

![Secret Rotation Procedure](../assets/admin-secret-rotation.svg)

---

## 7. User Management

### 7.1 Access Control Model

> 💡 **RBAC (Role-Based Access Control)**
>
> We use RBAC at two levels:
> - **Azure RBAC:** Who can access Azure resources
> - **Kubernetes RBAC:** Who can access Kubernetes resources

![Access Control Hierarchy](../assets/admin-access-control.svg)

### 7.2 Adding a New User

**Step 1: Add to Azure AD Group**

```bash
# Get user's Object ID
az ad user show --id "user@company.com" --query id -o tsv

# Add to appropriate group
# For operators:
az ad group member add \
  --group "Platform-Operators" \
  --member-id "user-object-id"

# For admins:
az ad group member add \
  --group "Platform-Admins" \
  --member-id "user-object-id"
```

**Step 2: Create Kubernetes RoleBinding (if namespace-specific)**

```yaml
# rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-alpha-access
  namespace: team-alpha
subjects:
  # Bind to Azure AD group
  - kind: Group
    name: "team-alpha-developers"  # Azure AD group name
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit  # Kubernetes built-in role
  apiGroup: rbac.authorization.k8s.io
```

**Step 3: Verify access**

```bash
# User should run:
az aks get-credentials --resource-group rg-XXX --name aks-XXX

# Test access
kubectl auth can-i create pods -n team-alpha
# Expected: yes

kubectl auth can-i create pods -n other-team
# Expected: no
```

### 7.3 Removing User Access

```bash
# Remove from Azure AD group
az ad group member remove \
  --group "Platform-Operators" \
  --member-id "user-object-id"

# Verify removal
az ad group member check \
  --group "Platform-Operators" \
  --member-id "user-object-id"
# Expected: false

# User's access will be revoked next time they try to authenticate
# For immediate revocation, delete their kubeconfig credentials
```

---

## 8. Certificate Management

### 8.1 Certificate Types

| Certificate Type | Purpose | Managed By | Rotation |
|-----------------|---------|------------|----------|
| **TLS for Ingress** | HTTPS for web apps | cert-manager | Auto (Let's Encrypt) |
| **Kubernetes CA** | Internal cluster TLS | AKS | Auto (Azure) |
| **Key Vault Certs** | Custom certificates | Key Vault | Manual or auto |

### 8.2 Checking Certificate Status

```bash
# List all certificates managed by cert-manager
kubectl get certificates -A

# Check specific certificate details
kubectl describe certificate my-tls-cert -n my-app

# Check certificate expiry
kubectl get certificate -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.status.notAfter}{"\n"}{end}'
```

### 8.3 Certificate Renewal

**Automatic renewal (cert-manager):**

cert-manager automatically renews certificates 30 days before expiry. If renewal fails:

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Force renewal
kubectl delete certificate my-tls-cert -n my-app
# cert-manager will recreate it

# Or delete the secret to trigger re-issuance
kubectl delete secret my-tls-cert -n my-app
```

**Manual renewal (Key Vault certificates):**

```bash
# Check certificate expiry
az keyvault certificate show \
  --vault-name kv-XXX \
  --name my-cert \
  --query "attributes.expires"

# Create new version (CSR or import)
az keyvault certificate create \
  --vault-name kv-XXX \
  --name my-cert \
  --policy @cert-policy.json
```

---

## 9. Cost Management

### 9.1 Understanding Costs

> 💡 **Major Cost Drivers**
>
> In order of typical impact:
> 1. **AKS Node VMs:** 60-70% of cost
> 2. **Azure OpenAI:** Variable based on usage
> 3. **Storage:** Disks, blobs, logs
> 4. **Network:** Egress traffic

![Cost Breakdown](../assets/admin-cost-breakdown.svg)

### 9.2 Cost Monitoring

**Check current spend:**

```bash
# Get current month spend
az consumption usage list \
  --subscription $SUBSCRIPTION_ID \
  --start-date $(date -v-30d +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[].{Name:instanceName, Cost:pretaxCost}" \
  --output table
```

**Set up budget alerts:**

```bash
# Create budget with alerts
az consumption budget create \
  --budget-name "platform-monthly" \
  --amount 5000 \
  --category Cost \
  --time-grain Monthly \
  --start-date 2024-01-01 \
  --end-date 2025-12-31 \
  --resource-group rg-threehorizons-dev \
  --notification-key-1 80Percent \
  --notification-threshold 80 \
  --notification-operator GreaterThan \
  --contact-emails "platform-team@company.com" \
  --notification-enabled true
```

### 9.3 Cost Optimization Tips

| Optimization | Savings | Effort | Risk |
|--------------|---------|--------|------|
| **Spot instances for workload pool** | 60-80% | Low | Medium (interruptions) |
| **Reserved instances (1 year)** | 30-40% | Low | Low |
| **Scale down dev at night** | 50% | Medium | Low |
| **Right-size VMs** | 10-30% | Medium | Low |
| **Optimize AI model usage** | Variable | High | Low |

**Implement spot instances:**

```hcl
# In terraform/terraform.tfvars
additional_node_pools = {
  spot = {
    vm_size = "Standard_D4s_v5"
    count   = 3
    priority = "Spot"
    eviction_policy = "Delete"
    spot_max_price = -1  # Pay up to on-demand price
  }
}
```

---

## 10. Security Operations

### 10.1 Security Monitoring

**Daily security checks:**

```bash
# Check Defender for Cloud recommendations
az security assessment list \
  --query "[?status.code=='Unhealthy'].{Name:displayName, Status:status.code}" \
  --output table

# Check for security events in past 24 hours
az monitor activity-log list \
  --start-time $(date -v-1d +%Y-%m-%dT%H:%M:%SZ) \
  --query "[?authorization.action contains 'Microsoft.Security'].{Time:eventTimestamp, Action:authorization.action}" \
  --output table
```

### 10.2 Security Incident Response

![Security Incident Response](../assets/admin-security-incident.svg)

---

## 11. Maintenance Windows

### 11.1 Scheduled Maintenance

| Maintenance Type | Frequency | Window | Duration | Impact |
|-----------------|-----------|--------|----------|--------|
| **AKS Upgrades** | Quarterly | Saturday 2-6 AM | 2-4 hours | Rolling (minimal) |
| **Node Pool Updates** | Monthly | Saturday 2-4 AM | 1-2 hours | Rolling |
| **Certificate Rotation** | As needed | Any time | Minutes | None |
| **Helm Chart Updates** | Weekly | Wednesday 10 PM | 30 min | Rolling |

### 11.2 Pre-Maintenance Checklist

![Pre-Maintenance Checklist](../assets/admin-pre-maintenance.svg)

---

## 12. Incident Response

### 12.1 Incident Severity Levels

| Level | Definition | Response Time | Examples |
|-------|------------|---------------|----------|
| **SEV1** | Platform down | 15 min | Cluster unreachable, data loss |
| **SEV2** | Major degradation | 1 hour | Multiple apps failing, high error rate |
| **SEV3** | Minor degradation | 4 hours | Single app affected, non-critical |
| **SEV4** | Informational | Next business day | Cosmetic issues, questions |

### 12.2 Incident Response Procedure

![Incident Response Timeline](../assets/admin-incident-timeline.svg)

---

## 13. Runbook: Common Procedures

### 13.1 Restart a Stuck Deployment

```bash
# Check current status
kubectl get deployment my-app -n production

# Restart all pods (rolling)
kubectl rollout restart deployment/my-app -n production

# Watch rollout progress
kubectl rollout status deployment/my-app -n production

# If rollout fails, rollback
kubectl rollout undo deployment/my-app -n production
```

### 13.2 Force Sync ArgoCD Application

```bash
# Hard refresh - re-read from Git
kubectl patch application my-app -n argocd --type merge \
  -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {"syncStrategy": {"apply": {"force": true}}}}}'

# Or use ArgoCD CLI
argocd app sync my-app --force
```

### 13.3 Drain and Cordon a Node

```bash
# Mark node as unschedulable (cordon)
kubectl cordon node-name

# Safely evict pods (drain)
kubectl drain node-name --ignore-daemonsets --delete-emptydir-data

# After maintenance, uncordon
kubectl uncordon node-name
```

### 13.4 Emergency Scale Up

```bash
# Immediately add nodes
az aks nodepool scale \
  --resource-group rg-XXX \
  --cluster-name aks-XXX \
  --name workload \
  --node-count 10

# Scale specific deployment
kubectl scale deployment my-app -n production --replicas=10
```

### 13.5 View and Follow Logs

```bash
# Follow logs for a deployment
kubectl logs -f deployment/my-app -n production

# View logs from crashed pod
kubectl logs deployment/my-app -n production --previous

# View logs with timestamps
kubectl logs -f deployment/my-app -n production --timestamps

# View logs from specific container in multi-container pod
kubectl logs -f deployment/my-app -n production -c sidecar-container
```

### 13.6 Emergency Rollback

```bash
# View rollout history
kubectl rollout history deployment/my-app -n production

# Rollback to previous version
kubectl rollout undo deployment/my-app -n production

# Rollback to specific version
kubectl rollout undo deployment/my-app -n production --to-revision=3

# Verify rollback
kubectl rollout status deployment/my-app -n production
```

---

## Summary

This Administrator Guide covered:

1. **Daily Operations:** Health checks, monitoring, checklists
2. **Monitoring:** Accessing Grafana, Prometheus, ArgoCD
3. **Scaling:** Manual and automatic scaling procedures
4. **Backup/Recovery:** Velero operations, disaster recovery
5. **Secrets:** Key Vault and External Secrets management
6. **Users:** RBAC and access control
7. **Certificates:** TLS and cert-manager
8. **Costs:** Monitoring and optimization
9. **Security:** Monitoring and incident response
10. **Maintenance:** Windows and procedures
11. **Incidents:** Response and escalation
12. **Runbooks:** Common operational procedures

For specific troubleshooting scenarios, see the [Troubleshooting Guide](./TROUBLESHOOTING_GUIDE.md).

---

## 🤖 Using Copilot Agents for Administration

The platform includes AI agents that assist with day-2 operations:

| Task | Agent | Example Prompt |
|------|-------|---------------|
| Monitoring & alerts | `@sre` | "Show me the current error rate and latency for all services" |
| Security operations | `@security` | "Audit RBAC assignments on the AKS cluster" |
| Scaling decisions | `@terraform` | "Help me scale the AKS nodepool to 5 nodes" |
| Cost optimization | `@architect` | "Suggest cost savings for our current Azure setup" |
| Pipeline management | `@devops` | "Help me set up a new GitHub Actions workflow" |
| Documentation updates | `@docs` | "Update the README to reflect the new module we added" |

> **Tip:** Use `@sre` as your daily operations companion. It will triage issues, check metrics, and suggest fixes.

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [Troubleshooting Guide](./TROUBLESHOOTING_GUIDE.md) | Diagnostic workflows for common platform issues |
| [Performance Tuning Guide](./PERFORMANCE_TUNING_GUIDE.md) | Optimization recommendations for all components |
| [Deployment Guide](./DEPLOYMENT_GUIDE.md) | Step-by-step platform deployment instructions |
| [Module Reference](./MODULE_REFERENCE.md) | Detailed inputs/outputs for all Terraform modules |
| [Runbooks](../runbooks/README.md) | Operational runbooks for common procedures |

## Next Steps

- **Review performance tuning**: Optimize cluster resources — see [Performance Tuning Guide](./PERFORMANCE_TUNING_GUIDE.md)
- **Set up runbooks**: Familiarize with operational procedures — see [Runbooks](../runbooks/README.md)
- **Configure alerting**: Set up alerting rules and notification channels

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
