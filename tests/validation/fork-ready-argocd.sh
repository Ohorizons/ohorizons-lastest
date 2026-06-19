#!/usr/bin/env bash
# =============================================================================
# Static fork-readiness checks for ArgoCD repository URLs
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

patterns='open-horizons-platform\.git|ohorizons-lastest\.git|gitops-config\.git|golden-paths\.git|platform-gitops\.git'
scan_paths=(
  "$REPO_ROOT/argocd"
  "$REPO_ROOT/deploy/helm/argocd"
)

matches="$(grep -RE "$patterns" "${scan_paths[@]}" 2>/dev/null || true)"
count="$(printf '%s' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')"
assert "ArgoCD repo URLs avoid fixed repository names" "$count" "0"

if [[ "$count" != "0" ]]; then
  printf '%s\n' "$matches"
fi

echo

echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
