#!/usr/bin/env bash
# =============================================================================
# Static checks for Entra redirect URI wiring in terraform/modules/security
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

assert() {
  local desc="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $desc (expected '$expected', got '$actual')"
    FAIL=$((FAIL + 1))
  fi
}

security_main="$REPO_ROOT/terraform/modules/security/main.tf"
security_vars="$REPO_ROOT/terraform/modules/security/variables.tf"
root_main="$REPO_ROOT/terraform/main.tf"

legacy_count=$(grep -RE 'https://(argocd|backstage)\.\$\{var\.customer_name\}\.com' "$security_main" | wc -l | tr -d ' ')
assert "legacy customer-name callback URI is absent" "$legacy_count" "0"

portal_uri_count=$(grep -c 'https://${var.portal_domain_name}/api/auth/microsoft/handler/frame' "$security_main" || true)
assert "Backstage callback uses portal_domain_name" "$portal_uri_count" "1"

argocd_uri_count=$(grep -c 'https://argocd.${var.portal_domain_name}/api/dex/callback' "$security_main" || true)
assert "ArgoCD callback uses portal_domain_name" "$argocd_uri_count" "1"

var_count=$(grep -c 'variable "portal_domain_name"' "$security_vars" || true)
assert "security module declares portal_domain_name" "$var_count" "1"

root_count=$(grep -c 'portal_domain_name  = var.domain_name' "$root_main" || true)
assert "root module passes var.domain_name" "$root_count" "1"

echo

echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
