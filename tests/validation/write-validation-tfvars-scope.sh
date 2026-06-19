#!/usr/bin/env bash
# =============================================================================
# Validation-scope tfvars tests for scripts/azure-validation-run.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/azure-validation-run.sh"

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

run_scope() {
  local scope="$1"
  local run_id="unit-tfvars-${scope}-$$"
  local run_dir="$REPO_ROOT/runs/azure-validation/$run_id"
  local args=(
    --phase write-validation-tfvars
    --run-id "$run_id"
    --customer-name contoso
    --environment prod
    --domain-name contoso.example.com
    --subscription-id 00000000-0000-0000-0000-000000000000
    --tenant-id 11111111-1111-1111-1111-111111111111
    --validation-scope "$scope"
  )
  if [[ "$scope" == "platform" || "$scope" == "full" ]]; then
    args+=(--admin-group-id 22222222-2222-2222-2222-222222222222 --github-org contoso)
  fi
  if [[ "$scope" == "full" ]]; then
    TF_VAR_github_token=ghp_testtoken "$SCRIPT" "${args[@]}" >/dev/null 2>&1
  else
    "$SCRIPT" "${args[@]}" >/dev/null 2>&1
  fi
  ec=$?
  assert "$scope tfvars phase exit code" "$ec" "0"
  tfvars="$run_dir/validation.auto.tfvars"
  assert "$scope tfvars exists" "$([[ -f $tfvars ]] && echo yes || echo no)" "yes"
  if [[ -f "$tfvars" ]]; then
    assert_contains "$scope records validation scope" "$tfvars" "Validation scope: $scope"
    case "$scope" in
      infra)
        assert_contains "infra disables argocd" "$tfvars" '^enable_argocd[[:space:]]+= false$'
        assert_contains "infra disables agent api" "$tfvars" '^enable_agent_api[[:space:]]+= false$'
        ;;
      nogithub)
        assert_contains "nogithub enables argocd" "$tfvars" '^enable_argocd[[:space:]]+= true$'
        assert_contains "nogithub enables agent api impact" "$tfvars" '^enable_agent_api_impact[[:space:]]+= true$'
        ;;
      platform)
        assert_contains "platform requires github org" "$tfvars" '^github_org[[:space:]]+= "contoso"$'
        assert_contains "platform disables AI runtime" "$tfvars" '^enable_agent_api[[:space:]]+= false$'
        ;;
      full)
        assert_contains "full enables github runners" "$tfvars" '^enable_github_runners[[:space:]]+= true$'
        assert_contains "full enables mcp ecosystem" "$tfvars" '^enable_mcp_ecosystem[[:space:]]+= true$'
        ;;
    esac
  fi
  rm -rf "$run_dir"
}

run_scope infra
run_scope nogithub
run_scope platform
run_scope full

echo

echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
