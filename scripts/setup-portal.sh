#!/usr/bin/env bash
# =============================================================================
# ohorizons - Portal Setup Wizard
# =============================================================================
# Interactive wizard that collects all configuration needed to deploy
# a developer portal (Backstage) on Azure or locally.
#
# Usage:
#   ./scripts/setup-portal.sh                  # Interactive mode
#   ./scripts/setup-portal.sh --non-interactive # Use environment variables
#
# Output:
#   - terraform/environments/<env>.auto.tfvars  (Azure deployments)
#   - Displays summary of collected configuration
# =============================================================================
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Defaults ---
PORTAL_NAME="${PORTAL_NAME:-}"
PORTAL_TYPE="${PORTAL_TYPE:-}"
PLATFORM_TYPE="${PLATFORM_TYPE:-}"
DEPLOY_MODE="${DEPLOY_MODE:-}"
AZURE_SUBSCRIPTION="${AZURE_SUBSCRIPTION:-}"
AZURE_REGION="${AZURE_REGION:-}"
GITHUB_ORG="${GITHUB_ORG:-}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
NON_INTERACTIVE=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --non-interactive) NON_INTERACTIVE=true; shift ;;
    *) shift ;;
  esac
done

# --- Helpers ---
banner() {
  echo -e "\n${PURPLE}${BOLD}"
  echo "  ============================================================"
  echo "    ohorizons - Agentic DevOps Platform Setup Wizard"
  echo "  ============================================================"
  echo -e "${NC}\n"
}

ask() {
  local var_name="$1" prompt="$2" default="${3:-}"
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    eval "val=\${$var_name:-$default}"
    if [[ -z "$val" ]]; then
      echo -e "${RED}Error: $var_name is required in non-interactive mode${NC}" >&2
      exit 1
    fi
    eval "$var_name=\"$val\""
    return
  fi
  local input
  if [[ -n "$default" ]]; then
    read -rp "$(echo -e "${CYAN}$prompt${NC} [${default}]: ")" input
    eval "$var_name=\"${input:-$default}\""
  else
    read -rp "$(echo -e "${CYAN}$prompt${NC}: ")" input
    eval "$var_name=\"$input\""
  fi
}

choose() {
  local var_name="$1" prompt="$2"
  shift 2
  local options=("$@")
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    eval "val=\${$var_name:-}"
    if [[ -z "$val" ]]; then
      echo -e "${RED}Error: $var_name is required in non-interactive mode${NC}" >&2
      exit 1
    fi
    return
  fi
  echo -e "\n${BOLD}$prompt${NC}"
  local i=1
  for opt in "${options[@]}"; do
    echo -e "  ${CYAN}$i)${NC} $opt"
    ((i++))
  done
  local choice
  read -rp "$(echo -e "${CYAN}Choose [1-${#options[@]}]${NC}: ")" choice
  eval "$var_name=\"$choice\""
}

ok() { echo -e "  ${GREEN}[OK]${NC} $1"; }
info() { echo -e "  ${BLUE}[i]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }

# =============================================================================
# STEP 1: Portal Configuration
# =============================================================================
step1_portal() {
  echo -e "\n${BOLD}Step 1/5: Portal Configuration${NC}"
  echo -e "${BOLD}------------------------------${NC}\n"

  ask PORTAL_NAME "Portal name (e.g. acme-developer-portal)" ""
  if [[ -z "$PORTAL_NAME" ]]; then
    echo -e "${RED}Portal name is required${NC}"
    exit 1
  fi
  ok "Portal name: $PORTAL_NAME"

  PORTAL_TYPE="backstage"
  ok "Portal type: Backstage"
  PLATFORM_TYPE="aks"
  info "Backstage always deploys on AKS"
}

# =============================================================================
# STEP 2: Deployment Mode
# =============================================================================
step2_deploy_mode() {
  echo -e "\n${BOLD}Step 2/5: Deployment Mode${NC}"
  echo -e "${BOLD}-------------------------${NC}\n"

  DEPLOY_MODE="azure"
  ok "Deployment: Azure (AKS)"
}

# =============================================================================
# STEP 3: Azure Configuration (if Azure mode)
# =============================================================================
step3_azure() {
  if [[ "$DEPLOY_MODE" != "azure" ]]; then
    info "Skipping Azure config (deploy mode: $DEPLOY_MODE)"
    return
  fi

  echo -e "\n${BOLD}Step 3/5: Azure Configuration${NC}"
  echo -e "${BOLD}-----------------------------${NC}\n"

  ask AZURE_SUBSCRIPTION "Azure Subscription ID" ""
  if [[ -z "$AZURE_SUBSCRIPTION" ]]; then
    echo -e "${RED}Azure Subscription ID is required for Azure deployments${NC}"
    exit 1
  fi
  ok "Subscription: $AZURE_SUBSCRIPTION"

  choose AZURE_REGION "Azure Region" \
    "Central US (centralus)" \
    "East US (eastus)"
  case "$AZURE_REGION" in
    1) AZURE_REGION="centralus"; ok "Region: Central US" ;;
    2) AZURE_REGION="eastus"; ok "Region: East US" ;;
    *) AZURE_REGION="centralus"; ok "Region: Central US (default)" ;;
  esac

  ask ENVIRONMENT "Environment name" "dev"
  ok "Environment: $ENVIRONMENT"
}

# =============================================================================
# STEP 4: GitHub Configuration
# =============================================================================
step4_github() {
  echo -e "\n${BOLD}Step 4/5: GitHub Configuration${NC}"
  echo -e "${BOLD}------------------------------${NC}\n"

  ask GITHUB_ORG "GitHub organization" ""
  ok "GitHub org: $GITHUB_ORG"

  echo ""
  info "GitHub App is needed for portal authentication and catalog integration."
  info "If you don't have one yet, run: ./scripts/setup-github-app.sh --org $GITHUB_ORG"

  ask GITHUB_APP_ID "GitHub App ID (numeric)" "${GITHUB_APP_ID:-}"
  ask GITHUB_APP_CLIENT_ID "GitHub App Client ID" "${GITHUB_APP_CLIENT_ID:-}"
  ask GITHUB_APP_CLIENT_SECRET "GitHub App Client Secret" "${GITHUB_APP_CLIENT_SECRET:-}"
  ask GITHUB_APP_PRIVATE_KEY_FILE "Path to GitHub App Private Key (.pem)" "${GITHUB_APP_PRIVATE_KEY_FILE:-}"

  if [[ -n "$GITHUB_APP_PRIVATE_KEY_FILE" && -f "$GITHUB_APP_PRIVATE_KEY_FILE" ]]; then
    ok "Private key file found: $GITHUB_APP_PRIVATE_KEY_FILE"
  elif [[ -n "$GITHUB_APP_PRIVATE_KEY_FILE" ]]; then
    warn "Private key file not found: $GITHUB_APP_PRIVATE_KEY_FILE"
  fi

  ask TEMPLATE_REPO "Template repository" "${GITHUB_ORG:+$GITHUB_ORG/agentic-devops-platform}"
  ok "Template repo: $TEMPLATE_REPO"
}

# =============================================================================
# STEP 5: Generate Configuration
# =============================================================================
step5_generate() {
  echo -e "\n${BOLD}Step 5/5: Generating Configuration${NC}"
  echo -e "${BOLD}----------------------------------${NC}\n"

  generate_azure_config
}

generate_azure_config() {
  local tfvars_file="$ROOT_DIR/terraform/environments/${ENVIRONMENT}.auto.tfvars"

  cat > "$tfvars_file" << TFVARS
# =============================================================================
# Generated by setup-portal.sh on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# =============================================================================

# Portal
portal_name     = "$PORTAL_NAME"
portal_type     = "$PORTAL_TYPE"
platform_type   = "$PLATFORM_TYPE"

# Azure
location        = "$AZURE_REGION"
environment     = "$ENVIRONMENT"
customer_name   = "$PORTAL_NAME"

# GitHub
github_org      = "$GITHUB_ORG"
github_app_id   = "${GITHUB_APP_ID:-}"
template_repo   = "$TEMPLATE_REPO"
TFVARS

  ok "Generated $tfvars_file"

  ok "Azure configuration ready"
  echo ""
  info "To deploy on Azure:"
  echo -e "  ${BOLD}cd terraform${NC}"
  echo -e "  ${BOLD}terraform init${NC}"
  echo -e "  ${BOLD}terraform plan -var-file=environments/${ENVIRONMENT}.auto.tfvars${NC}"
  echo -e "  ${BOLD}terraform apply -var-file=environments/${ENVIRONMENT}.auto.tfvars${NC}"
}

# =============================================================================
# SUMMARY
# =============================================================================
summary() {
  echo -e "\n${PURPLE}${BOLD}"
  echo "  ============================================================"
  echo "    Setup Complete"
  echo "  ============================================================"
  echo -e "${NC}\n"

  echo -e "  ${BOLD}Portal Name:${NC}     $PORTAL_NAME"
  echo -e "  ${BOLD}Portal Type:${NC}     $PORTAL_TYPE"
  echo -e "  ${BOLD}Platform:${NC}        $PLATFORM_TYPE"
  echo -e "  ${BOLD}Deploy Mode:${NC}     $DEPLOY_MODE"
  if [[ "$DEPLOY_MODE" == "azure" ]]; then
    echo -e "  ${BOLD}Azure Region:${NC}    $AZURE_REGION"
    echo -e "  ${BOLD}Environment:${NC}     $ENVIRONMENT"
    echo -e "  ${BOLD}Subscription:${NC}    $AZURE_SUBSCRIPTION"
  fi
  echo -e "  ${BOLD}GitHub Org:${NC}      ${GITHUB_ORG:-not set}"
  echo -e "  ${BOLD}Template Repo:${NC}   ${TEMPLATE_REPO:-not set}"
  echo ""

  if [[ "$DEPLOY_MODE" == "azure" ]]; then
    echo -e "  ${GREEN}Next: @deploy Deploy the platform to $ENVIRONMENT${NC}"
  fi
  echo ""
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  banner
  step1_portal
  step2_deploy_mode
  step3_azure
  step4_github
  step5_generate
  summary
}

main
