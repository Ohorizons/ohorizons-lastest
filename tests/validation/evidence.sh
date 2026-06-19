#!/usr/bin/env bash
# =============================================================================
# Evidence bundle tests for scripts/azure-validation-run.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/azure-validation-run.sh"
RUN_ID="unit-evidence-$$"
RUN_DIR="$REPO_ROOT/runs/azure-validation/$RUN_ID"

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

trap 'rm -rf "$RUN_DIR"' EXIT
mkdir -p "$RUN_DIR/01-plan" "$RUN_DIR/07-inventory" "$RUN_DIR/08-docs"
cat > "$RUN_DIR/status.json" <<'JSON'
{"run_id":"unit-evidence","phase":"docs","status":"passed"}
JSON
printf '[]\n' > "$RUN_DIR/errors.json"
printf '# Summary\n\n- validation passed\n' > "$RUN_DIR/summary.md"
printf '# Fixes\n' > "$RUN_DIR/fixes.md"
printf '{"safe":"value"}\n' > "$RUN_DIR/01-plan/tfplan.sanitized.json"
printf '{"safe":"output"}\n' > "$RUN_DIR/07-inventory/terraform-output.sanitized.json"
printf '{"safe":"resources"}\n' > "$RUN_DIR/07-inventory/resources-summary.sanitized.json"
printf '# Resource Inventory\n' > "$RUN_DIR/08-docs/resource-inventory.md"
printf '{"kube_config":"SECRET_SHOULD_NOT_BE_BUNDLED"}\n' > "$RUN_DIR/07-inventory/terraform-output.json"

"$SCRIPT" --phase evidence --run-id "$RUN_ID" >/tmp/openhorizons-evidence.out 2>&1
ec=$?
assert "evidence phase exit code" "$ec" "0"
assert "evidence manifest exists" "$([[ -f $RUN_DIR/09-evidence/evidence-manifest.json ]] && echo yes || echo no)" "yes"
assert "evidence bundle exists" "$([[ -f $RUN_DIR/09-evidence/evidence.tar.gz ]] && echo yes || echo no)" "yes"

if [[ -d "$RUN_DIR/09-evidence/files" ]]; then
  if grep -R "SECRET_SHOULD_NOT_BE_BUNDLED" "$RUN_DIR/09-evidence/files" >/dev/null 2>&1; then
    echo "  FAIL  raw secret was bundled"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS  raw secret was not bundled"
    PASS=$((PASS + 1))
  fi
else
  assert "evidence files dir exists" "no" "yes"
fi

python3 -m json.tool "$RUN_DIR/09-evidence/evidence-manifest.json" >/dev/null 2>&1
assert "evidence manifest is valid JSON" "$?" "0"
rm -f /tmp/openhorizons-evidence.out

echo

echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
