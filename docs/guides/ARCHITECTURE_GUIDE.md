# Open Horizons Platform - Architecture Guide

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** Architects, Tech Leads, Senior Engineers

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Understanding the Open Horizons Model](#2-understanding-the-open-horizons-model)
3. [High-Level Platform Architecture](#3-high-level-platform-architecture)
4. [Infrastructure Architecture](#4-infrastructure-architecture)
5. [Network Architecture](#5-network-architecture)
6. [Security Architecture](#6-security-architecture)
7. [GitOps Architecture](#7-gitops-architecture)
8. [Observability Architecture](#8-observability-architecture)
9. [AI/ML Architecture](#9-aiml-architecture)
10. [Agent Architecture](#10-agent-architecture)
11. [Data Flow Diagrams](#11-data-flow-diagrams)
12. [Architecture Decision Records](#12-architecture-decision-records)

---

## 1. Introduction

### What is This Guide?

This Architecture Guide explains **how** the Open Horizons Platform is designed and **why** specific technology choices were made. It's intended for architects and engineers who need to understand the platform's internal workings.

> 💡 **Different from the Deployment Guide**
>
> - **Deployment Guide:** Step-by-step instructions to deploy the platform
> - **Architecture Guide (this):** Explains the design decisions and component interactions

### Who Should Read This?

| Role | What You'll Learn |
|------|-------------------|
| **Cloud Architects** | Overall platform design and Azure service integration |
| **Security Architects** | Zero-trust implementation and security controls |
| **Platform Engineers** | Component interactions and customization points |
| **DevOps Engineers** | GitOps workflow and CI/CD architecture |
| **Tech Leads** | Technology choices and trade-offs |

### Key Concepts You'll Understand

After reading this guide, you'll understand:

1. Why we use the "Open Horizons" organizational model
2. How Azure services are integrated together
3. How network isolation and security work
4. How GitOps enables declarative infrastructure
5. How observability components interact
6. How AI capabilities are integrated

---

## 2. Understanding the Open Horizons Model

### 2.1 What is the Open Horizons Framework?

> 💡 **Origin of the Model**
>
> The Open Horizons Platform is a solution created in partnership with **Microsoft** and
> **GitHub**. It helps organizations balance maintaining current operations
> (H1) while developing improvements (H2) and exploring future opportunities (H3).

The Open Horizons model organizes the platform into three layers with different purposes:

![Open Horizons Framework](../assets/arch-three-horizons-framework.svg)

### 2.2 Why Use Open Horizons?

| Benefit | Explanation |
|---------|-------------|
| **Clear Dependencies** | Each horizon has well-defined dependencies on lower horizons |
| **Independent Scaling** | Horizons can evolve at different speeds |
| **Risk Isolation** | Experimental H3 features don't affect stable H1 infrastructure |
| **Incremental Adoption** | Organizations can start with H1, add H2/H3 when ready |
| **Budget Control** | Each horizon can have separate cost allocation |

### 2.3 Component Mapping by Horizon

#### H1: Foundation Components

| Component | Azure Service | Purpose | Required? |
|-----------|---------------|---------|-----------|
| **AKS** | Azure Kubernetes Service | Container orchestration | Yes |
| **ACR** | Azure Container Registry | Container image storage | Yes |
| **Key Vault** | Azure Key Vault | Secrets and certificates | Yes |
| **VNet** | Azure Virtual Network | Network isolation | Yes |
| **NSG** | Network Security Groups | Firewall rules | Yes |
| **Managed Identity** | Azure AD Managed Identity | Passwordless auth | Yes |
| **Defender** | Defender for Cloud | Threat protection | Recommended |
| **Purview** | Microsoft Purview | Data governance | Optional |
| **PostgreSQL** | Azure Database for PostgreSQL | Relational database | Optional |
| **Redis** | Azure Cache for Redis | Caching | Optional |

#### H2: Enhancement Components

| Component | Technology | Purpose | Required? |
|-----------|------------|---------|-----------|
| **ArgoCD** | CNCF ArgoCD | GitOps deployment | Recommended |
| **External Secrets** | External Secrets Operator | Secret synchronization | Recommended |
| **Prometheus** | CNCF Prometheus | Metrics collection | Recommended |
| **Grafana** | Grafana | Dashboards | Recommended |
| **Alertmanager** | CNCF Alertmanager | Alert routing | Recommended |
| **Gatekeeper** | OPA Gatekeeper | Policy enforcement | Recommended |
| **Backstage** | Backstage | Developer portal | Optional |
| **GitHub Runners** | Self-hosted runners | CI/CD execution | Optional |

#### H3: Innovation Components

| Component | Technology | Purpose | Required? |
|-----------|------------|---------|-----------|
| **AI Foundry** | Azure OpenAI | LLM capabilities | Optional |
| **GPT-4o** | OpenAI GPT-4o | Text generation | Optional |
| **Embeddings** | text-embedding-3 | Vector embeddings | Optional |
| **Agents** | Custom implementations | Intelligent automation | Optional |

---

## 3. High-Level Platform Architecture

### 3.1 Layered Architecture Diagram

![Layered Platform Architecture](../assets/arch-layered-architecture.svg)

### 3.2 Design Principles

> 💡 **What are Design Principles?**
>
> Design principles are the rules we follow when making architecture decisions.
> They ensure consistency and help avoid common mistakes.

| Principle | What It Means | How We Implement It |
|-----------|---------------|---------------------|
| **Infrastructure as Code** | All infrastructure is defined in code, not created manually | Terraform for Azure resources, Kubernetes manifests for apps |
| **GitOps** | Git is the single source of truth for deployments | ArgoCD watches Git repos and syncs changes automatically |
| **Zero Trust** | Never trust, always verify | Private endpoints, workload identity, network policies |
| **Immutable Infrastructure** | Don't modify running systems; replace them | Rolling updates, blue-green deployments |
| **Observable** | Everything can be measured and monitored | Prometheus metrics, Grafana dashboards, alerts |
| **Self-Service** | Developers can deploy without ops intervention | Golden Path templates, Backstage portal |
| **Policy as Code** | Security policies are defined in code | Gatekeeper/OPA constraints |
| **Cost Awareness** | Monitor and optimize costs continuously | Azure Cost Management, budgets, alerts |

---

## 4. Infrastructure Architecture

### 4.1 AKS Cluster Architecture

> 💡 **What is AKS?**
>
> Azure Kubernetes Service (AKS) is a managed Kubernetes service. Azure manages
> the control plane (API server, etcd, scheduler), and you only manage the
> worker nodes where your applications run.

![AKS Cluster Architecture](../assets/arch-aks-cluster.svg)

### 4.2 Why Multiple Node Pools?

| Node Pool | Purpose | Why Separate? |
|-----------|---------|---------------|
| **System** | Kubernetes system components | Isolates system pods from application disruptions |
| **Workload** | Application pods | Can scale independently based on app demand |
| **AI** | GPU-accelerated workloads | Expensive GPUs only used when needed (scales to 0) |

### 4.3 Cluster Add-ons

These are additional capabilities we enable on the AKS cluster:

| Add-on | What It Does | Why We Enable It |
|--------|--------------|------------------|
| **Azure CNI** | Network plugin | Assigns Azure VNet IPs to pods for better network integration |
| **Azure Policy** | Policy enforcement | Integrates with Azure Policy for compliance |
| **Workload Identity** | Pod authentication | Allows pods to authenticate to Azure without secrets |
| **Key Vault CSI** | Secret injection | Mounts Key Vault secrets as files in pods |
| **Blob CSI** | Blob storage | Allows pods to use Azure Blob storage as volumes |

---

## 5. Network Architecture

### 5.1 Network Topology

> 💡 **Why Network Architecture Matters**
>
> Proper network design is critical for:
> - **Security:** Isolating sensitive workloads
> - **Performance:** Reducing latency between components
> - **Compliance:** Meeting regulatory requirements for data isolation

![Network Topology](../assets/arch-network-topology.svg)

### 5.2 Private DNS Zones

> 💡 **What are Private DNS Zones?**
>
> When you create a private endpoint for an Azure service (like Key Vault),
> it gets a private IP (e.g., 10.0.4.5). Private DNS zones automatically
> resolve the service's public DNS name to this private IP when queried
> from within the VNet.

| Service | Private DNS Zone | Example Resolution |
|---------|------------------|-------------------|
| Key Vault | `privatelink.vaultcore.azure.net` | kv-myapp.vault.azure.net → 10.0.4.5 |
| ACR | `privatelink.azurecr.io` | myacr.azurecr.io → 10.0.4.4 |
| PostgreSQL | `privatelink.postgres.database.azure.com` | mydb.postgres.database.azure.com → 10.0.4.6 |
| OpenAI | `privatelink.openai.azure.com` | myoai.openai.azure.com → 10.0.4.7 |

### 5.3 Network Security Groups (NSGs)

NSGs act as firewalls at the subnet level:

![NSG Rules](../assets/nsg-rules-table.svg)

---

## 6. Security Architecture

### 6.1 Zero Trust Model

> 💡 **What is Zero Trust?**
>
> Zero Trust is a security model where you never trust anything by default,
> even if it's inside your network. Every request must be verified.

![Zero Trust Implementation](../assets/arch-zero-trust.svg)

### 6.2 Workload Identity

> 💡 **What is Workload Identity?**
>
> Workload Identity allows Kubernetes pods to authenticate to Azure services
> using Azure AD tokens, without needing secrets or passwords.

![Workload Identity](../assets/arch-workload-identity.svg)

### 6.3 Secret Management Flow

![Secret Management Architecture](../assets/arch-secret-management.svg)

---

## 7. GitOps Architecture

### 7.1 What is GitOps?

> 💡 **GitOps Explained Simply**
>
> GitOps means **Git is the source of truth** for your infrastructure.
> Instead of running commands to deploy, you commit changes to Git,
> and a tool (ArgoCD) automatically applies them to your cluster.

### 7.2 GitOps Workflow

![GitOps Workflow](../assets/arch-gitops-workflow.svg)

### 7.3 ArgoCD Application Model

![ArgoCD Application Hierarchy](../assets/arch-argocd-app-model.svg)

### 7.4 Sync Strategies

| Strategy | When to Use | How It Works |
|----------|-------------|--------------|
| **Auto-Sync** | Development environments | ArgoCD automatically applies changes when Git changes |
| **Manual Sync** | Production | Human must click "Sync" to apply changes |
| **Self-Heal** | Always-on environments | ArgoCD reverts manual changes made directly to cluster |
| **Prune** | Cleanup needed | Deletes resources removed from Git |

---

## 8. Observability Architecture

### 8.1 Observability Stack

> 💡 **What is Observability?**
>
> Observability is the ability to understand what's happening inside your system
> by looking at its external outputs: **metrics**, **logs**, and **traces**.

![Observability Architecture](../assets/arch-observability-stack.svg)

### 8.2 Metrics Collection

![Metrics Collection](../assets/arch-metrics-collection.svg)

### 8.3 Alert Flow

![Alert Flow](../assets/arch-alert-flow.svg)

---

## 9. AI/ML Architecture

### 9.1 AI Foundry Integration

> 💡 **What is Azure AI Foundry?**
>
> Azure AI Foundry is a comprehensive enterprise AI platform that goes far beyond just Azure OpenAI.
> It provides a unified hub for building, deploying, and managing AI solutions at scale, including:
>
> - **Multiple AI Model Providers:** Foundation models, fine-tuned models, and embedding services via a managed model gateway
> - **AI Agent Development:** Tools for building autonomous agents for enterprise workflows
> - **RAG & Knowledge Management:** Vector search, document intelligence, and knowledge bases
> - **Responsible AI:** Built-in content safety, prompt shields, and governance controls
> - **MLOps Integration:** Model versioning, deployment pipelines, and monitoring
> - **Enterprise Security:** Private endpoints, managed identities, and compliance certifications

![AI Foundry Architecture](../assets/arch-ai-foundry.svg)

### 9.2 Model Routing by SDLC Phase

Open Horizons uses task-specific model routing to optimize cost and quality. The routing is defined in [`.github/model-routing.yaml`](../../.github/model-routing.yaml).

| SDLC Phase | Task | Recommended Models | Extended Thinking | Cost |
|:-----------|:-----|:-------------------|:-----------------:|:----:|
| **Specification** | Vague requirements → structured specs | Claude Opus 4.6, GPT-5.4 | Yes | High |
| **Architecture** | Planning affecting >5 files | Claude Opus 4.6, GPT-5.4 | Yes | High |
| **TDD** | Test cases from clear spec | Claude Sonnet 4.6, GPT-5.1 | No | Medium |
| **Implementation** | Feature code, 3-10 files | Claude Sonnet 4.6, GPT-5.1 | No | Medium |
| **Docstrings** | Commit messages, changelogs | Claude Haiku 4.5, GPT-5.1 | No | Low |
| **Code Review** | Quality + security review | Claude Opus 4.6, GPT-5.4 | Yes | High |
| **Summarization** | PR descriptions, release notes | Claude Haiku 4.5, GPT-5.1 | No | Low |

**Model Routing Decision Tree:**

```mermaid
flowchart TD
    A["Developer Request"] --> B{"Is the spec clear?"}
    B -->|No| C["Specification\nOpus 4.6 / GPT-5.4\nAsk + Extended Thinking"]
    B -->|Yes| D{"Affects more\nthan 5 files?"}
    D -->|Yes| E["Architecture\nOpus 4.6 / GPT-5.4\nAsk + Extended Thinking"]
    D -->|No| F{"Tests written?"}
    F -->|No| G["TDD Spec\nSonnet 4.6 / GPT-5.1\nEdit Mode"]
    F -->|Yes| H["Implementation\nSonnet 4.6 / GPT-5.1\nAgent + Hooks"]
    C --> I{{"Human Review Gate"}}
    E --> I
    I --> G
    G --> H
    H --> J["Code Review\nOpus 4.6 / GPT-5.4\nAsk + Extended Thinking"]
    J --> K{"Boilerplate?"}
    K -->|Yes| L["Summarization\nHaiku 4.5 / GPT-5.1"]
    K -->|No| M["Done"]
    L --> M

    style C fill:#F25022,color:#fff
    style E fill:#F25022,color:#fff
    style G fill:#00A4EF,color:#fff
    style H fill:#00A4EF,color:#fff
    style J fill:#F25022,color:#fff
    style L fill:#7FBA00,color:#fff
    style I fill:#FFB900,color:#000
```

### 9.3 Agentic Deployment Workflow

Open Horizons supports fully agentic deployment via `@deploy`. The workflow orchestrates multiple specialized agents, each using the optimal model for its phase.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Deploy as @deploy<br/>Opus 4.6 / GPT-5.4
    participant Azure as @azure-portal-deploy<br/>Sonnet 4.6 / GPT-5.1
    participant TF as @terraform<br/>Sonnet 4.6 / GPT-5.1
    participant BS as @backstage-expert<br/>Sonnet 4.6 / GPT-5.1
    participant GH as @github-integration<br/>Sonnet 4.6 / GPT-5.1
    participant SRE as @sre<br/>Sonnet 4.6 / GPT-5.1
    participant Sec as @security<br/>Opus 4.6 / GPT-5.4

    Dev->>Deploy: @deploy Deploy platform to dev
    Deploy->>Deploy: Plan deployment sequence
    Deploy->>Deploy: Validate prerequisites

    rect rgb(235, 243, 252)
        Note over Azure,TF: Phase 1 Infrastructure 30-45 min
        Deploy->>Azure: Provision AKS KeyVault ACR
        Azure-->>Deploy: Infrastructure ready
        Deploy->>TF: terraform init plan apply
        TF-->>Deploy: 16 modules applied
    end

    rect rgb(240, 247, 230)
        Note over BS,GH: Phase 2 Platform 25-35 min
        Deploy->>BS: Deploy Backstage ArgoCD Grafana
        Deploy->>GH: Configure GitHub App OAuth
        BS-->>Deploy: Portal live
        GH-->>Deploy: Integration complete
    end

    rect rgb(252, 234, 229)
        Note over SRE,Sec: Phase 3 Verification 15-25 min
        Deploy->>SRE: Post-deploy health checks
        SRE-->>Deploy: All services healthy
        Deploy->>Sec: Security audit policy review
        Sec-->>Deploy: Compliant
    end

    Deploy-->>Dev: Platform deployed successfully
```

**Agent-to-Model Mapping for Deployment:**

| Deploy Phase | Agent | Mode | Recommended Models |
|:-------------|:------|:-----|:-------------------|
| Planning and sequencing | `@deploy` | Ask | Claude Opus 4.6, GPT-5.4 |
| Azure provisioning | `@azure-portal-deploy` | Agent | Claude Sonnet 4.6, GPT-5.1 |
| Infrastructure as Code | `@terraform` | Agent | Claude Sonnet 4.6, GPT-5.1 |
| Portal deployment | `@backstage-expert` | Agent | Claude Sonnet 4.6, GPT-5.1 |
| GitHub integration | `@github-integration` | Agent | Claude Sonnet 4.6, GPT-5.1 |
| Post-deploy verification | `@sre` | Ask | Claude Sonnet 4.6, GPT-5.1 |
| Security audit | `@security` | Ask | Claude Opus 4.6, GPT-5.4 |
| Documentation | `@docs` | Ask | Claude Haiku 4.5, GPT-5.1 |

> **Deploy times:** Dev 75-105 min · Staging 100-130 min · Production 130-175 min

---

## 10. Agent Architecture

### 10.1 Agent Categories

The platform includes 18 Copilot Chat agents organized by adoption stage:

![Agent Architecture](../assets/arch-agent-categories.svg)

### 10.2 Agent Handoff Flow

Agents hand off work to specialized peers based on task type. Each agent uses the model best suited to its role.

```mermaid
flowchart LR
    subgraph Planning["Planning · Opus 4.6 / GPT-5.4"]
        A["@deploy"] --> B["@architect"]
    end

    subgraph Impl["Implementation · Sonnet 4.6 / GPT-5.1"]
        B --> C["@terraform"]
        B --> D["@devops"]
        B --> E["@platform"]
    end

    subgraph Verify["Verification · Opus 4.6 / GPT-5.4"]
        C --> F["@security"]
        D --> F
        E --> F
        F --> G["@reviewer"]
    end

    subgraph Ops["Operations · Sonnet 4.6 / GPT-5.1"]
        G --> H["@sre"]
        H --> I["@docs"]
    end

    style A fill:#F25022,color:#fff
    style B fill:#F25022,color:#fff
    style C fill:#00A4EF,color:#fff
    style D fill:#00A4EF,color:#fff
    style E fill:#00A4EF,color:#fff
    style F fill:#F25022,color:#fff
    style G fill:#F25022,color:#fff
    style H fill:#00A4EF,color:#fff
    style I fill:#7FBA00,color:#fff
```

---

## 11. Data Flow Diagrams

### 11.1 Application Deployment Flow

![Application Deployment Flow](../assets/arch-deployment-flow.svg)

```mermaid
flowchart LR
    A["Developer"] -->|git push| B["GitHub"]
    B -->|webhook| C["ArgoCD"]
    C -->|sync| D["AKS Cluster"]
    D -->|pull image| E["ACR"]
    D -->|read secrets| F["Key Vault"]
    D -->|emit metrics| G["Prometheus"]
    G -->|visualize| H["Grafana"]

    style A fill:#FFB900,color:#000
    style B fill:#1A1A1A,color:#fff
    style C fill:#F25022,color:#fff
    style D fill:#0078D4,color:#fff
    style E fill:#0078D4,color:#fff
    style F fill:#0078D4,color:#fff
    style G fill:#7FBA00,color:#fff
    style H fill:#7FBA00,color:#fff
```

### 11.2 Secret Access Flow

![Secret Access Data Flow](../assets/arch-secret-access-flow.svg)

```mermaid
flowchart LR
    A["Pod"] -->|ServiceAccount| B["Workload Identity"]
    B -->|federated token| C["Azure AD"]
    C -->|access token| D["Key Vault"]
    D -->|secret value| E["ESO Controller"]
    E -->|creates| F["K8s Secret"]
    F -->|mounts| A

    style A fill:#00A4EF,color:#fff
    style B fill:#FFB900,color:#000
    style C fill:#0078D4,color:#fff
    style D fill:#0078D4,color:#fff
    style E fill:#7FBA00,color:#fff
    style F fill:#00A4EF,color:#fff
```

---

## 12. Architecture Decision Records

### ADR-001: Use AKS Instead of Self-Managed Kubernetes

**Status:** Accepted

**Context:** We need a Kubernetes platform for container orchestration.

**Decision:** Use Azure Kubernetes Service (AKS) instead of self-managed Kubernetes.

**Rationale:**
- Azure manages the control plane (99.95% SLA)
- Automatic security patches
- Deep Azure integration (identity, networking, storage)
- Lower operational overhead
- Cost: Only pay for worker nodes

**Trade-offs:**
- Less control over control plane configuration
- Tied to Azure's upgrade schedule

---

### ADR-002: Use ArgoCD for GitOps

**Status:** Accepted

**Context:** We need a mechanism to deploy applications declaratively.

**Decision:** Use ArgoCD for GitOps-based deployments.

**Rationale:**
- CNCF graduated project (mature, well-maintained)
- Excellent UI for visibility
- Supports Helm, Kustomize, plain YAML
- Application-centric model fits our needs
- Strong community support

**Alternatives Considered:**
- Flux: Good but less intuitive UI
- Jenkins X: More complex, heavier
- Spinnaker: Enterprise-focused, complex

---

### ADR-003: Use Azure CNI Networking

**Status:** Accepted

**Context:** Need to choose Kubernetes network plugin.

**Decision:** Use Azure CNI instead of kubenet.

**Rationale:**
- Pods get VNet IP addresses directly
- Better integration with Azure services
- Required for some features (Windows nodes, network policies)
- Better performance for large clusters

**Trade-offs:**
- Requires more IP addresses (need larger subnets)
- More complex IP planning

---

### ADR-004: Use External Secrets Operator

**Status:** Accepted

**Context:** Applications need access to secrets stored in Key Vault.

**Decision:** Use External Secrets Operator instead of Key Vault CSI driver.

**Rationale:**
- Works with standard Kubernetes Secrets (no application changes)
- Supports multiple secret stores (flexibility)
- Automatic refresh of secrets
- Better GitOps compatibility

**Trade-offs:**
- Additional component to maintain
- Secrets exist in-cluster (encrypted at rest)

---

## Summary

This Architecture Guide covered:

1. **Open Horizons Model:** How the platform is organized into Foundation, Enhancement, and Innovation layers
2. **Platform Architecture:** High-level view of all components
3. **Infrastructure:** AKS cluster design and node pools
4. **Networking:** VNet topology, subnets, and private endpoints
5. **Security:** Zero trust implementation and secret management
6. **GitOps:** ArgoCD workflow and application model
7. **Observability:** Prometheus, Grafana, and alerting
8. **AI/ML:** Azure AI Foundry - enterprise AI hub with multiple model providers and agent capabilities
9. **Agents:** 18 Copilot Chat Agents for development assistance
10. **Data Flows:** How deployments and secret access work
11. **ADRs:** Key architecture decisions and rationale

For implementation details, see the [Deployment Guide](./DEPLOYMENT_GUIDE.md).

---

## 🤖 Using Copilot Agents for Architecture

| Task | Agent | Example Prompt |
|------|-------|---------------|
| System design | `@architect` | "Design a microservice architecture for order processing" |
| WAF review | `@architect` | "Evaluate this design against the Reliability WAF pillar" |
| Module structure | `@terraform` | "Help me decompose this into reusable Terraform modules" |
| Security review | `@security` | "Review this architecture for Zero Trust compliance" |
| ADR creation | `@docs` | "Create an ADR for choosing Cosmos DB over PostgreSQL" |

> **Tip:** `@architect` will create Mermaid diagrams, evaluate trade-offs, and write ADRs. It automatically hands off to `@terraform` for implementation and `@security` for review.

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [Deployment Guide](./DEPLOYMENT_GUIDE.md) | Step-by-step platform deployment instructions |
| [Module Reference](./MODULE_REFERENCE.md) | Detailed inputs/outputs for all Terraform modules |
| [Performance Tuning Guide](./PERFORMANCE_TUNING_GUIDE.md) | Optimization recommendations for all components |
| [Administrator Guide](./ADMINISTRATOR_GUIDE.md) | Day-2 operations and maintenance procedures |

## Next Steps

- **Deploy the platform**: Follow the [Deployment Guide](./DEPLOYMENT_GUIDE.md) to provision infrastructure
- **Review module details**: See [Module Reference](./MODULE_REFERENCE.md) for all module configurations
- **Configure monitoring**: Set up observability stack — see [Administrator Guide](./ADMINISTRATOR_GUIDE.md)

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
