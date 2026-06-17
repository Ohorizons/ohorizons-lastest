# Open Horizons Platform - Performance Tuning Guide

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** Platform Engineers, DevOps Teams

---

## Table of Contents

1. [Sizing Recommendations](#sizing-recommendations)
2. [AKS Cluster Optimization](#aks-cluster-optimization)
3. [Node Pool Configuration](#node-pool-configuration)
4. [Pod Resource Management](#pod-resource-management)
5. [Autoscaling Configuration](#autoscaling-configuration)
6. [Database Optimization](#database-optimization)
7. [Network Performance](#network-performance)
8. [Observability Overhead](#observability-overhead)
9. [AI Workload Optimization](#ai-workload-optimization)
10. [Load Testing](#load-testing)
11. [Capacity Planning](#capacity-planning)

---

## Overview

This guide provides recommendations for optimizing the performance of the Open Horizons Platform across all components.

---

## Sizing Recommendations

### Profile Comparison

| Profile | Nodes | vCPUs | Memory | Monthly Cost | Use Case |
|---------|-------|-------|--------|--------------|----------|
| **Small** | 3 | 6 | 12 GB | ~$800 | Dev/POC |
| **Medium** | 5 | 20 | 40 GB | ~$3,500 | Standard Production |
| **Large** | 10 | 40 | 80 GB | ~$12,000 | Enterprise |
| **XLarge** | 15+ | 60+ | 120+ GB | ~$35,000 | Mission Critical |

### Selecting the Right Profile

**Choose Small when:**
- Development or testing environment
- < 10 concurrent developers
- < 20 microservices
- No GPU workloads

**Choose Medium when:**
- Standard production workload
- 10-50 concurrent developers
- 20-50 microservices
- Light AI/ML workloads

**Choose Large when:**
- Enterprise production
- 50-200 concurrent developers
- 50-100 microservices
- Moderate AI/ML workloads
- GPU requirements

**Choose XLarge when:**
- Mission-critical systems
- 200+ concurrent developers
- 100+ microservices
- Heavy AI/ML workloads
- Multi-region deployment

---

## AKS Cluster Optimization

### Control Plane Configuration

```hcl
# terraform.tfvars optimizations
sku_tier = "Standard"  # Use Standard for production (SLA backed)

# For high-throughput environments
kubernetes_version = "1.29"  # Latest stable version

# API server authorized IP ranges (reduces attack surface)
api_server_authorized_ip_ranges = ["10.0.0.0/8", "YOUR_OFFICE_IP/32"]
```

### Cluster Autoscaler Profile

```hcl
# Optimized autoscaler settings
auto_scaler_profile = {
  balance_similar_node_groups      = true
  expander                         = "random"
  max_graceful_termination_sec     = 600
  max_node_provisioning_time       = "15m"
  max_unready_nodes                = 3
  max_unready_percentage           = 45
  new_pod_scale_up_delay           = "10s"
  scale_down_delay_after_add       = "10m"
  scale_down_delay_after_delete    = "10s"
  scale_down_delay_after_failure   = "3m"
  scan_interval                    = "10s"
  scale_down_unneeded              = "10m"
  scale_down_unready               = "20m"
  scale_down_utilization_threshold = 0.5
  empty_bulk_delete_max            = 10
  skip_nodes_with_local_storage    = false
  skip_nodes_with_system_pods      = true
}
```

### Best Practices

1. **Use availability zones** for high availability
2. **Separate node pools** for different workload types
3. **Enable Uptime SLA** for production clusters
4. **Use managed identities** instead of service principals

---

## Node Pool Configuration

### Recommended VM Sizes by Workload

| Workload Type | Recommended SKU | vCPUs | Memory | Notes |
|---------------|-----------------|-------|--------|-------|
| System | Standard_D2s_v5 | 2 | 8 GB | Control plane components |
| General | Standard_D4s_v5 | 4 | 16 GB | Most workloads |
| Memory-intensive | Standard_E4s_v5 | 4 | 32 GB | Databases, caches |
| CPU-intensive | Standard_F8s_v2 | 8 | 16 GB | Compute workloads |
| GPU | Standard_NC6s_v3 | 6 | 112 GB | AI/ML training |

### Node Pool Separation Strategy

```hcl
# System node pool - minimal, dedicated to system components
default_node_pool = {
  name                = "system"
  vm_size             = "Standard_D2s_v5"
  node_count          = 3
  zones               = ["1", "2", "3"]
  enable_auto_scaling = true
  min_count           = 3
  max_count           = 5
  only_critical_addons_enabled = true
}

# User workloads node pool
additional_node_pools = {
  user = {
    name                = "user"
    vm_size             = "Standard_D4s_v5"
    node_count          = 3
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 20
    node_labels = {
      "workload" = "user"
    }
  }

  # GPU node pool for AI workloads
  gpu = {
    name                = "gpu"
    vm_size             = "Standard_NC6s_v3"
    node_count          = 0
    enable_auto_scaling = true
    min_count           = 0
    max_count           = 4
    node_taints         = ["nvidia.com/gpu=true:NoSchedule"]
    node_labels = {
      "workload"      = "gpu"
      "accelerator"   = "nvidia"
    }
  }
}
```

---

## Pod Resource Management

### Resource Requests and Limits

```yaml
# Recommended starting points
resources:
  requests:
    cpu: "100m"      # 0.1 CPU core
    memory: "128Mi"  # 128 MB
  limits:
    cpu: "500m"      # 0.5 CPU core
    memory: "512Mi"  # 512 MB
```

### Guidelines by Application Type

| App Type | CPU Request | CPU Limit | Memory Request | Memory Limit |
|----------|-------------|-----------|----------------|--------------|
| API Service | 100m | 500m | 128Mi | 512Mi |
| Web Frontend | 50m | 200m | 64Mi | 256Mi |
| Background Worker | 200m | 1000m | 256Mi | 1Gi |
| Database Client | 100m | 500m | 256Mi | 1Gi |
| AI Inference | 500m | 2000m | 1Gi | 4Gi |

### Quality of Service (QoS) Classes

```yaml
# Guaranteed QoS (requests = limits)
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

# Burstable QoS (requests < limits)
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

### Vertical Pod Autoscaler (VPA)

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  updatePolicy:
    updateMode: "Auto"  # or "Off" for recommendations only
  resourcePolicy:
    containerPolicies:
    - containerName: "*"
      minAllowed:
        cpu: "50m"
        memory: "64Mi"
      maxAllowed:
        cpu: "2000m"
        memory: "4Gi"
```

---

## Autoscaling Configuration

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### KEDA for Event-Driven Scaling

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: queue-processor
spec:
  scaleTargetRef:
    name: queue-processor
  minReplicaCount: 0
  maxReplicaCount: 50
  triggers:
  - type: azure-servicebus
    metadata:
      queueName: orders
      messageCount: "5"
      connectionFromEnv: SERVICEBUS_CONNECTION
```

---

## Database Optimization

### PostgreSQL Tuning

```sql
-- Connection pooling settings
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 768MB
maintenance_work_mem = 64MB
work_mem = 4MB

-- Performance settings
random_page_cost = 1.1  -- For SSD storage
effective_io_concurrency = 200

-- Write performance
wal_buffers = 16MB
checkpoint_completion_target = 0.9
```

### Azure PostgreSQL Flexible Server

```hcl
# terraform.tfvars
postgresql_sku_name = "GP_Standard_D4s_v3"  # 4 vCores, 16 GB RAM
postgresql_storage_mb = 65536  # 64 GB

# High availability
postgresql_ha_enabled = true
postgresql_geo_redundant_backup = true
```

### Redis Caching Strategy

```hcl
# terraform.tfvars
redis_sku_name = "Premium"
redis_family = "P"
redis_capacity = 1  # P1 = 6GB

# Cluster mode for high throughput
redis_cluster_enabled = true
redis_shard_count = 2
```

### Redis Best Practices

1. **Use connection pooling** - Reduce connection overhead
2. **Set appropriate TTLs** - Prevent memory bloat
3. **Use pipelining** - Batch commands for efficiency
4. **Monitor memory** - Set maxmemory-policy

---

## Network Performance

### Azure CNI Optimization

```hcl
# terraform.tfvars
network_plugin = "azure"
network_plugin_mode = "overlay"  # More efficient IP usage
network_policy = "calico"
```

### Pod CIDR Sizing

| Cluster Size | Pod CIDR | Max Pods |
|--------------|----------|----------|
| Small | /20 | 4,096 |
| Medium | /18 | 16,384 |
| Large | /16 | 65,536 |

### Service Mesh Considerations

For high-traffic environments, consider:

1. **Istio** - Full-featured but resource intensive
2. **Linkerd** - Lighter weight, lower overhead
3. **No mesh** - Direct service-to-service communication

### Ingress Optimization

```yaml
# NGINX Ingress tuning
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
data:
  proxy-body-size: "100m"
  proxy-connect-timeout: "15"
  proxy-read-timeout: "60"
  proxy-send-timeout: "60"
  use-gzip: "true"
  gzip-level: "5"
  worker-processes: "auto"
  max-worker-connections: "65536"
  keepalive: "75"
```

---

## Observability Overhead

### Prometheus Retention and Storage

```yaml
# prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 15d
    retentionSize: "50GB"
    resources:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: 2000m
        memory: 4Gi
```

### Reducing Cardinality

```yaml
# Drop high-cardinality labels
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'go_.*'  # Drop Go runtime metrics
    action: drop
  - source_labels: [pod]
    regex: '.*-[a-z0-9]{5}-[a-z0-9]{5}'
    action: labeldrop
```

### Log Volume Management

```yaml
# Loki retention
loki:
  limits_config:
    retention_period: 168h  # 7 days
    max_query_series: 5000
  chunk_store_config:
    max_look_back_period: 168h
```

---

## AI Workload Optimization

### Azure OpenAI Rate Limits

| Model | TPM (Tokens/min) | RPM (Requests/min) |
|-------|------------------|-------------------|
| GPT-4o | 30,000 | 300 |
| GPT-4o-mini | 100,000 | 1,000 |
| Embeddings | 1,000,000 | 6,000 |

### Optimizing AI Calls

```python
# Batch embeddings
texts = ["text1", "text2", "text3"]
embeddings = openai.embeddings.create(
    model="text-embedding-3-large",
    input=texts  # Send as batch
)

# Use streaming for long responses
response = openai.chat.completions.create(
    model="gpt-4o",
    messages=[...],
    stream=True  # Reduces perceived latency
)
```

### AI Search Optimization

```hcl
# terraform.tfvars
ai_search_sku = "standard"  # or "standard2" for high volume
ai_search_replica_count = 2
ai_search_partition_count = 1

# Enable semantic search for better relevance
ai_search_semantic_search_sku = "standard"
```

---

## Load Testing

### Recommended Tools

1. **k6** - Modern load testing tool
2. **Locust** - Python-based, distributed
3. **Apache JMeter** - Enterprise grade

### k6 Example Script

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up
    { duration: '5m', target: 100 },  // Sustained load
    { duration: '2m', target: 200 },  // Peak
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% under 500ms
    http_req_failed: ['rate<0.01'],    // <1% errors
  },
};

export default function () {
  const res = http.get('https://api.example.com/health');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
```

### Load Testing Best Practices

1. **Test in staging** - Mirror production configuration
2. **Start small** - Gradually increase load
3. **Monitor everything** - Watch cluster metrics during tests
4. **Test failure scenarios** - Include error conditions
5. **Document baselines** - Record performance benchmarks

---

## Capacity Planning

### Metrics to Monitor

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| Node CPU | >70% | >85% | Add nodes |
| Node Memory | >75% | >90% | Add nodes |
| Pod CPU | >80% | >95% | Increase limits or replicas |
| Pod Memory | >80% | >95% | Increase limits |
| API Latency | >500ms | >1s | Scale or optimize |
| Error Rate | >1% | >5% | Investigate |

### Growth Planning Formula

```
Required Nodes = (Current Workload × Growth Factor) / Node Capacity

Example:
- Current: 50 pods using 100m CPU each = 5 CPU cores
- Growth: 2x in 6 months
- Node capacity: 4 cores usable (D4s_v5)

Required = (5 × 2) / 4 = 2.5 → 3 nodes minimum
Add buffer: 3 × 1.3 = 4 nodes recommended
```

### Cost Optimization

1. **Use spot instances** for non-critical workloads
2. **Right-size resources** based on actual usage
3. **Implement pod disruption budgets** for efficient scaling
4. **Use reserved instances** for predictable workloads
5. **Schedule non-prod shutdowns** during off-hours

---

## Performance Monitoring Dashboard

### Key Grafana Panels

1. **Cluster Overview**
   - Node count and status
   - Total CPU/Memory utilization
   - Pod count by namespace

2. **Application Performance**
   - Request rate (RPS)
   - Error rate
   - P50/P95/P99 latency

3. **Resource Efficiency**
   - Request vs actual usage
   - Cost per namespace
   - Idle resource percentage

4. **Scaling Events**
   - HPA scaling events
   - Node scaling events
   - Pod restarts

## References

- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Azure OpenAI Quotas](https://docs.microsoft.com/azure/cognitive-services/openai/quotas-limits)
- [Sizing Profiles](../../config/sizing-profiles.yaml)

---

## 🤖 Using Copilot Agents for Performance Tuning

| Task | Agent | Example Prompt |
|------|-------|---------------|
| Prometheus metric analysis | `@sre` | "Query Prometheus for p99 latency over the last 24h" |
| AKS node tuning | `@terraform` | "Help me adjust the AKS nodepool SKU and autoscaler settings" |
| Resource limits review | `@sre` | "Which pods are over their memory limits?" |
| Cost vs performance analysis | `@architect` | "Evaluate trade-offs between Standard_D4s_v3 and Standard_D8s_v3" |

> **Tip:** Ask `@sre` to analyze metrics before making tuning decisions — data-driven changes are safer.

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
