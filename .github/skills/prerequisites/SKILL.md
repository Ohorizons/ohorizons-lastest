---
name: prerequisites
description: "CLI tool prerequisites validation and setup. USE FOR: validate prerequisites, check CLI tools, install missing tools, verify versions, prerequisite checklist. DO NOT USE FOR: deployment orchestration (use deploy-orchestration), Terraform operations (use terraform-cli), Kubernetes operations (use kubectl-cli)."
---

## When to Use
- Before any deployment workflow
- Environment setup validation
- CI/CD pipeline prerequisite checks

## Prerequisites
- Bash shell
- Access to download tools if missing

## Required CLI Tools

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| az | 2.50.0 | Azure CLI |
| terraform | 1.5.0 | Infrastructure as Code |
| kubectl | 1.28.0 | Kubernetes CLI |
| helm | 3.12.0 | Kubernetes package manager |
| gh | 2.30.0 | GitHub CLI |
| argocd | 2.8.0 | ArgoCD CLI |
| jq | 1.6 | JSON processor |
| yq | 4.0.0 | YAML processor |

## Validation Script

```bash
#!/bin/bash
set -euo pipefail

# Check required tools
TOOLS=("az" "terraform" "kubectl" "helm" "gh" "argocd" "jq" "yq")
MISSING=()

for tool in "${TOOLS[@]}"; do
  if ! command -v "$tool" &> /dev/null; then
    MISSING+=("$tool")
  fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
  echo "Missing tools: ${MISSING[*]}"
  exit 1
fi

echo "All prerequisites satisfied"
```

## Installation Commands

### macOS (Homebrew)
```bash
brew install azure-cli terraform kubectl helm gh argocd jq yq
```

### Ubuntu/Debian
```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Best Practices
1. Run prerequisite check before every deployment
2. Pin tool versions in CI/CD
3. Document version requirements
4. Use version managers (asdf, mise)
5. Include prerequisite check in pre-commit hooks

## Output Format
1. Tools checked
2. Versions found
3. Missing tools
4. Installation instructions

## Integration with Agents
Used by: All agents (prerequisite validation)
