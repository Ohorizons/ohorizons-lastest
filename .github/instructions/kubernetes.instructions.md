---
applyTo: "**/*.yaml,**/*.yml,**/kubernetes/**,**/k8s/**,**/helm/**"
description: "Kubernetes manifest standards — resource limits, security contexts, labels, probes, and network policies for AKS deployments."
---

# Kubernetes Coding Standards

## Manifest Structure

```
deploy/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    ├── staging/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

## Deployment Template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .name }}
  namespace: {{ .namespace }}
  labels:
    app.kubernetes.io/name: {{ .name }}
    app.kubernetes.io/instance: {{ .instance }}
    app.kubernetes.io/version: {{ .version }}
    app.kubernetes.io/component: {{ .component }}
    app.kubernetes.io/part-of: {{ .partOf }}
    app.kubernetes.io/managed-by: {{ .managedBy }}
spec:
  replicas: {{ .replicas }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .name }}
      app.kubernetes.io/instance: {{ .instance }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ .name }}
        app.kubernetes.io/instance: {{ .instance }}
    spec:
      serviceAccountName: {{ .serviceAccountName }}
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: {{ .name }}
          image: {{ .image }}:{{ .tag }}
          imagePullPolicy: IfNotPresent
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
```

## Security Requirements

### Pod Security
- ALWAYS run as non-root user
- ALWAYS use read-only root filesystem
- ALWAYS drop all capabilities
- NEVER allow privilege escalation
- Use RuntimeDefault seccomp profile

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### Service Account
- Create dedicated service accounts
- Never use default service account
- Disable automount of service account token when not needed

## Resource Management

### Limits and Requests
- ALWAYS specify resource requests
- ALWAYS specify resource limits
- Set limits close to requests for predictability
- Use LimitRange for namespace defaults

### Pod Disruption Budgets
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .name }}-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .name }}
```

## Health Checks

- ALWAYS configure liveness probes
- ALWAYS configure readiness probes
- Consider startup probes for slow-starting apps
- Set appropriate timeouts and thresholds

## Labeling Standards

Required labels:
- `app.kubernetes.io/name` - Application name
- `app.kubernetes.io/instance` - Instance identifier
- `app.kubernetes.io/version` - Application version
- `app.kubernetes.io/component` - Component type
- `app.kubernetes.io/part-of` - Parent application
- `app.kubernetes.io/managed-by` - Management tool

## ConfigMaps and Secrets

- Use ConfigMaps for non-sensitive configuration
- Use External Secrets Operator for secrets
- Never store secrets in Git
- Use immutable ConfigMaps/Secrets when possible
