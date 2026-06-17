#!/bin/bash
# =============================================================================
# validate-deployment.sh — Post-deployment health checks
# =============================================================================
# Usage: ./scripts/validate-deployment.sh --environment <dev|staging|prod>
#        ./scripts/validate-deployment.sh --phase <h1|h2|h3|all>
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ERRORS=0; WARNINGS=0
ENVIRONMENT="${TF_VAR_environment:-dev}"
PHASE="all"

header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
pass()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn()   { echo -e "  ${YELLOW}!${NC} $1"; WARNINGS=$((WARNINGS + 1)); }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment|-e) ENVIRONMENT="$2"; shift 2 ;;
    --phase|-p)       PHASE="$2"; shift 2 ;;
    *) echo "Usage: $0 [--environment <env>] [--phase <h1|h2|h3|all>]"; exit 1 ;;
  esac
done

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       OPEN HORIZONS — Deployment Validation               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "  Environment: ${YELLOW}${ENVIRONMENT}${NC}  Phase: ${YELLOW}${PHASE}${NC}"

# =============================================================================
# H1 FOUNDATION CHECKS
# =============================================================================
if [[ "$PHASE" == "h1" || "$PHASE" == "all" ]]; then
  header "H1: Kubernetes Cluster"

  if kubectl cluster-info &>/dev/null; then
    pass "Cluster is reachable"
  else
    fail "Cannot reach cluster — run: az aks get-credentials -g <rg> -n <cluster>"
    if [[ "$PHASE" == "h1" ]]; then exit 1; fi
  fi

  NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
  READY_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || echo 0)
  if [[ "$READY_COUNT" -gt 0 ]]; then
    pass "Nodes: $READY_COUNT/$NODE_COUNT Ready"
  else
    fail "No nodes in Ready state"
  fi

  header "H1: Core Components"
  for ns in kube-system; do
    TOTAL=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
    RUNNING=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep -c "Running" || echo 0)
    if [[ "$RUNNING" -eq "$TOTAL" && "$TOTAL" -gt 0 ]]; then
      pass "$ns: $RUNNING/$TOTAL pods running"
    else
      warn "$ns: $RUNNING/$TOTAL pods running"
    fi
  done

  header "H1: Azure Resources"
  CUSTOMER_NAME=$(terraform -chdir="$(dirname "$0")/../terraform" output -raw customer_name 2>/dev/null || echo "")
  if [[ -n "$CUSTOMER_NAME" ]]; then
    RG_NAME="rg-${CUSTOMER_NAME}-${ENVIRONMENT}"
    if az group show --name "$RG_NAME" &>/dev/null 2>&1; then
      pass "Resource group exists: $RG_NAME"
    else
      warn "Resource group not found: $RG_NAME (may need az login or different naming)"
    fi
  else
    # Try to detect resource group from kubectl context
    RG_CONTEXT=$(kubectl config current-context 2>/dev/null | head -1 || echo "unknown")
    if az group list --query "[?starts_with(name, 'rg-')]" -o tsv &>/dev/null 2>&1; then
      RG_COUNT=$(az group list --query "length([?starts_with(name, 'rg-')])" -o tsv 2>/dev/null || echo 0)
      if [[ "$RG_COUNT" -gt 0 ]]; then
        pass "Found $RG_COUNT resource group(s) with rg- prefix"
      else
        warn "No resource groups with rg- prefix found"
      fi
    else
      warn "Could not verify resource group (may need az login)"
    fi
  fi
fi

# =============================================================================
# H2 ENHANCEMENT CHECKS
# =============================================================================
if [[ "$PHASE" == "h2" || "$PHASE" == "all" ]]; then
  header "H2: ArgoCD"
  if kubectl get namespace argocd &>/dev/null 2>&1; then
    ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -c "Running" || echo 0)
    if [[ "$ARGOCD_PODS" -gt 0 ]]; then
      pass "ArgoCD: $ARGOCD_PODS pods running"
    else
      fail "ArgoCD: No pods running in argocd namespace"
    fi
  else
    warn "ArgoCD namespace not found (may not be enabled)"
  fi

  header "H2: Observability"
  if kubectl get namespace observability &>/dev/null 2>&1; then
    OBS_PODS=$(kubectl get pods -n observability --no-headers 2>/dev/null | grep -c "Running" || echo 0)
    pass "Observability: $OBS_PODS pods running"
  else
    warn "Observability namespace not found (may not be enabled)"
  fi

  header "H2: External Secrets"
  if kubectl get namespace external-secrets &>/dev/null 2>&1; then
    ESO_PODS=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep -c "Running" || echo 0)
    pass "External Secrets: $ESO_PODS pods running"
  else
    warn "External Secrets namespace not found (may not be enabled)"
  fi
fi

# =============================================================================
# H3 INNOVATION CHECKS
# =============================================================================
if [[ "$PHASE" == "h3" || "$PHASE" == "all" ]]; then
  header "H3: AI Foundry"
  if az cognitiveservices account list --query "[?contains(name,'oai')]" -o tsv &>/dev/null 2>&1; then
    AI_COUNT=$(az cognitiveservices account list --query "length([?contains(name,'oai')])" -o tsv 2>/dev/null || echo 0)
    if [[ "$AI_COUNT" -gt 0 ]]; then
      pass "AI Foundry: $AI_COUNT account(s) found"
    else
      warn "AI Foundry: No accounts found (may not be enabled)"
    fi
  else
    warn "Could not check AI Foundry (requires az login)"
  fi
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
if [[ "$ERRORS" -eq 0 ]]; then
  echo -e "${GREEN}━━━ Deployment validation passed! ($WARNINGS warning(s)) ━━━${NC}"
  exit 0
else
  echo -e "${RED}━━━ $ERRORS error(s), $WARNINGS warning(s) ━━━${NC}"
  exit 1
fi
