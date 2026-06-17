#!/bin/bash
# =============================================================================
# validate-config.sh — Validate Terraform configuration before deployment
# =============================================================================
# Usage: ./scripts/validate-config.sh --environment <dev|staging|prod>
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ERRORS=0; WARNINGS=0
ENVIRONMENT=""
TERRAFORM_DIR="terraform"

header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
pass()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn()   { echo -e "  ${YELLOW}!${NC} $1"; WARNINGS=$((WARNINGS + 1)); }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment|-e) ENVIRONMENT="$2"; shift 2 ;;
    *) echo "Usage: $0 --environment <dev|staging|prod>"; exit 1 ;;
  esac
done

if [[ -z "$ENVIRONMENT" ]]; then
  echo "Error: --environment is required"
  echo "Usage: $0 --environment <dev|staging|prod>"
  exit 1
fi

TFVARS_FILE="$TERRAFORM_DIR/environments/${ENVIRONMENT}.tfvars"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       OPEN HORIZONS — Configuration Validation            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "  Environment: ${YELLOW}${ENVIRONMENT}${NC}"

# --- Check tfvars file exists -------------------------------------------------
header "Configuration File"
if [[ -f "$TFVARS_FILE" ]]; then
  pass "Found: $TFVARS_FILE"
else
  fail "Missing: $TFVARS_FILE"
  echo "  Create from template: cp $TERRAFORM_DIR/terraform.tfvars.example $TFVARS_FILE"
  exit 1
fi

# --- Check required environment variables -------------------------------------
header "Environment Variables (sensitive values)"
REQUIRED_ENV_VARS=("TF_VAR_azure_subscription_id" "TF_VAR_azure_tenant_id" "TF_VAR_admin_group_id" "TF_VAR_github_org" "TF_VAR_github_token")

for var in "${REQUIRED_ENV_VARS[@]}"; do
  if [[ -n "${!var:-}" ]]; then
    pass "$var is set"
  else
    # Check if it's in the tfvars file (non-empty)
    short_var="${var#TF_VAR_}"
    if grep -qE "^${short_var}\s*=\s*\"[^\"]+\"" "$TFVARS_FILE" 2>/dev/null; then
      pass "$short_var defined in $TFVARS_FILE"
    else
      fail "$var not set — export $var=... or set $short_var in $TFVARS_FILE"
    fi
  fi
done

# --- Check Azure subscription access -----------------------------------------
header "Azure Subscription"
if az account show &>/dev/null; then
  SUB_ID="${TF_VAR_azure_subscription_id:-$(az account show --query id -o tsv 2>/dev/null)}"
  if [[ -n "$SUB_ID" ]]; then
    pass "Subscription: $SUB_ID"
    # Verify we can access it
    if az account set --subscription "$SUB_ID" &>/dev/null; then
      pass "Subscription is accessible"
    else
      fail "Cannot access subscription $SUB_ID"
    fi
  fi
else
  warn "Not logged in to Azure — skipping subscription check"
fi

# --- Check Azure resource providers -------------------------------------------
header "Azure Resource Providers"
REQUIRED_PROVIDERS=(
  "Microsoft.ContainerService"
  "Microsoft.ContainerRegistry"
  "Microsoft.KeyVault"
  "Microsoft.Network"
  "Microsoft.ManagedIdentity"
)

if az account show &>/dev/null; then
  for provider in "${REQUIRED_PROVIDERS[@]}"; do
    STATE=$(az provider show --namespace "$provider" --query "registrationState" -o tsv 2>/dev/null || echo "Unknown")
    if [[ "$STATE" == "Registered" ]]; then
      pass "$provider: Registered"
    else
      fail "$provider: $STATE — run: az provider register --namespace $provider"
    fi
  done
else
  warn "Not logged in — skipping provider checks"
fi

# --- Terraform validation -----------------------------------------------------
header "Terraform Configuration"
if [[ -d "$TERRAFORM_DIR" ]]; then
  pass "Terraform directory exists"

  cd "$TERRAFORM_DIR"

  # Init with backend disabled
  if terraform init -backend=false -input=false &>/dev/null; then
    pass "terraform init succeeded"
  else
    fail "terraform init failed"
  fi

  # Format check
  if terraform fmt -check -recursive &>/dev/null; then
    pass "terraform fmt: All files formatted correctly"
  else
    warn "terraform fmt: Some files need formatting — run: terraform fmt -recursive"
  fi

  # Validate
  if terraform validate &>/dev/null; then
    pass "terraform validate: Configuration is valid"
  else
    fail "terraform validate: Configuration has errors"
    terraform validate 2>&1 | head -10
  fi

  cd ..
fi

# --- Summary ------------------------------------------------------------------
echo ""
if [[ "$ERRORS" -eq 0 ]]; then
  echo -e "${GREEN}━━━ Configuration valid! Ready to deploy. ━━━${NC}"
  echo ""
  echo "  Next step:"
  echo "  cd $TERRAFORM_DIR && terraform plan -var-file=environments/${ENVIRONMENT}.tfvars"
  exit 0
else
  echo -e "${RED}━━━ $ERRORS error(s), $WARNINGS warning(s) ━━━${NC}"
  echo "  Fix the issues above and run this script again."
  exit 1
fi
