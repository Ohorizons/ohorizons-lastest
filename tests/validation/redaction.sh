#!/usr/bin/env bash
# =============================================================================
# Redaction tests for scripts/azure-validation-run.sh
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

assert_file_not_contains() {
  local desc="$1" file="$2" pattern="$3"
  if grep -E "$pattern" "$file" >/dev/null 2>&1; then
    echo "  FAIL  $desc"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  fi
}

if [[ ! -x "$SCRIPT" ]]; then
  echo "  FAIL  script is not executable: $SCRIPT"
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

sample_tf_output="$workdir/terraform-output.json"
sanitized_tf_output="$workdir/terraform-output.sanitized.json"
cat > "$sample_tf_output" <<'JSON'
{
  "kube_config": {
    "sensitive": true,
    "type": "string",
    "value": "apiVersion: v1\nclusters:\n- cluster:\n    certificate-authority-data: SECRET_CA_DATA"
  },
  "postgres_password": {
    "sensitive": true,
    "type": "string",
    "value": "SuperSecretPassword123!"
  },
  "resource_group_id": {
    "sensitive": false,
    "type": "string",
    "value": "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-contoso-prod"
  },
  "next_steps": {
    "sensitive": false,
    "type": "string",
    "value": "az aks get-credentials --resource-group rg-contoso-prod --name aks-contoso-prod"
  }
}
JSON

"$SCRIPT" --phase redact-artifact --input "$sample_tf_output" --output "$sanitized_tf_output" --artifact-type terraform-output >/dev/null 2>&1
ec=$?
assert "redact terraform output exit code" "$ec" "0"
assert "sanitized terraform output exists" "$([[ -f $sanitized_tf_output ]] && echo yes || echo no)" "yes"
if [[ -f "$sanitized_tf_output" ]]; then
  assert_file_not_contains "kube_config content is removed" "$sanitized_tf_output" "SECRET_CA_DATA|apiVersion: v1"
  assert_file_not_contains "password is removed" "$sanitized_tf_output" "SuperSecretPassword123"
  assert_file_not_contains "subscription id is masked" "$sanitized_tf_output" "11111111-2222-3333-4444-555555555555"
  python3 -m json.tool "$sanitized_tf_output" >/dev/null 2>&1
  assert "sanitized terraform output is valid JSON" "$?" "0"
fi

sample_plan="$workdir/tfplan.json"
sanitized_plan="$workdir/tfplan.sanitized.json"
cat > "$sample_plan" <<'JSON'
{
  "resource_changes": [
    {
      "address": "module.databases.random_password.postgresql[0]",
      "type": "random_password",
      "change": {
        "actions": ["create"],
        "after": {
          "result": "GeneratedSecret456!",
          "bcrypt_hash": "$2a$10$hash"
        }
      }
    },
    {
      "address": "azurerm_resource_group.main",
      "type": "azurerm_resource_group",
      "change": {
        "actions": ["no-op"],
        "after": {
          "id": "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-contoso-prod"
        }
      }
    }
  ]
}
JSON

"$SCRIPT" --phase redact-artifact --input "$sample_plan" --output "$sanitized_plan" --artifact-type terraform-plan >/dev/null 2>&1
ec=$?
assert "redact terraform plan exit code" "$ec" "0"
assert "sanitized terraform plan exists" "$([[ -f $sanitized_plan ]] && echo yes || echo no)" "yes"
if [[ -f "$sanitized_plan" ]]; then
  assert_file_not_contains "random password result is removed" "$sanitized_plan" "GeneratedSecret456"
  assert_file_not_contains "bcrypt hash is removed" "$sanitized_plan" '\$2a\$10\$hash'
  assert_file_not_contains "plan subscription id is masked" "$sanitized_plan" "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  python3 -m json.tool "$sanitized_plan" >/dev/null 2>&1
  assert "sanitized plan is valid JSON" "$?" "0"
fi

echo
echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
