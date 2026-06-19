#!/usr/bin/env bash
# =============================================================================
# Render test for AUTH_PROVIDER=entra + GitHub EMU
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RENDER="$REPO_ROOT/scripts/render-k8s.sh"

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

assert_contains() {
  local desc="$1" file="$2" pattern="$3"
  if grep -E "$pattern" "$file" >/dev/null 2>&1; then
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $desc"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local desc="$1" file="$2" pattern="$3"
  if grep -E "$pattern" "$file" >/dev/null 2>&1; then
    echo "  FAIL  $desc"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  fi
}

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

env_file="$workdir/entra-emu.env"
output_file="$workdir/render.out"
cat > "$env_file" <<'ENV'
PLATFORM_NAME=openhorizons
DOMAIN=portal.contoso.example.com
ADMIN_EMAIL=admin@contoso.example.com
ORG_DISPLAY_NAME="Contoso Platform"
GITHUB_ORG=contoso
GITHUB_REPO=open-horizons-platform
AUTH_PROVIDER=entra
GITHUB_IDENTITY_MODE=enterprise-managed-users
GITHUB_ENTERPRISE_SLUG=contoso-enterprise
IMAGE_TAG=v7.2.4
BACKSTAGE_IMAGE=ghcr.io/ohorizons/ohorizons-backstage
AGENT_API_IMAGE=ghcr.io/ohorizons/ohorizons-agent-api
AGENT_API_IMPACT_IMAGE=ghcr.io/ohorizons/ohorizons-agent-api-impact
MCP_ECOSYSTEM_IMAGE=ghcr.io/ohorizons/mcp-ecosystem
AZURE_OPENAI_DEPLOYMENT=gpt-5.1
ENV

bash "$RENDER" --env-file "$env_file" --dry-run > "$output_file" 2>&1
ec=$?
assert "render-k8s Entra EMU dry-run exit code" "$ec" "0"
assert_contains "render summary shows Entra auth" "$output_file" "Auth:[[:space:]]+.*entra"
assert_contains "render summary shows EMU identity" "$output_file" "Identity:[[:space:]]+.*enterprise-managed-users"
assert_contains "rendered config contains Microsoft provider" "$output_file" "microsoft:"
assert_contains "rendered config contains Entra tenant variable" "$output_file" 'tenantId: \$\{ENTRA_TENANT_ID\}'
assert_contains "secrets checklist includes Entra client id" "$output_file" "ENTRA_CLIENT_ID"
assert_contains "secrets checklist explains GitHub EMU technical integration" "$output_file" "GitHub EMU mode"
assert_not_contains "rendered auth block does not include GitHub auth provider" "$output_file" "clientId: \$\{GITHUB_APP_CLIENT_ID\}"

echo

echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
