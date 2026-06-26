#!/usr/bin/env bash
# =============================================================================
# Scope-aware required component tests for scripts/azure-validation-run.sh
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

make_common_stubs() {
  local bin_dir="$1"
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
if [[ "$1 $2" == "aks get-credentials" ]]; then exit 0; fi
if [[ "$1 $2 $3" == "cognitiveservices account list" ]]; then echo '[]'; exit 0; fi
if [[ "$1 $2 $3" == "search service list" ]]; then echo '[]'; exit 0; fi
echo "az stub: $*" >&2
exit 1
SH
  chmod +x "$bin_dir/terraform" "$bin_dir/az"
}

make_h2_missing_argocd_kubectl() {
  local bin_dir="$1"
  cat > "$bin_dir/kubectl" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == "get namespace" ]]; then
  ns="$3"
  if [[ "$ns" == "argocd" ]]; then echo 'Error from server (NotFound): namespaces "argocd" not found' >&2; exit 1; fi
  echo '{"metadata":{"name":"'"$ns"'"}}'
  exit 0
fi
if [[ "$1 $2" == "get pods" ]]; then
  ns=""
  for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "-n" ]]; then j=$((i+1)); ns="${!j}"; fi
  done
  if [[ "$ns" == "argocd" ]]; then exit 0; fi
  echo 'NAME READY STATUS'
  echo "${ns}-pod 1/1 Running"
  exit 0
fi
echo "kubectl stub: $*" >&2
exit 1
SH
  chmod +x "$bin_dir/kubectl"
}

make_h3_missing_mcp_kubectl() {
  local bin_dir="$1"
  cat > "$bin_dir/kubectl" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == "get pods" ]]; then
  echo 'NAME READY STATUS'
  echo 'open-horizons-agent-api-abc 1/1 Running'
  echo 'open-horizons-agent-api-impact-def 1/1 Running'
  exit 0
fi
if [[ "$1 $2" == "get svc" ]]; then
  echo 'NAME TYPE CLUSTER-IP PORT(S)'
  echo 'open-horizons-agent-api ClusterIP 10.1.1.1 8008/TCP'
  echo 'open-horizons-agent-api-impact ClusterIP 10.1.1.2 8011/TCP'
  exit 0
fi
echo "kubectl stub: $*" >&2
exit 1
SH
  chmod +x "$bin_dir/kubectl"
}

run_h2_case() {
  local workdir bin_dir run_id status_file failed_check
  workdir="$(mktemp -d)"
  bin_dir="$workdir/bin"
  mkdir -p "$bin_dir"
  make_common_stubs "$bin_dir"
  make_h2_missing_argocd_kubectl "$bin_dir"
  run_id="unit-h2-missing-$$"
  status_file="$REPO_ROOT/runs/azure-validation/$run_id/status.json"
  PATH="$bin_dir:$PATH" "$SCRIPT" --phase validate-h2 --run-id "$run_id" --customer-name contoso --environment prod --validation-scope nogithub >/dev/null 2>&1
  ec=$?
  assert "missing H2 required component exits 1" "$ec" "1"
  failed_check="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["failed_check"])' "$status_file")"
  assert "missing H2 failed_check" "$failed_check" "missing_required_components"
  rm -rf "$workdir" "$REPO_ROOT/runs/azure-validation/$run_id"
}

run_h3_case() {
  local workdir bin_dir run_id status_file failed_check
  workdir="$(mktemp -d)"
  bin_dir="$workdir/bin"
  mkdir -p "$bin_dir"
  make_common_stubs "$bin_dir"
  make_h3_missing_mcp_kubectl "$bin_dir"
  run_id="unit-h3-missing-$$"
  status_file="$REPO_ROOT/runs/azure-validation/$run_id/status.json"
  PATH="$bin_dir:$PATH" "$SCRIPT" --phase validate-h3 --run-id "$run_id" --customer-name contoso --environment prod --validation-scope nogithub >/dev/null 2>&1
  ec=$?
  assert "missing H3 required component exits 1" "$ec" "1"
  failed_check="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["failed_check"])' "$status_file")"
  assert "missing H3 failed_check" "$failed_check" "missing_required_components"
  rm -rf "$workdir" "$REPO_ROOT/runs/azure-validation/$run_id"
}

run_h2_case
run_h3_case

echo

echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
