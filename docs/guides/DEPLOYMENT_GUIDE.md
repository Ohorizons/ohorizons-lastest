# Open Horizons Platform - Complete Deployment Guide

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Estimated Time:** 2-4 hours (full platform)
> **Difficulty Level:** Beginner to Intermediate

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Understanding the Architecture](#2-understanding-the-architecture)
3. [Prerequisites](#3-prerequisites)
4. [Step 1: Azure Environment Setup](#step-1-azure-environment-setup)
5. [Step 2: GitHub Organization Setup](#step-2-github-organization-setup)
6. [Step 3: Clone and Configure the Repository](#step-3-clone-and-configure-the-repository)
7. [Step 4: Deploy H1 Foundation Layer](#step-4-deploy-h1-foundation-layer)
8. [Step 5: Verify H1 Foundation](#step-5-verify-h1-foundation)
9. [Step 6: Deploy H2 Enhancement Layer](#step-6-deploy-h2-enhancement-layer)
10. [Step 7: Verify H2 Enhancement](#step-7-verify-h2-enhancement)
11. [Step 8: Deploy H3 Innovation Layer (Optional)](#step-8-deploy-h3-innovation-layer-optional)
12. [Step 9: Final Platform Verification](#step-9-final-platform-verification)
13. [Step 10: Post-Deployment Configuration](#step-10-post-deployment-configuration)
14. [Troubleshooting Common Issues](#troubleshooting-common-issues)
15. [Appendix A: File Reference](#appendix-a-file-reference)
16. [Appendix B: Environment Variables Reference](#appendix-b-environment-variables-reference)
17. [Appendix C: Rollback Procedures](#appendix-c-rollback-procedures)

---

## 1. Introduction

### What is the Open Horizons Platform

The Open Horizons Platform is a **complete platform engineering solution** that helps organizations build and manage cloud-native applications on Azure. Think of it as a "starter kit" that provides everything you need to run modern applications in production.

### What Will You Learn

By following this guide, you will:

- Set up a complete Kubernetes platform on Azure
- Configure GitOps for automated deployments
- Implement security best practices
- Set up monitoring and observability
- (Optionally) Enable AI capabilities

### Who Is This Guide For

This guide is designed for:

- **DevOps Engineers** setting up platform infrastructure
- **Platform Engineers** building internal developer platforms
- **Cloud Architects** designing Azure solutions
- **Developers** who want to understand the underlying platform

> 💡 **No prior Kubernetes or Terraform experience required!**
> We explain every concept before asking you to execute commands.
>
> 🤖 **Need help?**
> Use the **Copilot Agents** in VS Code for guidance.
>
> - Ask `@deploy` to deploy the platform (recommended!)
> - Ask `@onboarding` for a walkthrough
> - Ask `@terraform` to explain configurations
> - See [AGENTS.md](../../AGENTS.md) for the full playbook

---

## Choose Your Deployment Method

There are **three ways** to deploy the Open Horizons platform. Choose the one that fits your experience level:

### Option A: Agent-Guided (Easiest — Interactive)

In VS Code with GitHub Copilot Chat, simply type:
```
@deploy Deploy the platform to dev environment
```
The `@deploy` agent walks you through each step interactively, running commands, validating results, and fixing issues along the way.

**Best for:** First-time deployments, learning the platform.

### Option B: Automated Script (Recommended — Fast)

```bash
# Dry-run first (no resources created)
./scripts/deploy-full.sh --environment dev --dry-run

# Deploy everything
./scripts/deploy-full.sh --environment dev

# Deploy specific horizon
./scripts/deploy-full.sh --environment dev --horizon h1

# Production with all features
./scripts/deploy-full.sh --environment prod --horizon all
```

**Flags:**

| Flag | Description |
|------|-------------|
| `--environment`, `-e` | **Required:** dev, staging, or prod |
| `--horizon`, `-h` | h1, h2, h3, or all (default: all) |
| `--dry-run` | Only terraform plan, no apply |
| `--auto-approve` | Skip prompts (for CI/CD) |
| `--destroy` | Teardown in reverse order |
| `--resume` | Resume from last checkpoint |

**Best for:** Experienced users, CI/CD integration, repeatable deployments.

### Option C: Manual Step-by-Step (Full Control)

Follow the rest of this guide — 10 detailed steps with copy-paste commands, explanations, and verification at each phase.

**Best for:** Learning, custom configurations, environments with special requirements.

---

## 2. Understanding the Architecture

Before we start deploying, let's understand **what** we're building and **why**.

### 2.1 The Open Horizons Model

The platform is organized into three "horizons" (layers), each building on the previous one:

![Open Horizons Architecture](../assets/arch-three-horizons-framework.svg)

### 2.2 What Each Horizon Contains

#### H1: Foundation (Required)

> 🎯 **Purpose:** Provides the basic infrastructure that everything else runs on.

| Component | What It Does | Why We Need It |
| :--- | :--- | :--- |
| **AKS Cluster** | Kubernetes cluster managed by Azure | Runs all our containerized applications |
| **Container Registry** | Stores Docker images | Where we push our application images |
| **Key Vault** | Stores secrets securely | Keeps passwords, API keys safe |
| **Virtual Network** | Private network in Azure | Isolates our resources from the internet |
| **Defender for Cloud** | Security monitoring | Detects threats and vulnerabilities |
| **Managed Identities** | Secure authentication | Applications authenticate without passwords |

#### H2: Enhancement (Recommended)

> 🎯 **Purpose:** Adds developer productivity and operational tools.

| Component | What It Does | Why We Need It |
| :--- | :--- | :--- |
| **ArgoCD** | GitOps continuous deployment | Automatically deploys changes from Git |
| **Backstage Portal** | Developer self-service portal | Developers create services easily |
| **External Secrets** | Syncs secrets from Key Vault | Kubernetes gets secrets automatically |
| **Prometheus + Grafana** | Monitoring and dashboards | See what's happening in the platform |
| **Gatekeeper** | Policy enforcement | Prevents misconfigurations |

#### H3: Innovation (Optional)

> 🎯 **Purpose:** Enables AI and machine learning capabilities.

| Component | What It Does | Why We Need It |
| :--- | :--- | :--- |
| **AI Foundry** | Azure OpenAI Service | GPT-4, embeddings, AI models |
| **MLOps Pipelines** | ML model lifecycle | Train, deploy, monitor ML models |
| **Intelligent Agents** | AI-powered automation | Automate complex tasks with AI |

### 2.3 Deployment Order and Timeline

We deploy in phases because each layer depends on the previous one:

```
Phase 1          Phase 2          Phase 3          Phase 4          Phase 5
[Prerequisites]  [H1 Foundation]  [H1 Verify]      [H2 Enhancement] [H3 Innovation]
    30 min    →     30 min     →    15 min     →      30 min      →    30 min
                                                                    (optional)
```

| Phase | What Happens | Time | Dependencies |
|-------|-------------|------|--------------|
| **Phase 1** | Azure + GitHub setup | 30 min | Azure subscription, GitHub org |
| **Phase 2** | Deploy H1 Foundation | 30 min | Phase 1 complete |
| **Phase 3** | Verify H1 works | 15 min | Phase 2 complete |
| **Phase 4** | Deploy H2 Enhancement | 30 min | Phase 3 complete |
| **Phase 5** | Deploy H3 Innovation | 30 min | Phase 4 complete (optional) |

---

## 3. Prerequisites

Before starting, you need to gather some information and install some tools. This section ensures you have everything ready.

### 3.1 What You Need Before Starting

#### Required Accounts and Access

| Requirement | How to Get It | Why We Need It |
|-------------|---------------|----------------|
| **Azure Subscription** | [Create Azure Account](https://azure.microsoft.com/free/) | Where all resources will be created |
| **Azure Permissions** | Ask your Azure admin for "Owner" or "Contributor + User Access Administrator" | To create resources and assign permissions |
| **GitHub Organization** | [Create Organization](https://github.com/organizations/new) | Where the code will live |
| **GitHub Admin Access** | Be an owner of the organization | To configure secrets and workflows |

> ⚠️ **Important: Check Your Permissions First!**
>
> Many deployment failures happen because of insufficient permissions. Before proceeding:
>
> 1. Confirm you can create resources in your Azure subscription
> 2. Confirm you're an owner/admin of your GitHub organization
>
> If you're unsure, ask your IT administrator.

#### Required Information (Gather Now!)

Before you begin, collect this information and save it somewhere safe:

```yaml
# Save this in a file called my-deployment-info.yaml
# Fill in YOUR values - these are just examples!

azure:
  # Find this in Azure Portal → Subscriptions
  subscription_id: "12345678-1234-1234-1234-123456789012"

  # Find this in Azure Portal → Microsoft Entra ID → Overview
  tenant_id: "87654321-4321-4321-4321-210987654321"

  # Choose your Azure region (where resources will be created)
  # Options: brazilsouth, eastus, eastus2, westus2, westeurope
  location: "brazilsouth"

github:
  # Your GitHub organization name (not your username!)
  organization: "my-company"

  # Email for notifications
  admin_email: "platform-admin@company.com"

project:
  # Project name: lowercase, no spaces, max 12 characters
  # This will be used in all resource names
  name: "threehorizons"

  # Environment: dev, staging, or prod
  environment: "dev"
```

> 💡 **How to Find Your Azure Subscription ID:**
>
> 1. Go to [Azure Portal](https://portal.azure.com)
> 2. Search for "Subscriptions" in the top search bar
> 3. Click on your subscription
> 4. Copy the "Subscription ID" value
>
> **How to Find Your Tenant ID:**
>
> 1. Go to [Azure Portal](https://portal.azure.com)
> 2. Search for "Microsoft Entra ID" (formerly Azure AD)
> 3. Click on "Overview"
> 4. Copy the "Tenant ID" value

### 3.2 Installing Required Tools

You need several command-line tools installed on your computer. Let's install them one by one.

#### Option A: Quick Install (macOS with Homebrew)

If you're on macOS and have Homebrew installed, run these commands:

```bash
# Install all tools at once
brew install azure-cli terraform kubectl helm gh jq yq git
```

#### Option B: Quick Install (Linux/Ubuntu)

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# kubectl
az aks install-cli

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# jq and yq
sudo apt install -y jq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

#### Option C: Individual Installation (All Platforms)

| Tool | Version Required | Download Link | What It Does |
|------|-----------------|---------------|--------------|
| **Azure CLI** | 2.50.0+ | [Install Guide](https://docs.microsoft.com/cli/azure/install-azure-cli) | Manage Azure resources |
| **Terraform** | 1.5.0+ | [Download](https://terraform.io/downloads) | Infrastructure as Code |
| **kubectl** | 1.28.0+ | Run `az aks install-cli` after Azure CLI | Manage Kubernetes |
| **Helm** | 3.12.0+ | [Install Guide](https://helm.sh/docs/intro/install/) | Kubernetes package manager |
| **GitHub CLI** | 2.30.0+ | [Download](https://cli.github.com/) | Manage GitHub from terminal |
| **jq** | 1.6+ | [Download](https://stedolan.github.io/jq/download/) | Parse JSON in terminal |
| **yq** | 4.30.0+ | [Download](https://github.com/mikefarah/yq/releases) | Parse YAML in terminal |
| **Git** | 2.40.0+ | [Download](https://git-scm.com/downloads) | Version control |

### 3.3 Verify All Tools Are Installed

After installing, verify everything works:

```bash
# Run this command to check all tools
echo "=== Checking installed tools ===" && \
az --version | head -1 && \
terraform version | head -1 && \
kubectl version --client -o yaml | grep gitVersion && \
helm version --short && \
gh --version && \
jq --version && \
yq --version && \
git --version
```

**Expected output (versions may vary):**

```
=== Checking installed tools ===
azure-cli                         2.55.0
Terraform v1.6.6
  gitVersion: v1.29.0
v3.14.0+g3fc9f4b
gh version 2.40.0 (2023-12-13)
jq-1.7
yq (https://github.com/mikefarah/yq/) version v4.40.5
git version 2.42.0
```

> ⚠️ **If any command fails:**
>
> The tool is either not installed or not in your PATH. Revisit the installation
> instructions for that specific tool.

---

## Step 1: Azure Environment Setup

**⏱️ Time Required:** 30 minutes
**📁 Related Files:** `scripts/validate-prerequisites.sh`

In this step, we'll:

1. Log into Azure
2. Register required services
3. Create a Service Principal (a "robot account" for Terraform)

### 1.1 Log Into Azure

> 💡 **What is Azure CLI Login?**
>
> The Azure CLI (`az`) is a command-line tool that lets you manage Azure resources.
> When you "login", you're authenticating your terminal session with your Azure account.

**Action: Open your terminal and run:**

```bash
# This will open a browser window for you to log in
az login
```

**What happens:**

1. A browser window opens
2. You log in with your Azure credentials
3. The browser shows "You have logged in"
4. Return to your terminal

**After login, verify you're in the right subscription:**

```bash
# List all subscriptions you have access to
az account list --output table
```

**Expected output:**

```
Name                    CloudName    SubscriptionId                        State    IsDefault
----------------------  -----------  ------------------------------------  -------  -----------
My Development Sub      AzureCloud   12345678-1234-1234-1234-123456789012  Enabled  True
Production Sub          AzureCloud   87654321-4321-4321-4321-210987654321  Enabled  False
```

**If you have multiple subscriptions, select the correct one:**

```bash
# Replace with YOUR subscription ID from the table above
az account set --subscription "12345678-1234-1234-1234-123456789012"

# Verify the correct subscription is now active
az account show --query '{Name:name, ID:id, State:state}' --output table
```

**Expected output:**

```
Name                    ID                                    State
----------------------  ------------------------------------  -------
My Development Sub      12345678-1234-1234-1234-123456789012  Enabled
```

> ✅ **Checkpoint:** You should see your subscription name and ID. If not, the login failed.

### 1.2 Register Required Azure Resource Providers

> 💡 **What are Resource Providers?**
>
> Azure is organized into "Resource Providers" - think of them as feature switches.
> Before you can create Kubernetes clusters (Microsoft.ContainerService), container
> registries (Microsoft.ContainerRegistry), etc., you need to "turn on" these providers
> for your subscription.
>
> This is a **one-time setup** per subscription.

**Action: Register all required providers:**

```bash
# This may take 2-5 minutes as each provider registers
echo "Registering Azure Resource Providers..."

# Core infrastructure providers
az provider register --namespace Microsoft.ContainerService
echo "✓ ContainerService (AKS) - registering..."

az provider register --namespace Microsoft.ContainerRegistry
echo "✓ ContainerRegistry (ACR) - registering..."

az provider register --namespace Microsoft.KeyVault
echo "✓ KeyVault - registering..."

az provider register --namespace Microsoft.Network
echo "✓ Network - registering..."

az provider register --namespace Microsoft.ManagedIdentity
echo "✓ ManagedIdentity - registering..."

# Security providers
az provider register --namespace Microsoft.Security
echo "✓ Security (Defender) - registering..."

az provider register --namespace Microsoft.Purview
echo "✓ Purview - registering..."

# AI providers (needed for H3)
az provider register --namespace Microsoft.CognitiveServices
echo "✓ CognitiveServices (AI) - registering..."

# Monitoring providers
az provider register --namespace Microsoft.AlertsManagement
echo "✓ AlertsManagement - registering..."

az provider register --namespace Microsoft.Monitor
echo "✓ Monitor - registering..."

echo ""
echo "All providers queued for registration!"
echo "This process runs in the background and may take 5-10 minutes."
```

**Wait for registration to complete (about 5 minutes), then verify:**

```bash
# Check status of all providers we need
az provider list --query "[?namespace=='Microsoft.ContainerService' || \
  namespace=='Microsoft.ContainerRegistry' || \
  namespace=='Microsoft.KeyVault' || \
  namespace=='Microsoft.Network' || \
  namespace=='Microsoft.ManagedIdentity' || \
  namespace=='Microsoft.Security'].{Provider:namespace, Status:registrationState}" \
  --output table
```

**Expected output (all should say "Registered"):**

```
Provider                        Status
------------------------------  ------------
Microsoft.ContainerRegistry     Registered
Microsoft.ContainerService      Registered
Microsoft.KeyVault              Registered
Microsoft.ManagedIdentity       Registered
Microsoft.Network               Registered
Microsoft.Security              Registered
```

> ⚠️ **If status shows "Registering":**
>
> Wait a few more minutes and run the check again. Registration can take up to 10 minutes.
>
> **If status shows "NotRegistered":**
>
> Run the `az provider register` command again for that specific provider.

### 1.3 Create a Service Principal for Terraform

> 💡 **What is a Service Principal?**
>
> A Service Principal is like a "robot account" for Azure. Instead of Terraform using
> your personal account (which might have 2FA, password expiration, etc.), we create
> a dedicated identity just for automation.
>
> **Why do we need it?**
>
> - **Security:** Limited permissions, can be revoked independently
> - **Automation:** Works in CI/CD pipelines without human interaction
> - **Audit:** All actions are logged under this specific identity

**Step 1: Set up variables**

```bash
# Get your subscription ID automatically
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Choose a name for your Service Principal
# Convention: sp-{project}-{purpose}
SP_NAME="sp-threehorizons-terraform"

# Display the values to confirm
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Service Principal Name: $SP_NAME"
```

**Step 2: Create the Service Principal**

```bash
# Create the Service Principal and save credentials to a file
az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth > azure-credentials.json

# Display the credentials (SAVE THESE SECURELY!)
echo ""
echo "=== IMPORTANT: SAVE THESE CREDENTIALS ==="
cat azure-credentials.json
echo ""
echo "========================================="
```

**Understanding the command:**

| Parameter | Value | Explanation |
|-----------|-------|-------------|
| `--name` | sp-threehorizons-Terraform | Identifier for this Service Principal |
| `--role` | Contributor | Permission level - can create and manage resources |
| `--scopes` | /subscriptions/xxx | Limits access to only this subscription |
| `--sdk-auth` | (flag) | Outputs in a format compatible with GitHub Actions |

**Expected output (save this!):**

```json
{
  "clientId": "abcd1234-ab12-cd34-ef56-abcdef123456",
  "clientSecret": "abc123~XYZ789~verylongsecretstring",
  "subscriptionId": "12345678-1234-1234-1234-123456789012",
  "tenantId": "87654321-4321-4321-4321-210987654321",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

> 🔒 **CRITICAL: Security Warning!**
>
> The `azure-credentials.json` file contains **sensitive secrets** that can control
> your entire Azure subscription!
>
> **DO:**
>
> - Save it in a password manager (1Password, LastPass, etc.)
> - Delete it from your computer after copying to GitHub Secrets
> - Add `azure-credentials.json` to `.gitignore`
>
> **DON'T:**
>
> - Commit this file to Git
> - Share it via email or Slack
> - Leave it on shared computers

### 1.4 Grant Additional Permissions to Service Principal

> 💡 **Why Additional Permissions?**
>
> The "Contributor" role lets us create resources, but we also need:
>
> - **User Access Administrator:** To assign permissions to managed identities
> - **Key Vault Administrator:** To manage secrets in Key Vault

```bash
# Get the Service Principal's Object ID (different from Client ID!)
SP_OBJECT_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv)

echo "Service Principal Object ID: $SP_OBJECT_ID"

# Grant User Access Administrator role
echo "Granting User Access Administrator role..."
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Grant Key Vault Administrator role
echo "Granting Key Vault Administrator role..."
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Key Vault Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

echo "✓ Additional permissions granted!"
```

**If you get "Principal not found" error:**

```bash
# Wait 30 seconds for Azure AD replication, then retry
sleep 30
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### 1.5 Verify Azure Setup is Complete

Let's confirm everything is ready:

```bash
echo ""
echo "=== AZURE SETUP VERIFICATION ==="
echo ""
echo "✓ Subscription: $(az account show --query name -o tsv)"
echo "✓ Subscription ID: $(az account show --query id -o tsv)"
echo "✓ Service Principal: $SP_NAME"
echo ""
echo "Resource Providers Status:"
az provider list --query "[?namespace=='Microsoft.ContainerService'].{Provider:namespace, Status:registrationState}" -o table
echo ""
echo "Credentials file exists: $([ -f azure-credentials.json ] && echo 'YES' || echo 'NO')"
echo ""
echo "=== STEP 1 COMPLETE ==="
```

> ✅ **Checkpoint before proceeding:**
>
> - [ ] You're logged into the correct Azure subscription
> - [ ] All resource providers show "Registered"
> - [ ] You have `azure-credentials.json` saved securely
> - [ ] Additional role assignments succeeded

---

## Step 2: GitHub Organization Setup

**⏱️ Time Required:** 15 minutes
**📁 Related Files:** `.github/workflows/*.yml`

In this step, we'll:

1. Log into GitHub CLI
2. Fork/clone the repository
3. Configure repository secrets
4. Configure repository variables

### 2.1 Log Into GitHub CLI

> 💡 **What is GitHub CLI?**
>
> GitHub CLI (`gh`) lets you interact with GitHub from your terminal. We'll use it
> to manage secrets and repository settings without using the web interface.

```bash
# Start the login process
gh auth login
```

**Follow the interactive prompts:**

1. "What account do you want to log into?" → Select **GitHub.com**
2. "What is your preferred protocol?" → Select **HTTPS**
3. "Authenticate Git with your GitHub credentials?" → Select **Yes**
4. "How would you like to authenticate?" → Select **Login with a web browser**
5. Copy the one-time code shown
6. Press Enter to open the browser
7. Paste the code and authorize

**Verify the login worked:**

```bash
# Check authentication status
gh auth status

# Test that you can access your organization
# Replace YOUR_ORG_NAME with your actual organization name
gh api /orgs/YOUR_ORG_NAME --jq '.login'
```

**Expected output:**

```
github.com
  ✓ Logged in to github.com as your-username (oauth_token)
  ✓ Git operations for github.com configured to use https protocol.

YOUR_ORG_NAME
```

### 2.2 Fork or Clone the Repository

> 💡 **Fork vs Clone: Which to Choose?**
>
> - **Fork (Recommended):** Creates a copy in your organization. Good for customization.
> - **Clone:** Just downloads the code. Good for trying things out.
>
> For production use, we recommend forking.

**Option A: Fork to Your Organization (Recommended)**

```bash
# Fork the repository to your organization
# Replace YOUR_ORG_NAME with your organization name
gh repo fork Ohorizons/agentic-devops-platform \
  --org YOUR_ORG_NAME \
  --clone \
  --remote

# Navigate into the repository
cd agentic-devops-platform

# Verify you're in the right place
pwd
ls -la
```

**Option B: Clone Directly**

```bash
# Clone the repository
git clone https://github.com/Ohorizons/agentic-devops-platform.git

# Navigate into the repository
cd agentic-devops-platform
```

### 2.3 Configure Repository Secrets

> 💡 **What are GitHub Secrets?**
>
> Secrets are encrypted environment variables that GitHub Actions can use. We store
> sensitive data (like Azure credentials) as secrets so they're never exposed in logs
> or code.

**First, make sure you're in the repository directory:**

```bash
# Confirm you're in the right folder
pwd
# Should end with: /agentic-devops-platform

# Check that azure-credentials.json is accessible
ls -la azure-credentials.json 2>/dev/null || echo "File not found - make sure you're in the right directory and the file exists"
```

**Set all required secrets:**

```bash
# Set the full Azure credentials JSON (used by some workflows)
gh secret set AZURE_CREDENTIALS < azure-credentials.json
echo "✓ AZURE_CREDENTIALS set"

# Set individual values (used by Terraform)
# These extract values from azure-credentials.json automatically

gh secret set ARM_CLIENT_ID --body "$(cat azure-credentials.json | jq -r .clientId)"
echo "✓ ARM_CLIENT_ID set"

gh secret set ARM_CLIENT_SECRET --body "$(cat azure-credentials.json | jq -r .clientSecret)"
echo "✓ ARM_CLIENT_SECRET set"

gh secret set ARM_SUBSCRIPTION_ID --body "$(cat azure-credentials.json | jq -r .subscriptionId)"
echo "✓ ARM_SUBSCRIPTION_ID set"

gh secret set ARM_TENANT_ID --body "$(cat azure-credentials.json | jq -r .tenantId)"
echo "✓ ARM_TENANT_ID set"

echo ""
echo "All secrets configured!"
```

**Verify secrets were created:**

```bash
gh secret list
```

**Expected output:**

```
NAME                 UPDATED
ARM_CLIENT_ID        now
ARM_CLIENT_SECRET    now
ARM_SUBSCRIPTION_ID  now
ARM_TENANT_ID        now
AZURE_CREDENTIALS    now
```

> ⚠️ **If you get "no repository detected" error:**
>
> You're not in a git repository. Run `cd agentic-devops-platform` first.
>
> **If you get "secrets are disabled" error:**
>
> Your repository might be a fork with Actions disabled. Enable it in Settings → Actions.

### 2.4 Configure Repository Variables

> 💡 **Secrets vs Variables: What's the Difference?**
>
> - **Secrets:** Encrypted, hidden in logs. For passwords, API keys.
> - **Variables:** Not encrypted, visible in logs. For configuration like project names.

```bash
# Set project configuration variables
# Replace values with your actual values!

gh variable set PROJECT_NAME --body "threehorizons"
echo "✓ PROJECT_NAME set"

gh variable set ENVIRONMENT --body "dev"
echo "✓ ENVIRONMENT set"

gh variable set AZURE_LOCATION --body "brazilsouth"
echo "✓ AZURE_LOCATION set"

gh variable set GITHUB_ORG --body "YOUR_ORG_NAME"  # Replace with your org!
echo "✓ GITHUB_ORG set"

echo ""
echo "All variables configured!"
```

**Verify variables were created:**

```bash
gh variable list
```

**Expected output:**

```
NAME            VALUE           UPDATED
AZURE_LOCATION  brazilsouth     now
ENVIRONMENT     dev             now
GITHUB_ORG      your-org-name   now
PROJECT_NAME    threehorizons   now
```

### 2.5 Verify GitHub Actions is Enabled

```bash
# Check if Actions is enabled for this repository
gh api repos/:owner/:repo/actions/permissions --jq '.enabled'
```

**Expected output:** `true`

**If it shows `false`, enable Actions:**

1. Go to your repository on GitHub.com
2. Click **Settings** → **Actions** → **General**
3. Select "Allow all actions and reusable workflows"
4. Click **Save**

> ✅ **Checkpoint before proceeding:**
>
> - [ ] You're logged into GitHub CLI
> - [ ] Repository is forked/cloned to your organization
> - [ ] All 5 secrets are configured
> - [ ] All 4 variables are configured
> - [ ] GitHub Actions is enabled

---

## Step 3: Clone and Configure the Repository

**⏱️ Time Required:** 15 minutes
**📁 Related Files:** `terraform/terraform.tfvars`, `config/`

In this step, we'll:

1. Verify repository structure
2. Run prerequisites check
3. Create Terraform configuration file

### 3.1 Verify Repository Structure

Let's make sure you have all the files:

```bash
# You should already be in the repository directory
pwd
# Should show: .../agentic-devops-platform

# List the main directories
ls -la
```

**Expected directories:**

| Directory | Contents | Purpose |
|-----------|----------|---------|
| `.github/` | GitHub Actions workflows, templates | CI/CD automation |
| `.github/agents/` | Copilot Chat Agents | 18 agent definitions |
| `argocd/` | ArgoCD configurations | GitOps setup |
| `config/` | Sizing profiles, region configs | Platform configuration |
| `docs/` | Documentation (you're reading it!) | Guides and references |
| `golden-paths/` | Developer templates | Self-service templates |
| `grafana/` | Grafana dashboards | Monitoring visualizations |
| `policies/` | OPA/Gatekeeper policies | Security policies |
| `prometheus/` | Prometheus configuration | Metrics and alerts |
| `scripts/` | Automation scripts | Helper scripts |
| `terraform/` | Infrastructure as Code | All Azure resources |
| `tests/` | Test files | Terratest, unit tests |

### 3.2 Make Scripts Executable

```bash
# Grant execute permission to all shell scripts
chmod +x scripts/*.sh

# Verify they're executable (should show 'x' in permissions)
ls -la scripts/*.sh | head -5
```

**Expected output (note the 'x' in -rwxr-xr-x):**

```
-rwxr-xr-x  1 user  staff  2048 Dec 10 10:00 scripts/bootstrap.sh
-rwxr-xr-x  1 user  staff  1024 Dec 10 10:00 scripts/validate-prerequisites.sh
-rwxr-xr-x  1 user  staff  3072 Dec 10 10:00 scripts/validate-deployment.sh
...
```

### 3.3 Run the Install Wizard (Phase 0)

Before configuring Terraform, run the install wizard to set up your platform identity and generate K8s manifests:

```bash
# Interactive setup — collects all platform configuration
./scripts/install-wizard.sh
```

The wizard will ask for:

| Setting | Description | Example |
|---------|-------------|---------|
| GitHub Organization | Your GitHub org/user | `contoso` |
| GitHub Repository | Your fork name | `open-horizons-platform` |
| Platform Name | K8s resource prefix | `myplatform` |
| Domain | Custom domain (optional) | `portal.contoso.com` |
| Auth Provider | `github`, `entra`, or `guest` | `github` |
| Container Registry | `ghcr` (default), `acr`, or `dockerhub` | `ghcr` |
| Azure Subscription | Your Azure subscription ID | `xxxxxxxx-xxxx-...` |
| AKS Cluster Name | Target AKS cluster | `aks-contoso-dev` |

The wizard writes a `.env` file and optionally runs `scripts/render-k8s.sh` to generate all K8s manifests from templates in `backstage/k8s/templates/`.

> 💡 **Alternatively**, you can configure manually:
> ```bash
> cp .env.example .env
> # Edit .env with your values
> scripts/render-k8s.sh
> ```

### 3.4 Run Prerequisites Validation

```bash
# Run the prerequisites check script
./scripts/validate-prerequisites.sh
```

**Expected output:**

```
=== Open Horizons Platform - Prerequisites Check ===

[✓] Azure CLI: 2.55.0 (minimum: 2.50.0)
[✓] Terraform: 1.6.6 (minimum: 1.5.0)
[✓] kubectl: 1.29.0 (minimum: 1.28.0)
[✓] Helm: 3.14.0 (minimum: 3.12.0)
[✓] GitHub CLI: 2.40.0 (minimum: 2.30.0)
[✓] jq: 1.7 (minimum: 1.6)

All prerequisites met! You can proceed with deployment.
```

> ⚠️ **If any tool shows [✗]:**
>
> Go back to section 3.2 and install the missing tool, then run this check again.

### 3.5 Create Terraform Configuration File

Now we'll create the main configuration file that tells Terraform what to deploy.

**Step 1: Copy the example file**

```bash
# Navigate to terraform directory
cd terraform

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Open for editing (use your preferred editor)
nano terraform.tfvars
# Or: code terraform.tfvars
# Or: vim terraform.tfvars
```

**Step 2: Edit the file with YOUR values**

Here's the complete file with explanations for each setting:

```hcl
# =============================================================================
# OPEN HORIZONS PLATFORM - TERRAFORM CONFIGURATION
# =============================================================================
#
# This file configures what resources Terraform will create in Azure.
# Edit the values below to match your environment.
#
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES - You MUST change these values
# -----------------------------------------------------------------------------

# Project name: Used in all resource names
# Rules: lowercase, no spaces, no special characters, max 12 characters
# Example: "threehorizons" creates resources like "aks-threehorizons-dev"
project_name = "threehorizons"

# Environment: Determines naming and some configurations
# Options: "dev", "staging", "prod"
# Recommendation: Start with "dev" for testing
environment = "dev"

# Azure region where all resources will be created
# Options: "brazilsouth", "eastus", "eastus2", "westus2", "westeurope"
# Choose the region closest to your users
location = "brazilsouth"

# Your Azure subscription ID (from azure-credentials.json)
# Format: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
subscription_id = "PASTE_YOUR_SUBSCRIPTION_ID_HERE"

# Your Azure tenant ID (from azure-credentials.json)
tenant_id = "PASTE_YOUR_TENANT_ID_HERE"

# Your GitHub organization name
# This is used for configuring GitHub integration
github_org = "YOUR_GITHUB_ORG_HERE"

# The name of this repository (usually keep as-is)
github_repo = "agentic-devops-platform"

# -----------------------------------------------------------------------------
# HORIZON ENABLEMENT - What layers to deploy
# -----------------------------------------------------------------------------

# H1 Foundation: Core infrastructure (always required)
enable_h1 = true

# H2 Enhancement: ArgoCD, Observability, Backstage (recommended)
enable_h2 = true

# H3 Innovation: AI Foundry, Azure OpenAI (optional)
# Recommendation: Start with false, enable after H1+H2 are stable
enable_h3 = false

# -----------------------------------------------------------------------------
# SIZING CONFIGURATION - How big should resources be?
# -----------------------------------------------------------------------------

# T-shirt sizing for easy configuration
# Options: "small", "medium", "large", "xlarge"
#
# Profiles:
# - small:  3 nodes, 4 vCPU each, good for dev/test
# - medium: 5 nodes, 8 vCPU each, good for staging
# - large:  7 nodes, 16 vCPU each, good for production
# - xlarge: 10 nodes, 32 vCPU each, good for large production
#
#
# Sizing Implications:
# - small: Minimal resources for testing
# - medium: Balanced performance
# - large: Production capacity
# - xlarge: High throughput workloads

sizing_profile = "small"

# -----------------------------------------------------------------------------
# NETWORKING - IP address ranges
# -----------------------------------------------------------------------------

# Virtual Network CIDR block
# This is the overall IP range for your Azure network
# Default: "10.0.0.0/16" provides 65,536 IP addresses
vnet_cidr = "10.0.0.0/16"

# Subnet configuration
# Each subnet is a smaller range within the VNet
subnet_config = {
  # Where AKS worker nodes run
  aks_nodes = "10.0.0.0/22"  # 1,024 IPs

  # Where Kubernetes pods get their IPs (Azure CNI)
  aks_pods = "10.0.16.0/20"  # 4,096 IPs

  # Where private endpoints connect
  private_endpoints = "10.0.4.0/24"  # 256 IPs

  # For Azure Bastion (secure VM access)
  bastion = "10.0.5.0/26"  # 64 IPs

  # For Application Gateway (load balancer)
  app_gateway = "10.0.6.0/24"  # 256 IPs
}

# -----------------------------------------------------------------------------
# SECURITY FEATURES
# -----------------------------------------------------------------------------

# Enable Microsoft Defender for Cloud
# Provides security recommendations and threat detection
# Cost: Additional charges apply per resource
enable_defender = true

# Enable Microsoft Purview
# Provides data governance and classification
# Cost: Additional charges apply per scan
enable_purview = true

# Enable private AKS cluster
# When true: API server is only accessible from VNet
# When false: API server is accessible from internet (with authentication)
# Recommendation: false for dev, true for production
enable_private_cluster = false

# -----------------------------------------------------------------------------
# RESOURCE TAGS - Metadata for all resources
# -----------------------------------------------------------------------------

# Tags help you organize, track costs, and manage resources
tags = {
  Project     = "ThreeHorizons"
  Environment = "Development"
  Owner       = "platform-team@company.com"  # CHANGE THIS
  CostCenter  = "PLATFORM-001"
  Compliance  = "LGPD"
  ManagedBy   = "Terraform"
}
```

**Step 3: Verify your configuration**

After editing, verify the file is valid:

![Repository Structure](../assets/mod-directory-structure.svg)


**Expected output:**

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching ">= 3.0.0"...
- Installing hashicorp/azurerm v3.85.0...
- Installed hashicorp/azurerm v3.85.0

Terraform has been successfully initialized!
```

**Validate the configuration:**

```bash
terraform validate
```

**Expected output:**

```
Success! The configuration is valid.
```

**Check formatting:**

```bash
terraform fmt -check -recursive
```

**Expected output:** No output means formatting is correct.

> ✅ **Checkpoint before proceeding:**
>
> - [ ] All scripts are executable
> - [ ] Prerequisites check passed
> - [ ] Terraform.tfvars is created with YOUR values
> - [ ] `terraform init` succeeded
> - [ ] `terraform validate` shows "Success"

---

## Step 4: Deploy H1 Foundation Layer

**⏱️ Time Required:** 30 minutes
**📁 Related Files:** `terraform/main.tf`, `terraform/modules/`

This is where we actually create Azure resources! In this step, we'll:

1. Review what will be created
2. Apply the Terraform configuration
3. Save the outputs

> ⚠️ **Cost Warning!**
>
> This step will create Azure resources that **cost money**.
> Please verify your subscription limits and credits.
>
> Make sure you have budget approval before proceeding!

### 4.1 Review the Deployment Plan

> 💡 **What is a Terraform Plan?**
>
> Before making any changes, Terraform shows you exactly what it will do.
> This is called a "plan". Review it carefully before applying!

```bash
# Make sure you're in the terraform directory
cd terraform

# Generate the execution plan
terraform plan -out=h1-foundation.tfplan
```

**This command:**

1. Reads your configuration (Terraform.tfvars)
2. Compares it to what exists in Azure (nothing yet)
3. Shows what it will create
4. Saves the plan to a file

**Expected output (abbreviated):**

```
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.naming.random_string.unique will be created
  + resource "random_string" "unique" {
      + id          = (known after apply)
      + length      = 4
      + lower       = true
      + number      = true
      ...
    }

  # module.networking.azurerm_virtual_network.main will be created
  + resource "azurerm_virtual_network" "main" {
      + name                = "vnet-threehorizons-dev"
      + address_space       = ["10.0.0.0/16"]
      + location            = "brazilsouth"
      + resource_group_name = "rg-threehorizons-dev"
      ...
    }

  # module.aks.azurerm_kubernetes_cluster.main will be created
  + resource "azurerm_kubernetes_cluster" "main" {
      + name                = "aks-threehorizons-dev"
      + kubernetes_version  = "1.29"
      ...
    }

... (more resources)

Plan: 32 to add, 0 to change, 0 to destroy.

──────────────────────────────────────────────────────────────────────────────

Saved the plan to: h1-foundation.tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "h1-foundation.tfplan"
```

**Review the resources being created:**

| Resource Count | What It Creates |
|----------------|-----------------|
| ~5 | Resource groups and naming |
| ~8 | Networking (VNet, subnets, NSGs) |
| ~6 | AKS cluster and node pools |
| ~4 | Container Registry (ACR) |
| ~5 | Key Vault and secrets |
| ~4 | Managed Identities and RBAC |

### 4.2 Apply the H1 Foundation

> ⚠️ **Point of No Return**
>
> Running `terraform apply` will create real Azure resources that cost money.
> Make sure you reviewed the plan above!

```bash
# Apply the saved plan
terraform apply h1-foundation.tfplan
```

**What happens during apply:**

1. Terraform starts creating resources in order of dependencies
2. You'll see real-time progress updates
3. Some resources (like AKS) take several minutes
4. Total time: 15-25 minutes

**Progress output (example):**

```
module.naming.random_string.unique: Creating...
module.naming.random_string.unique: Creation complete after 0s [id=a1b2]

azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s

module.networking.azurerm_virtual_network.main: Creating...
module.networking.azurerm_virtual_network.main: Creation complete after 8s

module.aks.azurerm_kubernetes_cluster.main: Creating...
module.aks.azurerm_kubernetes_cluster.main: Still creating... [1m0s elapsed]
module.aks.azurerm_kubernetes_cluster.main: Still creating... [2m0s elapsed]
module.aks.azurerm_kubernetes_cluster.main: Still creating... [3m0s elapsed]
module.aks.azurerm_kubernetes_cluster.main: Still creating... [4m0s elapsed]
module.aks.azurerm_kubernetes_cluster.main: Still creating... [5m0s elapsed]
module.aks.azurerm_kubernetes_cluster.main: Creation complete after 6m32s

...

Apply complete! Resources: 32 added, 0 changed, 0 destroyed.
```

> ⏳ **AKS cluster creation takes 5-10 minutes**
>
> This is normal. Azure is provisioning virtual machines and setting up Kubernetes.
> Do not interrupt the process!

### 4.3 Save the Outputs

After successful deployment, Terraform outputs important information:

```bash
# Create outputs directory if it doesn't exist
mkdir -p ../outputs

# Save all outputs to JSON file
terraform output -json > ../outputs/h1-outputs.json

# Display the outputs
terraform output
```

**Expected outputs:**

```
Outputs:

aks_cluster_name     = "aks-threehorizons-dev"
aks_cluster_id       = "/subscriptions/.../managedClusters/aks-threehorizons-dev"
acr_login_server     = "acrthreehorizonsdev.azurecr.io"
key_vault_name       = "kv-threehorizons-dev"
key_vault_uri        = "https://kv-threehorizons-dev.vault.azure.net/"
resource_group_name  = "rg-threehorizons-dev"
vnet_id              = "/subscriptions/.../virtualNetworks/vnet-threehorizons-dev"
```

**Save these values!** You'll need them for verification and debugging.

> ✅ **Checkpoint:**
>
> If you see "Apply complete!" with no errors, H1 Foundation is deployed!
> Proceed to Step 5 to verify everything works.

> ⚠️ **If apply fails:**
>
> Don't panic! Check the error message and refer to the Troubleshooting section.
> Common issues:
>
> - Quota limits exceeded → Request quota increase in Azure Portal
> - Permission denied → Verify Service Principal has correct roles
> - Name already exists → Change project_name in Terraform.tfvars

---

## Step 5: Verify H1 Foundation

**⏱️ Time Required:** 15 minutes

Before proceeding to H2, let's verify that H1 is working correctly.

### 5.1 Connect to AKS Cluster

> 💡 **What is kubeconfig?**
>
> kubectl needs credentials to talk to your Kubernetes cluster. The `az aks get-credentials`
> command downloads these credentials and saves them to `~/.kube/config`.

```bash
# Get AKS credentials (downloads kubeconfig)
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing
```

**Expected output:**

```
Merged "aks-threehorizons-dev" as current context in /Users/you/.kube/config
```

**Verify connection to cluster:**

```bash
kubectl cluster-info
```

**Expected output:**

```
Kubernetes control plane is running at https://aks-threehorizons-dev-abc123.hcp.brazilsouth.azmk8s.io:443
CoreDNS is running at https://aks-threehorizons-dev-abc123.hcp.brazilsouth.azmk8s.io:443/api/v1/...

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

> ⚠️ **If connection fails:**
>
> - "Unable to connect to the server" → Check your internet connection
> - "Unauthorized" → Run `az login` again, then retry `az aks get-credentials`
> - Timeout → If using private cluster, you need to be on the VNet or use Azure Bastion

### 5.2 Verify Cluster Nodes

```bash
# List all nodes in the cluster
kubectl get nodes -o wide
```

**Expected output:**

```
NAME                                STATUS   ROLES   AGE   VERSION   INTERNAL-IP   OS-IMAGE
aks-system-12345678-vmss000000      Ready    agent   10m   v1.29.0   10.0.0.4      Ubuntu 22.04.3 LTS
aks-system-12345678-vmss000001      Ready    agent   10m   v1.29.0   10.0.0.5      Ubuntu 22.04.3 LTS
aks-system-12345678-vmss000002      Ready    agent   10m   v1.29.0   10.0.0.6      Ubuntu 22.04.3 LTS
```

**What to check:**

- All nodes show `STATUS: Ready`
- Node count matches your sizing profile (small = 3 nodes)
- VERSION shows Kubernetes version (1.28+)

### 5.3 Verify Core Kubernetes Components

```bash
# Check pods in kube-system namespace
kubectl get pods -n kube-system
```

**Expected output (all should be Running):**

```
NAME                                  READY   STATUS    RESTARTS   AGE
azure-ip-masq-agent-xxxxx             1/1     Running   0          15m
cloud-node-manager-xxxxx              1/1     Running   0          15m
coredns-xxxxxxxxx-xxxxx               1/1     Running   0          15m
coredns-autoscaler-xxxxxxxxx-xxxxx    1/1     Running   0          15m
csi-azuredisk-node-xxxxx              3/3     Running   0          15m
csi-azurefile-node-xxxxx              3/3     Running   0          15m
konnectivity-agent-xxxxxxxxx-xxxxx    1/1     Running   0          15m
kube-proxy-xxxxx                      1/1     Running   0          15m
metrics-server-xxxxxxxxx-xxxxx        2/2     Running   0          15m
```

**All pods should show STATUS: Running with no restarts.**

### 5.4 Verify Azure Resources

Let's check that all Azure resources were created:

```bash
# List all resources in the resource group
az resource list \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table
```

**Expected resources:**

| Name | Type | Purpose |
|------|------|---------|
| aks-threehorizons-dev | Microsoft.ContainerService/managedClusters | Kubernetes cluster |
| acrthreehorizonsdev | Microsoft.ContainerRegistry/registries | Container images |
| kv-threehorizons-dev | Microsoft.KeyVault/vaults | Secrets storage |
| vnet-threehorizons-dev | Microsoft.Network/virtualNetworks | Network |
| nsg-aks-* | Microsoft.Network/networkSecurityGroups | Firewall rules |
| id-threehorizons-* | Microsoft.ManagedIdentity/userAssignedIdentities | Identities |

### 5.5 Test Container Registry Access

```bash
# Login to ACR
az acr login --name $(terraform output -raw acr_login_server | cut -d'.' -f1)
```

**Expected output:**

```
Login Succeeded
```

**Verify repository list (should be empty):**

```bash
az acr repository list --name $(terraform output -raw acr_login_server | cut -d'.' -f1) --output table
```

**Expected output:**

```
Result
--------
```

(Empty because we haven't pushed any images yet)

### 5.6 H1 Verification Checklist

Use this checklist to confirm everything works:

```
H1 FOUNDATION VERIFICATION CHECKLIST
====================================

Kubernetes Cluster:
[ ] kubectl cluster-info shows control plane URL
[ ] kubectl get nodes shows all nodes as Ready
[ ] All kube-system pods are Running

Azure Resources:
[ ] AKS cluster is created
[ ] Container Registry is accessible
[ ] Key Vault is created
[ ] Virtual Network and subnets exist
[ ] Network Security Groups are applied
[ ] Managed Identities are created

Quick Tests:
[ ] az acr login succeeds
[ ] kubectl run test --image=nginx --restart=Never succeeds
[ ] kubectl delete pod test succeeds
```

**Run a quick pod test:**

```bash
# Create a test pod
kubectl run test-pod --image=nginx --restart=Never

# Wait for it to be ready
kubectl wait --for=condition=Ready pod/test-pod --timeout=60s

# Check it's running
kubectl get pod test-pod

# Clean up
kubectl delete pod test-pod
```

> ✅ **If all checks pass, proceed to Step 6!**

---

## Step 6: Deploy H2 Enhancement Layer

**⏱️ Time Required:** 30 minutes
**📁 Related Files:** `argocd/`, `terraform/modules/observability/`

In this step, we'll deploy:

- ArgoCD (GitOps continuous deployment)
- External Secrets Operator (syncs secrets from Key Vault)
- Prometheus + Grafana (monitoring and dashboards)
- Gatekeeper (policy enforcement)

### 6.1 Create Required Namespaces

> 💡 **What are Kubernetes Namespaces?**
>
> Namespaces are like folders in Kubernetes. They help organize and isolate resources.
> Each H2 component gets its own namespace.

```bash
# Create namespaces for H2 components
kubectl create namespace argocd
kubectl create namespace observability
kubectl create namespace external-secrets
kubectl create namespace gatekeeper-system

# Verify namespaces were created
kubectl get namespaces | grep -E "argocd|observability|external-secrets|gatekeeper"
```

**Expected output:**

```
argocd              Active   5s
external-secrets    Active   5s
gatekeeper-system   Active   5s
observability       Active   5s
```

### 6.2 Deploy ArgoCD

> 💡 **What is ArgoCD?**
>
> ArgoCD is a GitOps tool that automatically syncs Kubernetes resources from Git.
> When you push changes to Git, ArgoCD applies them to the cluster automatically.

**Step 1: Install ArgoCD**

```bash
# Install ArgoCD using the official manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Expected output:**

```
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created
serviceaccount/argocd-application-controller created
serviceaccount/argocd-dex-server created
serviceaccount/argocd-redis created
serviceaccount/argocd-server created
...
deployment.apps/argocd-server created
```

**Step 2: Wait for ArgoCD to be ready**

```bash
# Wait for the argocd-server deployment to be available
echo "Waiting for ArgoCD to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

**Expected output:**

```
deployment.apps/argocd-server condition met
```

**Step 3: Get the initial admin password**

```bash
# ArgoCD generates a random admin password
# This command retrieves it
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "======================================="
echo "ArgoCD Admin Credentials"
echo "======================================="
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo "======================================="
echo ""
echo "Save this password! You'll need it to access the ArgoCD UI."
```

> 🔒 **Save this password!**
>
> Store it in your password manager. You'll need it to access ArgoCD.

### 6.3 Deploy External Secrets Operator

> 💡 **What is External Secrets Operator?**
>
> ESO syncs secrets from external sources (like Azure Key Vault) into Kubernetes Secrets.
> Your applications get secrets automatically, and they're always up to date.

**Step 1: Add Helm repository**

```bash
# Add the External Secrets Helm repository
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

**Step 2: Install External Secrets Operator**

```bash
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --set installCRDs=true \
  --wait
```

**Expected output:**

```
NAME: external-secrets
NAMESPACE: external-secrets
STATUS: deployed
REVISION: 1
...
```

**Step 3: Verify installation**

```bash
kubectl get pods -n external-secrets
```

**Expected output:**

```
NAME                                                READY   STATUS    RESTARTS   AGE
external-secrets-xxxxxxxxx-xxxxx                    1/1     Running   0          30s
external-secrets-cert-controller-xxxxxxxxx-xxxxx    1/1     Running   0          30s
external-secrets-webhook-xxxxxxxxx-xxxxx            1/1     Running   0          30s
```

### 6.4 Configure ClusterSecretStore

> 💡 **What is a ClusterSecretStore?**
>
> It tells External Secrets where to get secrets from. We're configuring it to use
> Azure Key Vault with Workload Identity (passwordless authentication).

```bash
# Get Key Vault name and tenant ID from Terraform outputs
cd terraform
KV_NAME=$(terraform output -raw key_vault_name)
TENANT_ID=$(az account show --query tenantId -o tsv)
cd ..

echo "Key Vault Name: $KV_NAME"
echo "Tenant ID: $TENANT_ID"

# Create the ClusterSecretStore
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: azure-key-vault
spec:
  provider:
    azurekv:
      authType: WorkloadIdentity
      vaultUrl: "https://${KV_NAME}.vault.azure.net"
      serviceAccountRef:
        name: external-secrets
        namespace: external-secrets
EOF
```

**Expected output:**

```
clustersecretstore.external-secrets.io/azure-key-vault created
```

**Verify the ClusterSecretStore:**

```bash
kubectl get clustersecretstore
```

**Expected output:**

```
NAME              AGE   STATUS   CAPABILITIES   READY
azure-key-vault   10s   Valid    ReadWrite      True
```

### 6.5 Deploy Observability Stack (Prometheus + Grafana)

> 💡 **What is kube-prometheus-stack?**
>
> It's a complete monitoring solution that includes:
>
> - **Prometheus:** Collects and stores metrics
> - **Grafana:** Visualizes metrics in dashboards
> - **Alertmanager:** Sends alerts when things go wrong

**Step 1: Add Helm repository**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

**Step 2: Install kube-prometheus-stack**

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n observability \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.retention=7d \
  --wait \
  --timeout 10m
```

> ⏳ **This may take 3-5 minutes**
>
> The Prometheus stack includes many components. Wait for it to complete.

**Step 3: Verify installation**

```bash
kubectl get pods -n observability
```

**Expected output (all should be Running):**

```
NAME                                                   READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0 2/2     Running   0          2m
prometheus-grafana-xxxxxxxxx-xxxxx                     3/3     Running   0          2m
prometheus-kube-prometheus-operator-xxxxxxxxx-xxxxx    1/1     Running   0          2m
prometheus-kube-state-metrics-xxxxxxxxx-xxxxx          1/1     Running   0          2m
prometheus-prometheus-kube-prometheus-prometheus-0     2/2     Running   0          2m
prometheus-prometheus-node-exporter-xxxxx              1/1     Running   0          2m
```

### 6.6 Deploy Gatekeeper (Policy Enforcement)

> 💡 **What is Gatekeeper?**
>
> Gatekeeper enforces policies on Kubernetes resources. For example, it can:
>
> - Block containers running as root
> - Require all pods to have resource limits
> - Enforce naming conventions

**Step 1: Add Helm repository**

```bash
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update
```

**Step 2: Install Gatekeeper**

```bash
helm install gatekeeper gatekeeper/gatekeeper \
  -n gatekeeper-system \
  --set replicas=2 \
  --wait
```

**Step 3: Verify installation**

```bash
kubectl get pods -n gatekeeper-system
```

**Expected output:**

```
NAME                                            READY   STATUS    RESTARTS   AGE
gatekeeper-audit-xxxxxxxxx-xxxxx                1/1     Running   0          30s
gatekeeper-controller-manager-xxxxxxxxx-xxxxx   1/1     Running   0          30s
gatekeeper-controller-manager-xxxxxxxxx-yyyyy   1/1     Running   0          30s
```

> ✅ **H2 Enhancement deployment complete!**
>
> Proceed to Step 7 to verify everything works.

---

## Step 7: Verify H2 Enhancement

**⏱️ Time Required:** 15 minutes

### 7.1 Access ArgoCD UI

```bash
# Port forward ArgoCD server to localhost
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

echo ""
echo "ArgoCD is available at: https://localhost:8080"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo ""
echo "Note: You may see a certificate warning - this is normal for local access."
```

**Open your browser and go to:** <https://localhost:8080>

1. Accept the certificate warning
2. Log in with username `admin` and the password from Step 6.2
3. You should see the ArgoCD dashboard

### 7.2 Access Grafana Dashboards

```bash
# Get Grafana password (we set it to admin123 during install)
GRAFANA_PASSWORD="admin123"

# Port forward Grafana to localhost
kubectl port-forward svc/prometheus-grafana -n observability 3000:80 &

echo ""
echo "Grafana is available at: http://localhost:3000"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
```

**Open your browser and go to:** <http://localhost:3000>

1. Log in with username `admin` and password `admin123`
2. Navigate to Dashboards → Browse
3. You should see pre-installed Kubernetes dashboards

### 7.3 Test External Secrets

Let's verify that External Secrets can sync secrets from Key Vault.

**Step 1: Create a test secret in Key Vault**

```bash
# Create a test secret
az keyvault secret set \
  --vault-name $(cd terraform && terraform output -raw key_vault_name) \
  --name test-secret \
  --value "hello-from-keyvault"
```

**Step 2: Create an ExternalSecret to sync it**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: test-external-secret
  namespace: default
spec:
  refreshInterval: 1m
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-key-vault
  target:
    name: test-k8s-secret
  data:
    - secretKey: my-value
      remoteRef:
        key: test-secret
EOF
```

**Step 3: Wait for sync and verify**

```bash
# Wait for the secret to sync (up to 1 minute)
sleep 10

# Check if the Kubernetes secret was created
kubectl get secret test-k8s-secret

# Decode and display the secret value
kubectl get secret test-k8s-secret -o jsonpath='{.data.my-value}' | base64 -d
```

**Expected output:**

```
hello-from-keyvault
```

**Step 4: Clean up test resources**

```bash
kubectl delete externalsecret test-external-secret
kubectl delete secret test-k8s-secret
az keyvault secret delete --vault-name $(cd terraform && terraform output -raw key_vault_name) --name test-secret
```

### 7.4 Verify Gatekeeper Policies

Let's test that Gatekeeper is enforcing policies.

```bash
# Try to create a privileged pod (this should be blocked)
cat <<EOF | kubectl apply -f - 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged
spec:
  containers:
  - name: test
    image: nginx
    securityContext:
      privileged: true
EOF
```

**Expected output (may vary based on installed policies):**

```
Error from server (Forbidden): error when creating "STDIN": admission webhook "validation.gatekeeper.sh" denied the request: ...
```

> 💡 **If the pod was created:**
>
> Gatekeeper is installed but no constraint policies are active yet.
> This is normal - you can add policies later from the `policies/` directory.

### 7.5 H2 Verification Checklist

```
H2 ENHANCEMENT VERIFICATION CHECKLIST
=====================================

ArgoCD:
[ ] ArgoCD UI accessible at https://localhost:8080
[ ] Can login with admin credentials
[ ] Dashboard loads without errors

Observability:
[ ] Grafana UI accessible at http://localhost:3000
[ ] Can login with admin credentials
[ ] Kubernetes dashboards show data

External Secrets:
[ ] ClusterSecretStore shows Ready=True
[ ] Test secret synced from Key Vault successfully

Gatekeeper:
[ ] All gatekeeper pods are Running
[ ] Audit and controller pods are healthy
```

> ✅ **If all checks pass, H2 is complete!**
>
> You can skip to Step 9 if you don't need H3 (AI Foundry).

---

## Step 8: Deploy H3 Innovation Layer (Optional)

**⏱️ Time Required:** 30 minutes
**📁 Related Files:** `terraform/modules/ai-foundry/`

> ⚠️ **Prerequisites for H3:**
>
> - Azure OpenAI access must be approved (request at <https://aka.ms/oai/access>)
> - H1 and H2 must be successfully deployed and verified

### 8.1 Enable H3 in Configuration

```bash
cd terraform

# Update terraform.tfvars to enable H3
# Replace enable_h3 = false with enable_h3 = true
sed -i.bak 's/enable_h3 = false/enable_h3 = true/' terraform.tfvars

# Verify the change
grep enable_h3 terraform.tfvars
```

**Expected output:**

```
enable_h3 = true
```

### 8.2 Plan H3 Deployment

```bash
# Generate the plan for H3 resources
terraform plan -out=h3-innovation.tfplan
```

**Expected new resources:**

```
Plan: 8 to add, 0 to change, 0 to destroy.

  # module.ai_foundry.azurerm_cognitive_account.main will be created
  + resource "azurerm_cognitive_account" "main" {
      + name                = "oai-threehorizons-dev"
      + kind                = "OpenAI"
      ...
    }

  # module.ai_foundry.azurerm_cognitive_deployment.gpt4o will be created
  ...
```

### 8.3 Apply H3 Deployment

```bash
terraform apply h3-innovation.tfplan
```

**Wait for deployment (5-10 minutes).**

### 8.4 Verify AI Foundry

```bash
# Get AI Foundry details
cd terraform
AI_NAME=$(terraform output -raw ai_foundry_name 2>/dev/null || echo "Not found")
RG_NAME=$(terraform output -raw resource_group_name)
cd ..

echo "AI Foundry Account: $AI_NAME"
echo "Resource Group: $RG_NAME"

# List model deployments
az cognitiveservices account deployment list \
  --name "$AI_NAME" \
  --resource-group "$RG_NAME" \
  --output table
```

**Expected output:**

```
Name             Model        Version   Capacity   ProvisioningState
---------------  -----------  --------  ---------  ------------------
gpt-4o           gpt-4o       2024-05   10         Succeeded
gpt-4o-mini      gpt-4o-mini  2024-07   20         Succeeded
text-embedding   text-embed   3-large   50         Succeeded
```

### 8.5 Test AI Endpoint

```bash
# Get endpoint and key
cd terraform
AI_ENDPOINT=$(az cognitiveservices account show \
  --name $(terraform output -raw ai_foundry_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "properties.endpoint" -o tsv)

AI_KEY=$(az cognitiveservices account keys list \
  --name $(terraform output -raw ai_foundry_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "key1" -o tsv)
cd ..

# Test API call
curl -s -X POST "${AI_ENDPOINT}openai/deployments/gpt-4o-mini/chat/completions?api-version=2024-02-15-preview" \
  -H "Content-Type: application/json" \
  -H "api-key: ${AI_KEY}" \
  -d '{
    "messages": [{"role": "user", "content": "Say hello!"}],
    "max_tokens": 50
  }' | jq '.choices[0].message.content'
```

**Expected output:**

```
"Hello! How can I assist you today?"
```

> ✅ **H3 Innovation is deployed and working!**

---

## Step 9: Final Platform Verification

**⏱️ Time Required:** 15 minutes

### 9.1 Platform Health Dashboard

Run this command to see overall platform status:

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           OPEN HORIZONS PLATFORM - STATUS DASHBOARD             ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

echo "─── H1: FOUNDATION ───────────────────────────────────────────────"
echo ""
echo "Kubernetes Nodes:"
kubectl get nodes -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[-1].type,VERSION:.status.nodeInfo.kubeletVersion'
echo ""

echo "─── H2: ENHANCEMENT ──────────────────────────────────────────────"
echo ""
echo "ArgoCD Applications:"
kubectl get applications -n argocd 2>/dev/null || echo "(No applications deployed yet)"
echo ""
echo "Observability Pods:"
kubectl get pods -n observability --no-headers | wc -l | xargs echo "Running pods:"
echo ""

echo "─── NAMESPACE SUMMARY ────────────────────────────────────────────"
echo ""
kubectl get namespaces --no-headers | wc -l | xargs echo "Total namespaces:"
echo ""

echo "─── RESOURCE SUMMARY ─────────────────────────────────────────────"
echo ""
echo "Pods by namespace (top 5):"
kubectl get pods -A --no-headers | awk '{print $1}' | sort | uniq -c | sort -rn | head -5
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "Platform verification complete!"
echo "═══════════════════════════════════════════════════════════════════"
```

### 9.2 Access URLs Summary

| Service | URL | Credentials |
|---------|-----|-------------|
| ArgoCD | <https://localhost:8080> | admin / (saved password) |
| Grafana | <http://localhost:3000> | admin / admin123 |
| Prometheus | <http://localhost:9090> | (no auth) |

**To access these services:**

```bash
# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Grafana
kubectl port-forward svc/prometheus-grafana -n observability 3000:80 &

# Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090 &
```

### 9.3 Final Checklist

```
COMPLETE PLATFORM VERIFICATION
==============================

H1 Foundation:
[ ] AKS cluster running with expected node count
[ ] All nodes in Ready status
[ ] Container Registry accessible
[ ] Key Vault created
[ ] Network properly configured

H2 Enhancement:
[ ] ArgoCD installed and accessible
[ ] External Secrets syncing from Key Vault
[ ] Prometheus collecting metrics
[ ] Grafana dashboards loading
[ ] Gatekeeper enforcing policies

H3 Innovation (if enabled):
[ ] AI Foundry account created
[ ] Model deployments succeeded
[ ] API calls returning responses

Overall:
[ ] All pods in Running state (no CrashLoopBackOff)
[ ] No persistent errors in events
[ ] Platform dashboard shows healthy status
```

> 🎉 **Congratulations!**
>
> You have successfully deployed the Open Horizons Platform!

---

## Step 10: Post-Deployment Configuration

Now that the platform is running, here are some recommended next steps.

> **Hand off to the wizard.** Once the platform is up, every new repository created by developers goes through the Backstage wizard. The wizard exposes a `Provision Azure Infrastructure` toggle so each Golden Path can opt into the Azure baseline (Bicep + OIDC workflow). Read [WIZARD_GUIDE.md](WIZARD_GUIDE.md) before onboarding developers.

### 10.1 Configure DNS (Production)

For production, configure proper DNS instead of port-forwarding:

```bash
# Example: Create DNS record for ArgoCD
# (Requires a public IP on your cluster ingress)

# Get the external IP
EXTERNAL_IP=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Configure in your DNS provider:
# argocd.your-domain.com -> $EXTERNAL_IP
```

### 10.2 Configure Backup (Production)

```bash
# Install Velero for backups
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero \
  -n velero --create-namespace \
  --set configuration.provider=azure \
  --set configuration.backupStorageLocation.bucket=backups

# Create daily backup schedule
velero schedule create daily-backup --schedule="0 2 * * *"
```

### 10.3 Change Default Passwords

For production, change all default passwords:

```bash
# ArgoCD: Change admin password
argocd account update-password --current-password "$ARGOCD_PASSWORD" --new-password "NewSecurePassword123!"

# Grafana: Change via UI (admin settings)
```

### 10.4 Document Your Deployment

Create a document with your deployment details:

```markdown
# Platform Access Information

## Deployed: [DATE]

## Azure Resources
- Subscription: [YOUR_SUBSCRIPTION_ID]
- Resource Group: [YOUR_RG_NAME]
- AKS Cluster: [YOUR_AKS_NAME]

## Access URLs
- ArgoCD: https://argocd.your-domain.com
- Grafana: https://grafana.your-domain.com

## Credentials Location
- ArgoCD: [Password Manager Entry]
- Grafana: [Password Manager Entry]
- Azure Credentials: [Secure Storage Location]

## Contacts
- Platform Owner: [EMAIL]
- Escalation: [EMAIL]
```

---

## Troubleshooting Common Issues

### Issue: "Insufficient privileges" during Service Principal creation

**Cause:** Your Azure account doesn't have permission to create applications.

**Solution:**

1. Ask your Azure AD administrator for "Application Administrator" role
2. Or ask them to create the Service Principal for you

### Issue: "Resource provider is not registered"

**Cause:** The provider wasn't registered in Step 1.2.

**Solution:**

```bash
az provider register --namespace Microsoft.ContainerService --wait
```

### Issue: "Quota exceeded" during AKS creation

**Cause:** Your subscription doesn't have enough VM quota.

**Solution:**

1. Go to Azure Portal → Subscriptions → Usage + quotas
2. Request a quota increase for the VM family you're using

### Issue: "Name already exists" during Terraform apply

**Cause:** Resource names must be globally unique in Azure.

**Solution:**

1. Change `project_name` in Terraform.tfvars to something unique
2. Run `terraform plan` and `terraform apply` again

### Issue: kubectl commands timeout

**Cause:** Can't reach the Kubernetes API server.

**Solution:**

1. Verify your internet connection
2. Run `az aks get-credentials` again
3. If using private cluster, connect through VNet or Bastion

### Issue: Pods stuck in "Pending" state

**Cause:** Not enough node resources.

**Solution:**

```bash
# Check what's happening
kubectl describe pod <pod-name>

# If resource issue, scale up nodes
az aks scale --resource-group <rg> --name <aks> --node-count 5
```

### Issue: External Secrets not syncing

**Cause:** Workload Identity not configured correctly.

**Solution:**

```bash
# Check ClusterSecretStore status
kubectl describe clustersecretstore azure-key-vault

# Check External Secret status
kubectl describe externalsecret <name>

# Verify Key Vault permissions
az keyvault show --name <kv-name> --query "properties.accessPolicies"
```

---

## Appendix A: File Reference

### Directory Structure

![Repository Structure](../assets/mod-directory-structure.svg)

---

## Appendix B: Environment Variables Reference

### Required for Terraform

| Variable | Description | Where to Get It |
|----------|-------------|-----------------|
| ARM_CLIENT_ID | Service Principal Client ID | Azure-credentials.json |
| ARM_CLIENT_SECRET | Service Principal Secret | Azure-credentials.json |
| ARM_SUBSCRIPTION_ID | Azure Subscription ID | Azure-credentials.json |
| ARM_TENANT_ID | Azure Tenant ID | Azure-credentials.json |

### Optional Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| PROJECT_NAME | threehorizons | Used in all resource names |
| ENVIRONMENT | dev | Environment (dev/staging/prod) |
| Azure_LOCATION | brazilsouth | Azure region |
| SIZING_PROFILE | small | Resource sizing (small/medium/large) |

---

## Appendix C: Rollback Procedures

### Rollback H3 Only

```bash
cd terraform
terraform destroy -target=module.ai_foundry -auto-approve
sed -i 's/enable_h3 = true/enable_h3 = false/' terraform.tfvars
```

### Rollback H2 Only

```bash
# Remove H2 namespaces
kubectl delete namespace argocd observability external-secrets gatekeeper-system

# Update configuration
cd terraform
sed -i 's/enable_h2 = true/enable_h2 = false/' terraform.tfvars
terraform apply
```

### Complete Rollback (Destroy Everything)

> ⚠️ **WARNING: This deletes ALL resources!**

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm. This will:

- Delete all Azure resources
- Remove the AKS cluster
- Delete the resource group
- Remove all data

---

## Getting Help

### 🤖 Copilot Agents for Deployment

The platform includes AI agents that can assist you at every deployment step:

| Step | Agent | Example Prompt |
|------|-------|---------------|
| First-time setup | `@onboarding` | "Help me set up prerequisites and create my first `.tfvars`" |
| Terraform configuration | `@terraform` | "Validate my `dev.tfvars` against the AKS module variables" |
| Terraform troubleshooting | `@terraform` | "My `terraform plan` shows unexpected changes, help me understand" |
| ArgoCD setup & sync | `@devops` | "ArgoCD app is OutOfSync, help me debug" |
| Backstage portal setup | `@platform` | "Help me register Golden Path templates in the catalog" |
| Security validation | `@security` | "Review my Terraform plan for security misconfigurations" |
| Post-deploy verification | `@sre` | "Verify all pods are healthy after H1 deployment" |
| Architecture questions | `@architect` | "Explain the networking design between H1 and H2" |

> **Tip:** Each agent will decompose your request into sub-tasks and walk you through step by step.

- **GitHub Issues:** [Create an Issue](https://github.com/Ohorizons/agentic-devops-platform/issues)
- **Documentation:** Check other guides in `/docs/guides/`

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [Architecture Guide](./ARCHITECTURE_GUIDE.md) | System design, component topology, and infrastructure patterns |
| [Administrator Guide](./ADMINISTRATOR_GUIDE.md) | Day-2 operations, monitoring, scaling, and maintenance |
| [Troubleshooting Guide](./TROUBLESHOOTING_GUIDE.md) | Diagnostic workflows for common issues |
| [Module Reference](./MODULE_REFERENCE.md) | Detailed inputs/outputs for all Terraform modules |
| [Performance Tuning Guide](./PERFORMANCE_TUNING_GUIDE.md) | Optimization recommendations for all components |

## Next Steps

- **Configure monitoring**: Set up Grafana dashboards and alerting rules — see [Administrator Guide](./ADMINISTRATOR_GUIDE.md)
- **Review security posture**: Validate security baseline — see [Architecture Guide](./ARCHITECTURE_GUIDE.md)
- **Set up observability**: Deploy Prometheus, Grafana, and Loki — see [Module Reference](./MODULE_REFERENCE.md)
- **Review runbooks**: Familiarize with operational procedures — see [Runbooks](../runbooks/README.md)

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
