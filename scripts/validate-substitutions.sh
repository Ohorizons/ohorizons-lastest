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

# Files to check for unresolved variables
declare -A FILE_GROUPS=(
  ["Helm ArgoCD"]="deploy/helm/argocd/values.yaml"
  ["Helm Monitoring"]="deploy/helm/monitoring/values.yaml"
  ["ArgoCD Root App"]="argocd/app-of-apps/root-application.yaml"
  ["ArgoCD Repo Creds"]="argocd/repo-credentials.yaml"
  ["ArgoCD Secret Store"]="argocd/secrets/cluster-secret-store.yaml"
  ["Prometheus Alerting"]="prometheus/alerting-rules.yaml"
  ["K8s Constraints"]="policies/kubernetes/constraints/platform-constraints.yaml"
)

# Known variables and their descriptions
declare -A KNOWN_VARS=(
  ["DNS_ZONE_NAME"]="Base DNS zone (e.g., platform.contoso.com)"
  ["GITHUB_ORG"]="GitHub organization name"
  ["CUSTOMER_NAME"]="Customer name for resource naming"
  ["CUSTOMER_FULL_NAME"]="Full customer display name"
  ["CUSTOMER_DOMAIN"]="Customer email domain"
  ["AZURE_TENANT_ID"]="Azure AD tenant ID"
  ["AZURE_SUBSCRIPTION_ID"]="Azure subscription ID"
  ["GRAFANA_ADMIN_PASSWORD"]="Grafana admin password"
  ["GRAFANA_CLIENT_ID"]="Grafana Azure AD app client ID"
  ["GRAFANA_CLIENT_SECRET"]="Grafana Azure AD app client secret"
  ["GRAFANA_TOKEN"]="Grafana API token"
  ["PAGERDUTY_SERVICE_KEY"]="PagerDuty integration key"
  ["TEAMS_WEBHOOK_URL"]="Microsoft Teams webhook URL"
  ["GITHUB_APP_ID"]="GitHub App ID"
  ["GITHUB_APP_CLIENT_ID"]="GitHub App client ID"
  ["GITHUB_APP_CLIENT_SECRET"]="GitHub App client secret"
  ["GITHUB_APP_PRIVATE_KEY"]="GitHub App private key (PEM)"
  ["GITHUB_PAT"]="GitHub personal access token"
  ["GITHUB_WEBHOOK_SECRET"]="GitHub webhook secret"
  ["SSH_PRIVATE_KEY"]="SSH private key for Git"
  ["AZURE_DEVOPS_PAT"]="Azure DevOps PAT"
  ["ACR_NAME"]="Azure Container Registry name"
  ["ACR_USERNAME"]="ACR username"
  ["ACR_PASSWORD"]="ACR password"
  ["KEY_VAULT_URL"]="Azure Key Vault URL"
  ["KEY_VAULT_NAME"]="Azure Key Vault name"
  ["CLUSTER_NAME"]="AKS cluster name"
  ["ENVIRONMENT"]="Environment name (dev/staging/prod)"
  ["BACKSTAGE_MANAGED_IDENTITY_CLIENT_ID"]="Backstage managed identity client ID"
  ["POSTGRESQL_HOST"]="PostgreSQL server hostname"
  ["POSTGRESQL_USER"]="PostgreSQL admin username"
  ["POSTGRESQL_PASSWORD"]="PostgreSQL admin password"
  ["ARGOCD_AUTH_TOKEN"]="ArgoCD authentication token"
  ["ARGOCD_ADMIN_PASSWORD"]="ArgoCD admin password"
  ["STORAGE_ACCOUNT_NAME"]="Azure Storage account name"
  ["STORAGE_ACCOUNT_KEY"]="Azure Storage account key"
  ["K8S_SERVICE_ACCOUNT_TOKEN"]="Kubernetes service account token"
  ["DNS_ZONE_RESOURCE_GROUP"]="Resource group containing DNS zone"
  ["EXTERNAL_DNS_CLIENT_ID"]="External DNS managed identity client ID"
  ["RUNBOOK_BASE_URL"]="Base URL for operational runbooks"
)

ALL_UNRESOLVED=()

header "Scanning Configuration Files"

for group_name in "${!FILE_GROUPS[@]}"; do
  file="${PROJECT_ROOT}/${FILE_GROUPS[$group_name]}"
  
  if [[ ! -f "$file" ]]; then
    warn "$group_name: File not found (${FILE_GROUPS[$group_name]})"
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
        desc="${KNOWN_VARS[$var_name]:-Unknown variable}"
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
      desc="${KNOWN_VARS[$var]:-Unknown}"
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
