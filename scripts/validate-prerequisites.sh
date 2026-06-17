#!/bin/bash
# =============================================================================
# validate-prerequisites.sh — Check all required CLI tools and versions
# =============================================================================
# Usage: ./scripts/validate-prerequisites.sh [--install]
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
MODE=""
INSTALL_MODE=""
ERRORS=0

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --local)   MODE="local" ;;
    --install) INSTALL_MODE="--install" ;;
  esac
done

header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
pass()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn()   { echo -e "  ${YELLOW}!${NC} $1"; }

# Semver comparison: returns 0 if $1 >= $2
version_gte() {
  local v1="$1" v2="$2"
  # Pad to 3 parts
  local IFS='.'
  read -ra a1 <<< "$v1"
  read -ra a2 <<< "$v2"
  for i in 0 1 2; do
    local n1=${a1[$i]:-0}
    local n2=${a2[$i]:-0}
    # strip non-numeric suffix
    n1=$(echo "$n1" | grep -oE '^[0-9]+' || echo 0)
    n2=$(echo "$n2" | grep -oE '^[0-9]+' || echo 0)
    if (( n1 > n2 )); then return 0; fi
    if (( n1 < n2 )); then return 1; fi
  done
  return 0
}

check_tool() {
  local tool="$1" min_version="$2" purpose="$3"
  if ! command -v "$tool" &>/dev/null; then
    fail "$tool not found — $purpose"
    return 1
  fi

  local version
  case "$tool" in
    az)        version=$(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo "0") ;;
    terraform) version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
    kubectl)   version=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' | sed 's/v//') ;;
    helm)      version=$(helm version --short 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
    gh)        version=$(gh --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
    jq)        version=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+') ;;
    yq)        version=$(yq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
    argocd)    version=$(argocd version --client --short 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0") ;;
    *)         version="unknown" ;;
  esac

  if version_gte "$version" "$min_version"; then
    pass "$tool $version (required: >= $min_version) — $purpose"
  else
    fail "$tool $version is below minimum $min_version — $purpose"
  fi
  return 0
}

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       OPEN HORIZONS — Prerequisites Validation            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

if [[ "$MODE" == "local" ]]; then
  fail "Local demo mode has been removed. Use dev/staging/prod environments."
  exit 1
else
  header "Required CLI Tools"
  check_tool "az"        "2.50.0"  "Azure CLI"               || true
  check_tool "terraform" "1.5.0"   "Infrastructure as Code"  || true
  check_tool "kubectl"   "1.28.0"  "Kubernetes CLI"          || true
  check_tool "helm"      "3.12.0"  "Kubernetes packages"     || true
  check_tool "gh"        "2.30.0"  "GitHub CLI"              || true
  check_tool "jq"        "1.6"     "JSON processor"          || true
  check_tool "yq"        "4.0.0"   "YAML processor"          || true

  header "Optional CLI Tools"
  check_tool "argocd"    "2.8.0"   "ArgoCD CLI (optional)"   || warn "Install later if using ArgoCD"

  header "Azure Authentication"
  if az account show &>/dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv 2>/dev/null)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
    pass "Logged in to Azure: $SUBSCRIPTION ($SUBSCRIPTION_ID)"
  else
    fail "Not logged in to Azure — run: az login"
  fi

  header "GitHub Authentication"
  if gh auth status &>/dev/null 2>&1; then
    GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
    pass "Logged in to GitHub as: $GH_USER"
  else
    fail "Not logged in to GitHub — run: gh auth login"
  fi
fi

echo ""
if [[ "$ERRORS" -eq 0 ]]; then
  echo -e "${GREEN}━━━ All prerequisites satisfied! ━━━${NC}"
  exit 0
else
  echo -e "${RED}━━━ $ERRORS issue(s) found ━━━${NC}"
  if [[ "$INSTALL_MODE" != "--install" ]]; then
    echo ""
    echo "To install missing tools (macOS):"
    echo "  brew install azure-cli terraform kubectl helm gh jq yq"
    echo ""
    echo "Or run with --install flag to auto-install:"
    echo "  ./scripts/validate-prerequisites.sh --install"
  fi
  exit 1
fi
