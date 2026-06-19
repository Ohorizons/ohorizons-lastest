#!/usr/bin/env bash
# =============================================================================
# Resume checkpoint tests for scripts/deploy-full.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOY="$REPO_ROOT/scripts/deploy-full.sh"
CHECKPOINT="$REPO_ROOT/.deploy-checkpoint"

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

backup="$(mktemp)"
if [[ -f "$CHECKPOINT" ]]; then cp "$CHECKPOINT" "$backup"; fi
restore() {
  if [[ -s "$backup" ]]; then
    cp "$backup" "$CHECKPOINT"
  else
    rm -f "$CHECKPOINT"
  fi
  rm -f "$backup"
}
trap restore EXIT

cat > "$CHECKPOINT" <<'JSON'
{
  "last_phase": 9,
  "environment": "dev",
  "horizon": "all",
  "updated_at": "2026-06-19T00:00:00Z"
}
JSON

"$DEPLOY" --environment dev --horizon all --dry-run --resume --skip-prerequisites >/tmp/openhorizons-resume-match.out 2>&1
ec=$?
assert "matching checkpoint resume exits 0" "$ec" "0"

"$DEPLOY" --environment prod --horizon all --dry-run --resume --skip-prerequisites >/tmp/openhorizons-resume-env-mismatch.out 2>&1
ec=$?
assert "environment mismatch resume exits 1" "$ec" "1"
if grep -q "Checkpoint environment" /tmp/openhorizons-resume-env-mismatch.out; then
  echo "  PASS  environment mismatch explains checkpoint conflict"
  PASS=$((PASS + 1))
else
  echo "  FAIL  environment mismatch explains checkpoint conflict"
  FAIL=$((FAIL + 1))
fi

"$DEPLOY" --environment dev --horizon h2 --dry-run --resume --skip-prerequisites >/tmp/openhorizons-resume-horizon-mismatch.out 2>&1
ec=$?
assert "horizon mismatch resume exits 1" "$ec" "1"
if grep -q "Checkpoint horizon" /tmp/openhorizons-resume-horizon-mismatch.out; then
  echo "  PASS  horizon mismatch explains checkpoint conflict"
  PASS=$((PASS + 1))
else
  echo "  FAIL  horizon mismatch explains checkpoint conflict"
  FAIL=$((FAIL + 1))
fi

printf '4\n' > "$CHECKPOINT"
"$DEPLOY" --environment dev --horizon all --dry-run --resume --skip-prerequisites >/tmp/openhorizons-resume-legacy.out 2>&1
ec=$?
assert "legacy numeric checkpoint exits 1" "$ec" "1"
if grep -q "Legacy checkpoint" /tmp/openhorizons-resume-legacy.out; then
  echo "  PASS  legacy checkpoint explains safe resume block"
  PASS=$((PASS + 1))
else
  echo "  FAIL  legacy checkpoint explains safe resume block"
  FAIL=$((FAIL + 1))
fi

rm -f /tmp/openhorizons-resume-match.out /tmp/openhorizons-resume-env-mismatch.out /tmp/openhorizons-resume-horizon-mismatch.out /tmp/openhorizons-resume-legacy.out

echo

echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
