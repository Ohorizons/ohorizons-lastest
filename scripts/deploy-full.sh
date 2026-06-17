#!/bin/bash
# =============================================================================
# deploy-full.sh — End-to-end deployment orchestrator
# =============================================================================
#
# Three deployment options are available:
#   Option A (Agent):     @deploy Deploy the platform to dev
#   Option B (Script):    ./scripts/deploy-full.sh --environment dev
#   Option C (Manual):    Follow docs/guides/DEPLOYMENT_GUIDE.md
#
# Usage:
#   ./scripts/deploy-full.sh --environment dev
#   ./scripts/deploy-full.sh --environment prod --horizon all
#   ./scripts/deploy-full.sh --environment dev --dry-run
#   ./scripts/deploy-full.sh --environment dev --destroy
#
# Flags:
#   --environment, -e   Required: dev | staging | prod
#   --horizon, -h       Optional: h1 | h2 | h3 | all (default: all)
#   --dry-run           Only terraform plan, no apply
#   --auto-approve      Skip confirmation prompts (for CI/CD)
#   --destroy           Teardown in reverse order
#   --skip-prerequisites Skip tool validation
#   --resume            Resume from last checkpoint
#
# =============================================================================
set -euo pipefail

# --- Colors & helpers ---------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/terraform"
CHECKPOINT_FILE="$PROJECT_DIR/.deploy-checkpoint"

# --- Defaults -----------------------------------------------------------------
ENVIRONMENT=""
HORIZON="all"
DRY_RUN=false
AUTO_APPROVE=false
DESTROY=false
SKIP_PREREQS=false
RESUME=false

# --- Parse arguments ----------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment|-e)     ENVIRONMENT="$2"; shift 2 ;;
    --horizon|-h)         HORIZON="$2"; shift 2 ;;
    --dry-run)            DRY_RUN=true; shift ;;
    --auto-approve)       AUTO_APPROVE=true; shift ;;
    --destroy)            DESTROY=true; shift ;;
    --skip-prerequisites) SKIP_PREREQS=true; shift ;;
    --resume)             RESUME=true; shift ;;
    --help)
      head -30 "$0" | grep -E '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown option: $1. Use --help for usage."; exit 1 ;;
  esac
done

if [[ -z "$ENVIRONMENT" ]]; then
  echo -e "${RED}Error: --environment is required${NC}"
  echo "Usage: $0 --environment <dev|staging|prod>"
  exit 1
fi

TFVARS_FILE="$TERRAFORM_DIR/environments/${ENVIRONMENT}.tfvars"
SELECTION_FILE="$PROJECT_DIR/.openhorizons-selection.yaml"

# --- Selection manifest --------------------------------------------------------
SELECTION_PRESENT=false
if [[ -f "$SELECTION_FILE" ]] && command -v yq >/dev/null 2>&1; then
  SELECTION_PRESENT=true
  sel_horizon="$(yq '.horizon' "$SELECTION_FILE" 2>/dev/null || echo null)"
  sel_environment="$(yq '.environment' "$SELECTION_FILE" 2>/dev/null || echo null)"
  if [[ -n "$sel_horizon" && "$sel_horizon" != "null" && "$sel_horizon" != "$HORIZON" ]]; then
    echo -e "  ${YELLOW}!${NC} Selection manifest horizon ($sel_horizon) differs from --horizon ($HORIZON)."
    echo "     Re-run scripts/install-wizard.sh or pass the matching --horizon."
  fi
  if [[ -n "$sel_environment" && "$sel_environment" != "null" && "$sel_environment" != "$ENVIRONMENT" ]]; then
    echo -e "  ${YELLOW}!${NC} Selection manifest environment ($sel_environment) differs from --environment ($ENVIRONMENT)."
  fi
fi

# --- Helper functions ---------------------------------------------------------
banner() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  ${BOLD}OPEN HORIZONS PLATFORM — Deployment${NC}${BLUE}                    ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo -e "  Environment: ${YELLOW}${ENVIRONMENT}${NC}"
  echo -e "  Horizons:    ${YELLOW}${HORIZON}${NC}"
  echo -e "  Mode:        ${YELLOW}$(if $DRY_RUN; then echo 'DRY RUN'; elif $DESTROY; then echo 'DESTROY'; else echo 'DEPLOY'; fi)${NC}"
  echo ""
}

phase() {
  local num="$1" name="$2"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Phase $num: $name${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

confirm() {
  if $AUTO_APPROVE; then return 0; fi
  read -rp "  Continue? (y/N): " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

save_checkpoint() {
  echo "$1" > "$CHECKPOINT_FILE"
}

load_checkpoint() {
  if [[ -f "$CHECKPOINT_FILE" ]]; then
    cat "$CHECKPOINT_FILE"
  else
    echo "0"
  fi
}

tf_plan() {
  local plan_file="$1"
  echo -e "  ${BLUE}Running terraform plan...${NC}"
  terraform plan \
    -var-file="environments/${ENVIRONMENT}.tfvars" \
    -out="$plan_file" \
    -detailed-exitcode 2>&1 | tail -5
  echo ""
}

tf_apply() {
  local plan_file="$1"
  if $DRY_RUN; then
    echo -e "  ${YELLOW}DRY RUN — skipping apply${NC}"
    return 0
  fi
  echo -e "  ${BLUE}Applying changes...${NC}"
  if ! confirm; then
    echo -e "  ${YELLOW}Skipped by user${NC}"
    return 0
  fi
  terraform apply "$plan_file"
}

# ==============================================================================
# DESTROY MODE
# ==============================================================================
if $DESTROY; then
  banner
  echo -e "${RED}${BOLD}  WARNING: This will DESTROY all resources in ${ENVIRONMENT}!${NC}"
  echo ""
  if ! $AUTO_APPROVE; then
    read -rp "  Type the environment name to confirm: " confirm_env
    if [[ "$confirm_env" != "$ENVIRONMENT" ]]; then
      echo "  Cancelled."
      exit 1
    fi
  fi

  cd "$TERRAFORM_DIR"
  terraform init -input=false
  terraform destroy \
    -var-file="environments/${ENVIRONMENT}.tfvars" \
    $(if $AUTO_APPROVE; then echo "-auto-approve"; fi)

  rm -f "$CHECKPOINT_FILE"
  echo -e "\n${GREEN}━━━ Destroy complete ━━━${NC}"
  exit 0
fi

# ==============================================================================
# DEPLOY MODE
# ==============================================================================
banner

LAST_PHASE=0
if $RESUME; then
  LAST_PHASE=$(load_checkpoint)
  echo -e "  ${YELLOW}Resuming from phase $((LAST_PHASE + 1))${NC}"
fi

# --- Phase 0: Prerequisites --------------------------------------------------
if [[ "$LAST_PHASE" -lt 1 ]] && ! $SKIP_PREREQS; then
  phase 0 "Prerequisites"
  "$SCRIPT_DIR/validate-prerequisites.sh" || {
    echo -e "  ${RED}Prerequisites check failed. Fix issues and retry.${NC}"
    exit 1
  }
  save_checkpoint 1
fi

# --- Phase 1: Validate Configuration -----------------------------------------
if [[ "$LAST_PHASE" -lt 2 ]]; then
  phase 1 "Validate Configuration"
  if [[ ! -f "$TFVARS_FILE" ]]; then
    echo -e "  ${RED}Missing: $TFVARS_FILE${NC}"
    echo "  Create from template: cp terraform/terraform.tfvars.example $TFVARS_FILE"
    exit 1
  fi
  echo -e "  ${GREEN}✓${NC} Configuration file: $TFVARS_FILE"
  save_checkpoint 2
fi

# --- Phase 2: Terraform Init -------------------------------------------------
if [[ "$LAST_PHASE" -lt 3 ]]; then
  phase 2 "Terraform Init"
  cd "$TERRAFORM_DIR"
  terraform init -input=false -upgrade
  terraform validate
  echo -e "  ${GREEN}✓${NC} Terraform initialized and validated"
  save_checkpoint 3
fi

# --- Phase 3: Deploy H1 Foundation -------------------------------------------
if [[ "$LAST_PHASE" -lt 4 ]] && [[ "$HORIZON" == "h1" || "$HORIZON" == "all" ]]; then
  phase 3 "Deploy H1 Foundation (Networking, AKS, Security)"
  cd "$TERRAFORM_DIR"

  tf_plan "h1.tfplan"
  tf_apply "h1.tfplan"

  if ! $DRY_RUN; then
    echo ""
    echo -e "  ${BLUE}Configuring kubectl...${NC}"
    RG_NAME=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    AKS_NAME=$(terraform output -raw aks_cluster_name 2>/dev/null || echo "")
    if [[ -n "$RG_NAME" && -n "$AKS_NAME" ]]; then
      az aks get-credentials \
        --resource-group "$RG_NAME" \
        --name "$AKS_NAME" \
        --overwrite-existing
      echo -e "  ${GREEN}✓${NC} kubectl configured"
    fi
  fi

  save_checkpoint 4
fi

# --- Phase 4: Verify H1 ------------------------------------------------------
if [[ "$LAST_PHASE" -lt 5 ]] && [[ "$HORIZON" == "h1" || "$HORIZON" == "all" ]] && ! $DRY_RUN; then
  phase 4 "Verify H1 Foundation"
  "$SCRIPT_DIR/validate-deployment.sh" --phase h1 || echo -e "  ${YELLOW}⚠ H1 verification had warnings${NC}"
  save_checkpoint 5
fi

# --- Phase 5: Deploy H2 Enhancement ------------------------------------------
if [[ "$LAST_PHASE" -lt 6 ]] && [[ "$HORIZON" == "h2" || "$HORIZON" == "all" ]]; then
  phase 5 "Deploy H2 Enhancement (ArgoCD, Observability, External Secrets)"
  cd "$TERRAFORM_DIR"

  if $DRY_RUN; then
    echo -e "  ${BLUE}Running terraform plan for H2 modules...${NC}"
    terraform plan \
      -var-file="environments/${ENVIRONMENT}.tfvars" \
      -target=module.argocd \
      -target=module.observability \
      -target=module.external_secrets \
      -target=module.databases 2>&1 | tail -5
    echo -e "  ${YELLOW}DRY RUN — skipping H2 apply${NC}"
  else
    echo -e "  ${BLUE}Applying H2 modules (ArgoCD, Observability, External Secrets, Databases)...${NC}"
    terraform apply \
      -var-file="environments/${ENVIRONMENT}.tfvars" \
      -target=module.argocd \
      -target=module.observability \
      -target=module.external_secrets \
      -target=module.databases \
      $(if $AUTO_APPROVE; then echo "-auto-approve"; fi)
    echo -e "  ${GREEN}\u2713${NC} H2 modules deployed via Terraform"
  fi
  echo "  Verify with: kubectl get pods -n argocd"

  save_checkpoint 6
fi

# --- Phase 5b: Render and apply Backstage manifests --------------------------
if [[ "$LAST_PHASE" -lt 6 ]] && [[ "$HORIZON" == "h2" || "$HORIZON" == "all" ]] && ! $DRY_RUN; then
  if [[ -x "$SCRIPT_DIR/render-manifests.sh" ]]; then
    echo -e "  ${BLUE}Rendering Backstage manifests from selection...${NC}"
    "$SCRIPT_DIR/render-manifests.sh" --selection "$SELECTION_FILE" || \
      echo -e "  ${YELLOW}!${NC} render-manifests.sh exited non-zero; continuing."
    if [[ -d "$PROJECT_DIR/backstage/k8s/.rendered" ]] && command -v kubectl >/dev/null 2>&1; then
      if kubectl cluster-info >/dev/null 2>&1; then
        echo -e "  ${BLUE}Applying rendered Backstage manifests...${NC}"
        kubectl apply -k "$PROJECT_DIR/backstage/k8s/.rendered" || \
          echo -e "  ${YELLOW}!${NC} kubectl apply -k failed; check cluster context."
      else
        echo -e "  ${YELLOW}!${NC} No live cluster context; skipping kubectl apply."
      fi
    fi
  fi
fi

# --- Phase 6: Verify H2 ------------------------------------------------------
if [[ "$LAST_PHASE" -lt 7 ]] && [[ "$HORIZON" == "h2" || "$HORIZON" == "all" ]] && ! $DRY_RUN; then
  phase 6 "Verify H2 Enhancement"
  "$SCRIPT_DIR/validate-deployment.sh" --phase h2 || true
  save_checkpoint 7
fi

# --- Phase 7: Deploy H3 Innovation -------------------------------------------
if [[ "$LAST_PHASE" -lt 8 ]] && [[ "$HORIZON" == "h3" || "$HORIZON" == "all" ]]; then
  phase 7 "Deploy H3 Innovation (AI Foundry)"
  cd "$TERRAFORM_DIR"

  if grep -q 'enable_ai_foundry.*=.*true' "environments/${ENVIRONMENT}.tfvars"; then
    echo -e "  ${GREEN}✓${NC} AI Foundry enabled in configuration"
    if $DRY_RUN; then
      echo -e "  ${BLUE}Running terraform plan for AI Foundry...${NC}"
      terraform plan \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -target=module.ai_foundry 2>&1 | tail -5
      echo -e "  ${YELLOW}DRY RUN — skipping H3 apply${NC}"
    else
      echo -e "  ${BLUE}Applying AI Foundry module...${NC}"
      terraform apply \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -target=module.ai_foundry \
        $(if $AUTO_APPROVE; then echo "-auto-approve"; fi)
      echo -e "  ${GREEN}\u2713${NC} AI Foundry deployed via Terraform"
    fi
  else
    echo -e "  ${YELLOW}!${NC} AI Foundry disabled in ${ENVIRONMENT}.tfvars"
    echo "  To enable: set enable_ai_foundry = true and re-run"
  fi

  save_checkpoint 8
fi

# --- Phase 8: Final Verification ---------------------------------------------
if [[ "$LAST_PHASE" -lt 9 ]] && ! $DRY_RUN; then
  phase 8 "Final Platform Verification"
  "$SCRIPT_DIR/validate-deployment.sh" --phase all --environment "$ENVIRONMENT" || true
  save_checkpoint 9
fi

# --- Phase 9: Summary --------------------------------------------------------
phase 9 "Deployment Summary"

if $DRY_RUN; then
  echo -e "  ${YELLOW}DRY RUN completed — no resources were created${NC}"
  echo ""
  echo "  To deploy for real, remove --dry-run:"
  echo "  $0 --environment $ENVIRONMENT --horizon $HORIZON"
else
  cd "$TERRAFORM_DIR"
  echo ""
  terraform output deployment_summary 2>/dev/null || true
  echo ""
  echo -e "  ${GREEN}━━━ Deployment complete! ━━━${NC}"
  echo ""
  echo "  Next steps:"
  echo "    kubectl get nodes"
  echo "    kubectl get pods -A"
  echo "    ./scripts/validate-deployment.sh --environment $ENVIRONMENT"

  # Cleanup checkpoint
  rm -f "$CHECKPOINT_FILE"
fi

echo ""
