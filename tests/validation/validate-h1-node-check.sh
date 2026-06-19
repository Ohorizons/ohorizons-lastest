#!/usr/bin/env bash
# =============================================================================
# H1 node readiness tests for scripts/azure-validation-run.sh
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

make_stubs() {
  local bin_dir="$1" nodes_file="$2"
  cat > "$bin_dir/terraform" <<'SH'
#!/usr/bin/env bash
case "$*" in
  *"output -raw resource_group_name"*) echo "rg-contoso-prod" ;;
  *"output -raw aks_cluster_name"*) echo "aks-contoso-prod" ;;
  *) echo "terraform stub: $*" >&2; exit 1 ;;
esac
SH
  cat > "$bin_dir/az" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == "aks get-credentials" ]]; then
  exit 0
fi
echo "az stub: $*" >&2
exit 1
SH
  cat > "$bin_dir/kubectl" <<SH
#!/usr/bin/env bash
if [[ "\$1 \$2" == "get nodes" && "\$3 \$4" == "-o json" ]]; then
  cat "$nodes_file"
  exit 0
fi
if [[ "\$1 \$2" == "get pods" ]]; then
  echo "NAMESPACE NAME READY STATUS"
  exit 0
fi
if [[ "\$1 \$2" == "get events" ]]; then
  echo "LAST SEEN TYPE REASON"
  exit 0
fi
echo "kubectl stub: \$*" >&2
exit 1
SH
  chmod +x "$bin_dir/terraform" "$bin_dir/az" "$bin_dir/kubectl"
}

run_case() {
  local name="$1" nodes_json="$2" expected_exit="$3" expected_status="$4"
  local workdir bin_dir nodes_file run_id status_file
  workdir="$(mktemp -d)"
  bin_dir="$workdir/bin"
  nodes_file="$workdir/nodes.json"
  mkdir -p "$bin_dir"
  printf '%s' "$nodes_json" > "$nodes_file"
  make_stubs "$bin_dir" "$nodes_file"
  run_id="unit-${name}-$$"
  status_file="$REPO_ROOT/runs/azure-validation/$run_id/status.json"
  PATH="$bin_dir:$PATH" "$SCRIPT" --phase validate-h1 --run-id "$run_id" --customer-name contoso --environment prod >/dev/null 2>&1
  ec=$?
  assert "$name exit code" "$ec" "$expected_exit"
  if [[ -f "$status_file" ]]; then
    status="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status"])' "$status_file")"
    assert "$name status" "$status" "$expected_status"
  else
    assert "$name status file exists" "no" "yes"
  fi
  rm -rf "$workdir" "$REPO_ROOT/runs/azure-validation/$run_id"
}

ready_nodes='{"items":[{"metadata":{"name":"node-1"},"status":{"conditions":[{"type":"Ready","status":"True"}]}},{"metadata":{"name":"node-2"},"status":{"conditions":[{"type":"Ready","status":"True"}]}}]}'
not_ready_nodes='{"items":[{"metadata":{"name":"node-1"},"status":{"conditions":[{"type":"Ready","status":"False"}]}}]}'
empty_nodes='{"items":[]}'

run_case "ready-nodes" "$ready_nodes" "0" "passed"
run_case "not-ready-nodes" "$not_ready_nodes" "1" "failed"
run_case "empty-nodes" "$empty_nodes" "1" "failed"

echo
echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
