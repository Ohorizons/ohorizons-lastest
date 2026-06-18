#!/bin/bash
# =============================================================================
# validate-substitutions.sh — Check for unresolved template variables
# =============================================================================
# Scans configuration files for unresolved ${VAR} placeholders that should
# have been substituted before deployment.
#
# Usage: ./scripts/validate-substitutions.sh [--fix] [--verbose]
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ERRORS=0; WARNINGS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

VERBOSE=false
FIX_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose|-v) VERBOSE=true; shift ;;
    --fix)        FIX_MODE=true; shift ;;
    --help|-h)
      echo "Usage: $0 [--verbose] [--fix]"
      echo "  --verbose  Show all unresolved variables with file locations"
      echo "  --fix      Show commands to set missing environment variables"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
pass()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn()   { echo -e "  ${YELLOW}!${NC} $1"; WARNINGS=$((WARNINGS + 1)); }

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       OPEN HORIZONS — Variable Substitution Validation     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# Files to check for unresolved variables.
# Keep as parallel arrays for compatibility with macOS Bash 3.2.
FILE_GROUP_NAMES=(
  "Helm ArgoCD"
  "Helm Monitoring"
  "ArgoCD Root App"
  "ArgoCD Repo Creds"
  "ArgoCD Secret Store"
  "Prometheus Alerting"
  "K8s Constraints"
)

FILE_GROUP_PATHS=(
  "deploy/helm/argocd/values.yaml"
  "deploy/helm/monitoring/values.yaml"
  "argocd/app-of-apps/root-application.yaml"
  "argocd/repo-credentials.yaml"
  "argocd/secrets/cluster-secret-store.yaml"
  "prometheus/alerting-rules.yaml"
  "policies/kubernetes/constraints/platform-constraints.yaml"
)

# Known variables and their descriptions.
KNOWN_VAR_NAMES=(
  "DNS_ZONE_NAME"
  "GITHUB_ORG"
  "CUSTOMER_NAME"
  "CUSTOMER_FULL_NAME"
  "CUSTOMER_DOMAIN"
  "AZURE_TENANT_ID"
  "AZURE_SUBSCRIPTION_ID"
  "GRAFANA_ADMIN_PASSWORD"
  "GRAFANA_CLIENT_ID"
  "GRAFANA_CLIENT_SECRET"
  "GRAFANA_TOKEN"
  "PAGERDUTY_SERVICE_KEY"
  "TEAMS_WEBHOOK_URL"
  "GITHUB_APP_ID"
  "GITHUB_APP_CLIENT_ID"
  "GITHUB_APP_CLIENT_SECRET"
  "GITHUB_APP_PRIVATE_KEY"
  "GITHUB_PAT"
  "GITHUB_WEBHOOK_SECRET"
  "SSH_PRIVATE_KEY"
  "AZURE_DEVOPS_PAT"
  "ACR_NAME"
  "ACR_USERNAME"
  "ACR_PASSWORD"
  "KEY_VAULT_URL"
  "KEY_VAULT_NAME"
  "CLUSTER_NAME"
  "ENVIRONMENT"
  "BACKSTAGE_MANAGED_IDENTITY_CLIENT_ID"
  "POSTGRESQL_HOST"
  "POSTGRESQL_USER"
  "POSTGRESQL_PASSWORD"
  "ARGOCD_AUTH_TOKEN"
  "ARGOCD_ADMIN_PASSWORD"
  "STORAGE_ACCOUNT_NAME"
  "STORAGE_ACCOUNT_KEY"
  "K8S_SERVICE_ACCOUNT_TOKEN"
  "DNS_ZONE_RESOURCE_GROUP"
  "EXTERNAL_DNS_CLIENT_ID"
  "RUNBOOK_BASE_URL"
)

KNOWN_VAR_DESCRIPTIONS=(
  "Base DNS zone (e.g., platform.contoso.com)"
  "GitHub organization name"
  "Customer name for resource naming"
  "Full customer display name"
  "Customer email domain"
  "Azure AD tenant ID"
  "Azure subscription ID"
  "Grafana admin password"
  "Grafana Azure AD app client ID"
  "Grafana Azure AD app client secret"
  "Grafana API token"
  "PagerDuty integration key"
  "Microsoft Teams webhook URL"
  "GitHub App ID"
  "GitHub App client ID"
  "GitHub App client secret"
  "GitHub App private key (PEM)"
  "GitHub personal access token"
  "GitHub webhook secret"
  "SSH private key for Git"
  "Azure DevOps PAT"
  "Azure Container Registry name"
  "ACR username"
  "ACR password"
  "Azure Key Vault URL"
  "Azure Key Vault name"
  "AKS cluster name"
  "Environment name (dev/staging/prod)"
  "Backstage managed identity client ID"
  "PostgreSQL server hostname"
  "PostgreSQL admin username"
  "PostgreSQL admin password"
  "ArgoCD authentication token"
  "ArgoCD admin password"
  "Azure Storage account name"
  "Azure Storage account key"
  "Kubernetes service account token"
  "Resource group containing DNS zone"
  "External DNS managed identity client ID"
  "Base URL for operational runbooks"
)

known_var_description() {
  local name="$1"
  local index
  for index in "${!KNOWN_VAR_NAMES[@]}"; do
    if [[ "${KNOWN_VAR_NAMES[$index]}" == "$name" ]]; then
      echo "${KNOWN_VAR_DESCRIPTIONS[$index]}"
      return 0
    fi
  done
  echo "Unknown variable"
}

ALL_UNRESOLVED=()

header "Scanning Configuration Files"

for index in "${!FILE_GROUP_NAMES[@]}"; do
  group_name="${FILE_GROUP_NAMES[$index]}"
  group_path="${FILE_GROUP_PATHS[$index]}"
  file="${PROJECT_ROOT}/${group_path}"
  
  if [[ ! -f "$file" ]]; then
    warn "$group_name: File not found (${group_path})"
    continue
  fi
  
  # Find unresolved ${VAR} patterns (exclude Helm {{ }} patterns)
  unresolved=$(grep -oE '\$\{[A-Z_]+\}' "$file" 2>/dev/null | sort -u || true)
  
  if [[ -z "$unresolved" ]]; then
    pass "$group_name: All variables resolved"
  else
    count=$(echo "$unresolved" | wc -l | tr -d ' ')
    warn "$group_name: $count unresolved variable(s)"
    
    if [[ "$VERBOSE" == "true" ]]; then
      while IFS= read -r var; do
        var_name="${var#\$\{}"
        var_name="${var_name%\}}"
        desc="$(known_var_description "$var_name")"
        echo -e "    ${YELLOW}${var}${NC} — $desc"
        ALL_UNRESOLVED+=("$var_name")
      done <<< "$unresolved"
    else
      ALL_UNRESOLVED+=($(echo "$unresolved" | sed 's/\${//g; s/}//g'))
    fi
  fi
done

# Deduplicate
UNIQUE_VARS=($(echo "${ALL_UNRESOLVED[@]}" | tr ' ' '\n' | sort -u))

header "Summary"

echo ""
echo "  Total unresolved variables: ${#UNIQUE_VARS[@]}"
echo ""

if [[ ${#UNIQUE_VARS[@]} -gt 0 ]]; then
  if [[ "$FIX_MODE" == "true" ]]; then
    header "Required Environment Variables"
    echo ""
    echo "  Set these before deployment (add to .env or export):"
    echo ""
    for var in "${UNIQUE_VARS[@]}"; do
      desc="$(known_var_description "$var")"
      echo "  export ${var}=\"\"  # $desc"
    done
    echo ""
    echo "  Then run envsubst on the config files:"
    echo "  envsubst < file.yaml > file-resolved.yaml"
  fi
  
  echo ""
  echo -e "${YELLOW}━━━ ${#UNIQUE_VARS[@]} unresolved variable(s) found ━━━${NC}"
  echo "Run with --verbose for details or --fix for setup commands"
  exit 1
else
  echo -e "${GREEN}━━━ All variables resolved! ━━━${NC}"
  exit 0
fi
