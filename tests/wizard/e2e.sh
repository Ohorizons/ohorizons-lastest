#!/usr/bin/env bash
# =============================================================================
# End-to-end tests for the Open Horizons install wizard
#
# Exercises the full pipeline:
#   install-wizard.sh --profile <p>   (writes manifest + tfvars + app-config)
#     -> render-manifests.sh           (filters backstage/k8s into .rendered)
#       -> kubectl kustomize           (validates kustomize build)
#       -> kubectl apply --dry-run     (optional, requires cluster context)
#
# Usage:
#   bash tests/wizard/e2e.sh                  # client-side only
#   KUBECTL_E2E_SERVER=1 bash tests/wizard/e2e.sh  # also runs --dry-run=server
#
# Exit 0 on success, non-zero on first failure.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WIZARD="$REPO_ROOT/scripts/install-wizard.sh"
RENDER="$REPO_ROOT/scripts/render-manifests.sh"
APP_CONFIG="$REPO_ROOT/backstage/app-config.production.yaml"
MANIFEST="$REPO_ROOT/.openhorizons-selection.yaml"
RENDERED="$REPO_ROOT/backstage/k8s/.rendered"
ENABLE_SERVER_DRY_RUN="${KUBECTL_E2E_SERVER:-0}"

if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

PASS=0; FAIL=0
SCENARIO=""

step()    { echo -e "\n${BLUE}--- $* ---${NC}"; }
pass()    { echo -e "  ${GREEN}PASS${NC}  $*"; PASS=$((PASS + 1)); }
fail()    { echo -e "  ${RED}FAIL${NC}  $*"; FAIL=$((FAIL + 1)); }
must() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc (cmd: $*)"; fi
}

# Backup files we will mutate during tests
manifest_backup="$(mktemp)"
appconfig_backup="$(mktemp)"
[[ -f "$MANIFEST" ]]   && cp "$MANIFEST"   "$manifest_backup"
[[ -f "$APP_CONFIG" ]] && cp "$APP_CONFIG" "$appconfig_backup"

cleanup() {
  echo
  echo "--- cleanup ---"
  if [[ -s "$appconfig_backup" ]]; then
    cp "$appconfig_backup" "$APP_CONFIG"
    echo "  restored app-config.production.yaml"
  fi
  if [[ -s "$manifest_backup" ]]; then
    cp "$manifest_backup" "$MANIFEST"
  else
    rm -f "$MANIFEST"
  fi
  rm -f "$manifest_backup" "$appconfig_backup"
  rm -rf "$RENDERED"
  rm -rf "$REPO_ROOT/golden-paths/common/agents/.rendered"
  rm -f "$REPO_ROOT/.openhorizons-selection.history"
  rm -f "$MANIFEST".bak.* 2>/dev/null
  rm -f "$APP_CONFIG".bak.* 2>/dev/null
  rm -f "$REPO_ROOT/terraform/environments/dev.tfvars" 2>/dev/null
  rm -f "$REPO_ROOT/terraform/environments/dev.tfvars".bak.* 2>/dev/null
  rm -f "$REPO_ROOT/terraform/environments/staging.tfvars" 2>/dev/null
  rm -f "$REPO_ROOT/terraform/environments/staging.tfvars".bak.* 2>/dev/null
  if [[ "$ENABLE_SERVER_DRY_RUN" == "1" ]] && kubectl get nodes >/dev/null 2>&1; then
    kubectl delete namespace backstage --ignore-not-found --wait=false >/dev/null 2>&1 || true
    kubectl delete namespace ai-services --ignore-not-found --wait=false >/dev/null 2>&1 || true
    echo "  removed test namespaces"
  fi
  echo "  removed transient artifacts"
}
trap cleanup EXIT

run_scenario() {
  SCENARIO="$1"
  local profile="$2"
  local env="${3:-dev}"
  step "Scenario: $SCENARIO (profile=$profile env=$env)"

  rm -f "$MANIFEST"
  rm -rf "$RENDERED"

  # 1. Wizard
  if ! "$WIZARD" --environment "$env" --auto --profile "$profile" >/dev/null 2>&1; then
    fail "wizard --auto --profile $profile failed"
    return
  fi
  pass "wizard wrote manifest and rendered files"

  must "manifest.yaml exists" test -f "$MANIFEST"
  must "tfvars exists" test -f "$REPO_ROOT/terraform/environments/${env}.tfvars"

  # 2. Render manifests
  if ! "$RENDER" >/dev/null 2>&1; then
    fail "render-manifests.sh failed"
    return
  fi
  pass "render-manifests produced output"
  must "kustomization.yaml exists" test -f "$RENDERED/kustomization.yaml"
  must "namespace.yaml is always present" test -f "$RENDERED/namespace.yaml"

  # 3. Validate kustomize build (client-side)
  if kubectl kustomize "$RENDERED" >/dev/null 2>&1; then
    pass "kubectl kustomize build succeeds"
  else
    fail "kubectl kustomize build failed"
    return
  fi

  # 4. Per-profile expectations
  case "$profile" in
    minimal)
      if [[ -f "$RENDERED/agent-api-deployment.yaml" ]]; then
        fail "minimal profile leaked agent-api-deployment.yaml"
      else
        pass "minimal profile correctly omits agent-api"
      fi
      if [[ -f "$RENDERED/mcp-ecosystem-deployment.yaml" ]]; then
        fail "minimal profile leaked mcp-ecosystem"
      else
        pass "minimal profile correctly omits mcp-ecosystem"
      fi
      ;;
    full)
      must "full profile includes agent-api" test -f "$RENDERED/agent-api-deployment.yaml"
      must "full profile includes agent-api-impact" test -f "$RENDERED/agent-api-impact-deployment.yaml"
      must "full profile includes mcp-ecosystem" test -f "$RENDERED/mcp-ecosystem-deployment.yaml"
      ;;
    standard)
      must "standard profile includes agent-api" test -f "$RENDERED/agent-api-deployment.yaml"
      if [[ -f "$RENDERED/mcp-ecosystem-deployment.yaml" ]]; then
        fail "standard profile leaked mcp-ecosystem"
      else
        pass "standard profile correctly omits mcp-ecosystem"
      fi
      ;;
  esac

  # 5. Optional server-side dry run
  if [[ "$ENABLE_SERVER_DRY_RUN" == "1" ]]; then
    if kubectl get nodes >/dev/null 2>&1; then
      # Apply namespaces first (server-dry-run cannot create + reference in one shot).
      kubectl apply -f "$RENDERED/namespace.yaml" >/dev/null 2>&1
      # mcp-ecosystem-deployment uses the ai-services namespace which is not in
      # backstage/k8s; pre-create it so dry-run can locate it.
      kubectl create namespace ai-services --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
      # Skip resources that require external CRDs not part of the install-wizard
      # surface (cert-manager, gateway-api, etc.) - those come from the platform
      # bootstrap stage. We dry-run only the namespaced resources from the wizard.
      local skip_files="tls.yaml namespace.yaml"
      local rejected=0
      while IFS= read -r f; do
        local base; base="$(basename "$f")"
        local skip=false
        for s in $skip_files; do [[ "$base" == "$s" ]] && skip=true; done
        $skip && continue
        if ! kubectl apply -f "$f" --dry-run=server >/dev/null 2>&1; then
          rejected=$((rejected + 1))
          # Re-run to capture the error reason for diagnostics
          local reason; reason="$(kubectl apply -f "$f" --dry-run=server 2>&1 | head -1)"
          echo "    rejected: $base -- ${reason:0:120}"
        fi
      done < <(find "$RENDERED" -maxdepth 1 -type f -name '*.yaml' ! -name 'kustomization.yaml')
      if [[ "$rejected" -eq 0 ]]; then
        pass "kubectl --dry-run=server accepted all wizard manifests"
      else
        fail "kubectl --dry-run=server rejected $rejected manifest(s)"
      fi
    else
      echo "  (server dry-run skipped: cluster context not reachable)"
    fi
  fi
}

run_custom_allowlist() {
  SCENARIO="custom-allowlist"
  step "Scenario: $SCENARIO"
  local sel; sel="$(mktemp)"
  cat > "$sel" <<'YAML'
horizon: h2
environment: dev
deployment_mode: standard
modules:
  enable_container_registry: true
  enable_argocd: true
  enable_observability: true
backstage_components:
  enable_ai_chat_plugin: true
  enable_agent_api: true
  enable_agent_api_impact: false
  enable_mcp_ecosystem: false
golden_paths:
  - h1-foundation/web-application
  - h2-enhancement/microservice
agents:
  - pipeline
  - sentinel
skills:
  - kubectl-cli
  - terraform-cli
prompts:
  - deploy-platform
mcp_servers: []
YAML

  rm -f "$MANIFEST"
  rm -rf "$RENDERED"
  if ! "$WIZARD" --environment dev --auto --selection-file "$sel" >/dev/null 2>&1; then
    fail "wizard with custom allowlist failed"
    rm -f "$sel"
    return
  fi
  rm -f "$sel"
  pass "wizard accepted custom allowlist"

  if ! "$RENDER" >/dev/null 2>&1; then
    fail "render-manifests with allowlist failed"
    return
  fi

  if kubectl kustomize "$RENDERED" >/dev/null 2>&1; then
    pass "kustomize build succeeds with allowlist"
  else
    fail "kustomize build failed with allowlist"
  fi

  must "agent-api included" test -f "$RENDERED/agent-api-deployment.yaml"
  if [[ -f "$RENDERED/agent-api-impact-deployment.yaml" ]]; then
    fail "agent-api-impact leaked"
  else
    pass "agent-api-impact correctly excluded"
  fi

  # Verify rendered primitives
  local rendered_dir="$REPO_ROOT/golden-paths/common/agents/.rendered"
  if [[ -d "$rendered_dir/.github/agents" ]]; then
    local count
    count=$(ls "$rendered_dir/.github/agents" 2>/dev/null | wc -l | tr -d ' ')
    [[ "$count" == "2" ]] && pass "agents allowlist count = 2" || fail "agents allowlist count = $count, expected 2"
  fi
}

# ============================================================================ 
# Main
# ============================================================================ 

echo "=== Open Horizons E2E test suite ==="
echo "REPO_ROOT=$REPO_ROOT"
echo "ENABLE_SERVER_DRY_RUN=$ENABLE_SERVER_DRY_RUN"

# Sanity checks
must "install-wizard.sh is executable" test -x "$WIZARD"
must "render-manifests.sh is executable" test -x "$RENDER"
must "kubectl is available" command -v kubectl

run_scenario "minimal" minimal dev
run_scenario "standard" standard staging
run_scenario "full" full dev
run_custom_allowlist

echo
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
