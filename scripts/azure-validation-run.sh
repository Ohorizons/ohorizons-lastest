#!/usr/bin/env bash
# =============================================================================
# azure-validation-run.sh — Agent-supervised Azure validation orchestrator
# =============================================================================
#
# Runs deterministic Azure/Terraform/Kubernetes validation phases and writes
# machine-readable artifacts for Copilot agents under runs/azure-validation/.
#
# Safety model:
#   - plan/preflight/validate/inventory/docs are safe and non-destructive
#   - apply requires --confirm-apply
#   - destroy requires --confirm-destroy
#   - resource group deletion requires --delete-rg plus --confirm-destroy
#
# Usage examples:
#   scripts/azure-validation-run.sh --phase preflight --customer-name <client-name> --subscription-id <id>
#   scripts/azure-validation-run.sh --phase plan --customer-name <client-name> --domain-name <client-domain> --github-org <client-github-org>
#   scripts/azure-validation-run.sh --phase apply --run-id <run-id> --confirm-apply
#   scripts/azure-validation-run.sh --phase validate-all --run-id <run-id>
#   scripts/azure-validation-run.sh --phase destroy --run-id <run-id> --confirm-destroy --destroy-confirm-text <client-name>-prod
#
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/terraform"
RUNS_ROOT="$PROJECT_DIR/runs/azure-validation"

PHASE="preflight"
RUN_ID=""
CUSTOMER_NAME=""
ENVIRONMENT="prod"
LOCATION="eastus2"
DR_LOCATION="centralus"
DOMAIN_NAME=""
SUBSCRIPTION_ID="${TF_VAR_azure_subscription_id:-}"
TENANT_ID="${TF_VAR_azure_tenant_id:-}"
ADMIN_GROUP_ID="${TF_VAR_admin_group_id:-}"
GITHUB_ORG="${TF_VAR_github_org:-}"
BASE_TFVARS="$TERRAFORM_DIR/environments/production.tfvars"
REGISTER_PROVIDERS=true
CONFIRM_APPLY=false
CONFIRM_DESTROY=false
DESTROY_CONFIRM_TEXT=""
DELETE_RG=false
AUTO_APPROVE=false

usage() {
  cat <<'USAGE'
Azure validation run orchestrator for Open Horizons.

Runs deterministic Azure/Terraform/Kubernetes validation phases and writes
machine-readable artifacts for Copilot agents under runs/azure-validation/.

Safety model:
  - preflight/plan/validate/inventory/docs are safe and non-destructive
  - apply requires --confirm-apply
  - destroy requires --confirm-destroy --destroy-confirm-text <customer>-<environment>

Usage:
  scripts/azure-validation-run.sh --phase preflight --customer-name <client-name> --environment prod --location eastus2
  scripts/azure-validation-run.sh --phase plan --run-id <run-id>
  scripts/azure-validation-run.sh --phase apply --run-id <run-id> --confirm-apply
  scripts/azure-validation-run.sh --phase validate-all --run-id <run-id>
  scripts/azure-validation-run.sh --phase destroy --run-id <run-id> --confirm-destroy --destroy-confirm-text <client-name>-prod

Options:
  --phase <name>              preflight | plan | apply | validate-h1 | validate-h2 | validate-h3 | validate-all | inventory | docs | destroy | all-safe
  --run-id <id>               Existing or desired run id (default: <customer>-<env>-<UTC timestamp>)
  --customer-name <name>      Required: real client/project short name (lowercase, 3-20 chars)
  --environment <env>         Terraform environment override (default: prod)
  --location <region>         Primary Azure region (default: eastus2)
  --dr-location <region>      DR region (default: centralus)
  --domain-name <domain>      Required for plan/apply: real client domain or approved internal domain
  --subscription-id <id>      Azure subscription id
  --tenant-id <id>            Azure tenant id
  --admin-group-id <id>       Entra admin group object id
  --github-org <org>          GitHub org
  --base-tfvars <path>        Base tfvars (default: terraform/environments/production.tfvars)
  --skip-provider-registration Do not register missing Azure providers in preflight
  --confirm-apply            Required for phase apply
  --confirm-destroy          Required for phase destroy
  --destroy-confirm-text <t> Required with --confirm-destroy; must equal <customer>-<environment>
  --delete-rg                After terraform destroy, delete empty RG if still present
  --auto-approve             Pass -auto-approve to terraform apply/destroy after confirm flag
  --help                     Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --run-id) RUN_ID="$2"; shift 2 ;;
    --customer-name) CUSTOMER_NAME="$2"; shift 2 ;;
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --location) LOCATION="$2"; shift 2 ;;
    --dr-location) DR_LOCATION="$2"; shift 2 ;;
    --domain-name) DOMAIN_NAME="$2"; shift 2 ;;
    --subscription-id) SUBSCRIPTION_ID="$2"; shift 2 ;;
    --tenant-id) TENANT_ID="$2"; shift 2 ;;
    --admin-group-id) ADMIN_GROUP_ID="$2"; shift 2 ;;
    --github-org) GITHUB_ORG="$2"; shift 2 ;;
    --base-tfvars) BASE_TFVARS="$2"; shift 2 ;;
    --skip-provider-registration) REGISTER_PROVIDERS=false; shift ;;
    --confirm-apply) CONFIRM_APPLY=true; shift ;;
    --confirm-destroy) CONFIRM_DESTROY=true; shift ;;
    --destroy-confirm-text) DESTROY_CONFIRM_TEXT="$2"; shift 2 ;;
    --delete-rg) DELETE_RG=true; shift ;;
    --auto-approve) AUTO_APPROVE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$RUN_ID" ]]; then
  if [[ -z "$CUSTOMER_NAME" ]]; then
    echo "Error: --customer-name is required and must be the real client/project short name." >&2
    exit 2
  fi
  RUN_ID="${CUSTOMER_NAME}-${ENVIRONMENT}-$(date -u +%Y%m%dT%H%M%SZ)"
fi

RUN_DIR="$RUNS_ROOT/$RUN_ID"
mkdir -p "$RUN_DIR"

STATUS_FILE="$RUN_DIR/status.json"
ERRORS_FILE="$RUN_DIR/errors.json"
SUMMARY_FILE="$RUN_DIR/summary.md"
FIXES_FILE="$RUN_DIR/fixes.md"
OVERRIDE_TFVARS="$RUN_DIR/validation.auto.tfvars"
PLAN_FILE="$RUN_DIR/validation.tfplan"
PLAN_JSON="$RUN_DIR/tfplan.json"
RESOURCE_GROUP="rg-${CUSTOMER_NAME}-${ENVIRONMENT}"

require_customer_name() {
  if [[ -z "$CUSTOMER_NAME" ]]; then
    write_error "$PHASE" "missing_customer_name" "deploy" "--customer-name is required. Use the real client/project short name." ""
    write_status "$PHASE" "failed" "missing_customer_name" "deploy" false
    exit 2
  fi
  if ! [[ "$CUSTOMER_NAME" =~ ^[a-z][a-z0-9-]{1,18}[a-z0-9]$ ]]; then
    write_error "$PHASE" "invalid_customer_name" "deploy" "--customer-name must match Terraform validation: lowercase alphanumeric/hyphen, 3-20 chars." ""
    write_status "$PHASE" "failed" "invalid_customer_name" "deploy" false
    exit 2
  fi
}

load_azure_context_defaults() {
  if command -v az >/dev/null 2>&1 && az account show -o json >/tmp/oh-az-account-context.json 2>/dev/null; then
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
      SUBSCRIPTION_ID="$(jq -r '.id // empty' /tmp/oh-az-account-context.json 2>/dev/null || true)"
    fi
    if [[ -z "$TENANT_ID" ]]; then
      TENANT_ID="$(jq -r '.tenantId // empty' /tmp/oh-az-account-context.json 2>/dev/null || true)"
    fi
  fi
}

require_plan_inputs() {
  require_customer_name
  load_azure_context_defaults
  local missing=()
  [[ -n "$DOMAIN_NAME" ]] || missing+=("--domain-name <client-domain>")
  [[ -n "$SUBSCRIPTION_ID" ]] || missing+=("--subscription-id <subscription-id> or TF_VAR_azure_subscription_id")
  [[ -n "$TENANT_ID" ]] || missing+=("--tenant-id <tenant-id> or TF_VAR_azure_tenant_id")
  [[ -n "$ADMIN_GROUP_ID" ]] || missing+=("--admin-group-id <entra-group-object-id> or TF_VAR_admin_group_id")
  [[ -n "$GITHUB_ORG" ]] || missing+=("--github-org <client-github-org> or TF_VAR_github_org")
  [[ -n "${TF_VAR_github_token:-}" ]] || missing+=("TF_VAR_github_token (export in terminal; do not send through chat)")

  if [[ "${#missing[@]}" -gt 0 ]]; then
    local message="Missing required real client inputs: ${missing[*]}"
    write_error "$PHASE" "missing_client_inputs" "deploy" "$message" ""
    write_status "$PHASE" "failed" "missing_client_inputs" "deploy" false
    printf '%s\n' "$message" >&2
    exit 2
  fi
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}

write_status() {
  local phase_name="$1" phase_status="$2" failed_check="${3:-}" owner_agent="${4:-deploy}" safe_to_retry="${5:-true}"
  cat > "$STATUS_FILE" <<JSON
{
  "run_id": "$RUN_ID",
  "phase": "$phase_name",
  "status": "$phase_status",
  "failed_check": "$failed_check",
  "owner_agent": "$owner_agent",
  "safe_to_retry": $safe_to_retry,
  "run_dir": "$RUN_DIR",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
}

write_error() {
  local phase_name="$1" code="$2" owner_agent="$3" message="$4" log_file="${5:-}"
  local escaped_message escaped_log
  escaped_message="$(printf '%s' "$message" | json_escape)"
  escaped_log="$(printf '%s' "$log_file" | json_escape)"
  cat > "$ERRORS_FILE" <<JSON
[
  {
    "phase": "$phase_name",
    "code": "$code",
    "owner_agent": "$owner_agent",
    "message": "$escaped_message",
    "log_file": "$escaped_log",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
]
JSON
}

clear_errors() {
  printf '[]\n' > "$ERRORS_FILE"
}

append_summary() {
  local text="$1"
  if [[ ! -f "$SUMMARY_FILE" ]]; then
    cat > "$SUMMARY_FILE" <<MD
# Azure Validation Run: $RUN_ID

| Field | Value |
| --- | --- |
| Customer | $CUSTOMER_NAME |
| Environment | $ENVIRONMENT |
| Location | $LOCATION |
| DR Location | $DR_LOCATION |
| Resource Group | $RESOURCE_GROUP |
| Started/Updated | $(date -u +%Y-%m-%dT%H:%M:%SZ) |

## Timeline

MD
  fi
  printf -- '- %s — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$text" >> "$SUMMARY_FILE"
}

ensure_fixes_file() {
  if [[ ! -f "$FIXES_FILE" ]]; then
    cat > "$FIXES_FILE" <<MD
# Fixes and Remediations: $RUN_ID

This file is intentionally append-only during validation runs. Agents should record root cause, files changed, validation commands, retry result, and any remaining risk.

MD
  fi
}

run_logged() {
  local phase_dir="$1" name="$2"; shift 2
  mkdir -p "$phase_dir"
  local log_file="$phase_dir/${name}.log"
  append_summary "Running ${name}"
  set +e
  "$@" > "$log_file" 2>&1
  local exit_code=$?
  set -e
  if [[ "$exit_code" -ne 0 ]]; then
    write_error "$PHASE" "${name}_failed" "deploy" "Command failed: $*" "$log_file"
    write_status "$PHASE" "failed" "${name}" "deploy" true
    echo "Command failed: $*" >&2
    echo "Log: $log_file" >&2
    tail -80 "$log_file" >&2 || true
    exit "$exit_code"
  fi
  echo "$log_file"
}

write_validation_tfvars() {
  require_plan_inputs
  cat > "$OVERRIDE_TFVARS" <<EOF_TFVARS
# Generated by scripts/azure-validation-run.sh for run $RUN_ID
# Non-secret validation overrides. Do not commit run artifacts.
customer_name         = "$CUSTOMER_NAME"
environment           = "$ENVIRONMENT"
location              = "$LOCATION"
dr_location           = "$DR_LOCATION"
domain_name           = "$DOMAIN_NAME"
deployment_mode       = "enterprise"

enable_container_registry = true
enable_databases          = true
enable_defender           = true
enable_purview            = true
enable_argocd             = true
enable_external_secrets   = true
enable_observability      = true
enable_github_runners     = true
enable_cost_management    = true
enable_ai_foundry         = true
enable_foundry_agents     = true
enable_disaster_recovery  = true
enable_ai_chat_plugin     = true
enable_agent_api          = true
enable_agent_api_impact   = true
enable_agent_api_maf      = false
enable_agent_api_sk       = false
enable_mcp_ecosystem      = true
EOF_TFVARS

  [[ -n "$SUBSCRIPTION_ID" ]] && printf 'azure_subscription_id = "%s"\n' "$SUBSCRIPTION_ID" >> "$OVERRIDE_TFVARS"
  [[ -n "$TENANT_ID" ]] && printf 'azure_tenant_id       = "%s"\n' "$TENANT_ID" >> "$OVERRIDE_TFVARS"
  [[ -n "$ADMIN_GROUP_ID" ]] && printf 'admin_group_id        = "%s"\n' "$ADMIN_GROUP_ID" >> "$OVERRIDE_TFVARS"
  [[ -n "$GITHUB_ORG" ]] && printf 'github_org            = "%s"\n' "$GITHUB_ORG" >> "$OVERRIDE_TFVARS"
}

terraform_var_files() {
  printf '%s\n' "-var-file=$BASE_TFVARS" "-var-file=$OVERRIDE_TFVARS"
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    write_error "$PHASE" "missing_tool" "deploy" "Required tool not found: $tool" ""
    write_status "$PHASE" "failed" "missing_tool_${tool}" "deploy" false
    echo "Required tool not found: $tool" >&2
    exit 1
  fi
}

phase_preflight() {
  PHASE="preflight"
  local phase_dir="$RUN_DIR/00-preflight"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  require_customer_name
  load_azure_context_defaults
  append_summary "Preflight started"

  for tool in az terraform kubectl jq; do require_tool "$tool"; done

  if [[ -n "$SUBSCRIPTION_ID" ]]; then
    run_logged "$phase_dir" "az-account-set" az account set --subscription "$SUBSCRIPTION_ID" >/dev/null
  fi

  run_logged "$phase_dir" "az-account-show" az account show -o json >/dev/null
  az account show -o json > "$phase_dir/account.json"

  local account_sub account_tenant
  account_sub="$(jq -r '.id // empty' "$phase_dir/account.json")"
  account_tenant="$(jq -r '.tenantId // empty' "$phase_dir/account.json")"
  if [[ -n "$SUBSCRIPTION_ID" && "$account_sub" != "$SUBSCRIPTION_ID" ]]; then
    write_error "$PHASE" "subscription_mismatch" "azure-portal-deploy" "Active subscription does not match requested subscription." "$phase_dir/account.json"
    write_status "$PHASE" "failed" "subscription_mismatch" "azure-portal-deploy" true
    exit 1
  fi
  if [[ -n "$TENANT_ID" && "$account_tenant" != "$TENANT_ID" ]]; then
    write_error "$PHASE" "tenant_mismatch" "azure-portal-deploy" "Active tenant does not match requested tenant." "$phase_dir/account.json"
    write_status "$PHASE" "failed" "tenant_mismatch" "azure-portal-deploy" true
    exit 1
  fi

  local providers=(
    Microsoft.ContainerService
    Microsoft.ContainerRegistry
    Microsoft.Cache
    Microsoft.DBforPostgreSQL
    Microsoft.CognitiveServices
    Microsoft.Search
    Microsoft.KeyVault
    Microsoft.ManagedIdentity
    Microsoft.Network
    Microsoft.Monitor
    Microsoft.Security
    Microsoft.Insights
  )
  printf '{\n' > "$phase_dir/providers.json"
  local first=true
  for provider in "${providers[@]}"; do
    local state
    state="$(az provider show --namespace "$provider" --query registrationState -o tsv 2>/dev/null || echo Unknown)"
    if [[ "$state" != "Registered" && "$REGISTER_PROVIDERS" == true ]]; then
      az provider register --namespace "$provider" >/dev/null 2>&1 || true
      state="$(az provider show --namespace "$provider" --query registrationState -o tsv 2>/dev/null || echo Registering)"
    fi
    if [[ "$first" == false ]]; then printf ',\n' >> "$phase_dir/providers.json"; fi
    first=false
    printf '  "%s": "%s"' "$provider" "$state" >> "$phase_dir/providers.json"
  done
  printf '\n}\n' >> "$phase_dir/providers.json"

  az vm list-usage --location "$LOCATION" -o json > "$phase_dir/vm-usage.json" 2> "$phase_dir/vm-usage.err" || true
  az network list-usages --location "$LOCATION" -o json > "$phase_dir/network-usage.json" 2> "$phase_dir/network-usage.err" || true
  az aks get-versions --location "$LOCATION" -o json > "$phase_dir/aks-versions.json" 2> "$phase_dir/aks-versions.err" || true
  az cognitiveservices usage list --location "$LOCATION" -o json > "$phase_dir/cognitive-usage.json" 2> "$phase_dir/cognitive-usage.err" || true

  if ! grep -q '"1.34' "$phase_dir/aks-versions.json" 2>/dev/null; then
    write_error "$PHASE" "aks_134_unavailable" "azure-portal-deploy" "AKS 1.34 was not found in az aks get-versions output for $LOCATION." "$phase_dir/aks-versions.json"
    write_status "$PHASE" "failed" "aks_134_unavailable" "azure-portal-deploy" true
    exit 1
  fi

  jq '{subscription: .id, tenant: .tenantId, name: .name}' "$phase_dir/account.json" > "$phase_dir/account-summary.json"
  write_status "$PHASE" "passed" "" "azure-portal-deploy" true
  append_summary "Preflight passed for subscription $account_sub in $LOCATION"
}

phase_plan() {
  PHASE="plan"
  local phase_dir="$RUN_DIR/01-plan"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  append_summary "Plan started"
  ensure_fixes_file
  write_validation_tfvars

  [[ -f "$BASE_TFVARS" ]] || { write_error "$PHASE" "missing_base_tfvars" "terraform" "Base tfvars not found: $BASE_TFVARS" ""; write_status "$PHASE" "failed" "missing_base_tfvars" "terraform" false; exit 1; }

  cd "$TERRAFORM_DIR"
  run_logged "$phase_dir" "terraform-fmt-check" terraform fmt -recursive -check >/dev/null
  run_logged "$phase_dir" "terraform-init" terraform init -backend=false -input=false -no-color >/dev/null
  run_logged "$phase_dir" "terraform-validate" terraform validate -no-color >/dev/null

  if command -v tflint >/dev/null 2>&1; then
    run_logged "$phase_dir" "tflint" tflint --recursive --minimum-failure-severity=error >/dev/null
  else
    printf 'tflint not installed locally; CI workflow installs and runs it.\n' > "$phase_dir/tflint.skipped"
  fi

  set +e
  terraform plan "$(terraform_var_files | sed -n '1p')" "$(terraform_var_files | sed -n '2p')" -out="$PLAN_FILE" -detailed-exitcode -no-color > "$phase_dir/terraform-plan.log" 2>&1
  local plan_exit=$?
  set -e
  if [[ "$plan_exit" -eq 1 ]]; then
    write_error "$PHASE" "terraform_plan_failed" "terraform" "Terraform plan failed." "$phase_dir/terraform-plan.log"
    write_status "$PHASE" "failed" "terraform_plan" "terraform" true
    tail -100 "$phase_dir/terraform-plan.log" >&2 || true
    exit 1
  fi

  terraform show -json "$PLAN_FILE" > "$PLAN_JSON"
  cp "$PLAN_JSON" "$phase_dir/tfplan.json"

  if command -v jq >/dev/null 2>&1; then
    jq '[.resource_changes[]? | {address, type, actions: .change.actions}]' "$PLAN_JSON" > "$phase_dir/resource-changes-summary.json"
    jq '{create: [.resource_changes[]? | select(.change.actions | index("create"))] | length, update: [.resource_changes[]? | select(.change.actions | index("update"))] | length, delete: [.resource_changes[]? | select(.change.actions | index("delete"))] | length}' "$PLAN_JSON" > "$phase_dir/change-counts.json"
  fi

  if command -v conftest >/dev/null 2>&1; then
    set +e
    conftest test "$PLAN_JSON" --policy "$PROJECT_DIR/policies/terraform" --all-namespaces > "$phase_dir/conftest.log" 2>&1
    local conftest_exit=$?
    set -e
    if [[ "$conftest_exit" -ne 0 ]]; then
      write_error "$PHASE" "conftest_failed" "security" "OPA/conftest policy validation failed." "$phase_dir/conftest.log"
      write_status "$PHASE" "failed" "conftest" "security" true
      tail -100 "$phase_dir/conftest.log" >&2 || true
      exit 1
    fi
  else
    printf 'conftest not installed locally; CI workflow installs and runs it.\n' > "$phase_dir/conftest.skipped"
  fi

  cd "$PROJECT_DIR"
  write_status "$PHASE" "passed" "" "terraform" true
  append_summary "Plan passed. Plan file: $PLAN_FILE"
}

require_plan() {
  [[ -f "$PLAN_FILE" ]] || { echo "Missing plan file: $PLAN_FILE. Run --phase plan first." >&2; exit 1; }
}

phase_apply() {
  PHASE="apply"
  local phase_dir="$RUN_DIR/02-apply"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  require_plan
  if [[ "$CONFIRM_APPLY" != true ]]; then
    write_error "$PHASE" "apply_not_confirmed" "deploy" "Apply requires --confirm-apply." ""
    write_status "$PHASE" "failed" "apply_not_confirmed" "deploy" false
    exit 1
  fi
  cd "$TERRAFORM_DIR"
  if [[ "$AUTO_APPROVE" == true ]]; then
    run_logged "$phase_dir" "terraform-apply" terraform apply -auto-approve "$PLAN_FILE" >/dev/null
  else
    run_logged "$phase_dir" "terraform-apply" terraform apply "$PLAN_FILE" >/dev/null
  fi
  terraform output -json > "$phase_dir/terraform-output.json" 2> "$phase_dir/terraform-output.err" || true
  cd "$PROJECT_DIR"
  write_status "$PHASE" "passed" "" "deploy" true
  append_summary "Apply passed"
}

get_output_raw() {
  local name="$1"
  terraform -chdir="$TERRAFORM_DIR" output -raw "$name" 2>/dev/null || true
}

configure_kubectl() {
  local phase_dir="$1"
  local rg aks
  rg="$(get_output_raw resource_group_name)"
  aks="$(get_output_raw aks_cluster_name)"
  if [[ -n "$rg" && -n "$aks" ]]; then
    az aks get-credentials --resource-group "$rg" --name "$aks" --overwrite-existing > "$phase_dir/az-aks-get-credentials.log" 2>&1 || return 1
  else
    return 1
  fi
}

phase_validate_h1() {
  PHASE="validate-h1"
  local phase_dir="$RUN_DIR/03-validate-h1"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  if ! configure_kubectl "$phase_dir"; then
    write_error "$PHASE" "aks_credentials_failed" "azure-portal-deploy" "Could not configure AKS credentials from Terraform outputs." "$phase_dir/az-aks-get-credentials.log"
    write_status "$PHASE" "failed" "aks_credentials" "azure-portal-deploy" true
    exit 1
  fi
  kubectl get nodes -o wide > "$phase_dir/kubectl-nodes.txt" 2> "$phase_dir/kubectl-nodes.err" || true
  kubectl get pods -A -o wide > "$phase_dir/kubectl-pods-all.txt" 2> "$phase_dir/kubectl-pods-all.err" || true
  kubectl get events -A --sort-by=.lastTimestamp > "$phase_dir/kubectl-events.txt" 2> "$phase_dir/kubectl-events.err" || true
  if ! grep -q ' Ready ' "$phase_dir/kubectl-nodes.txt" 2>/dev/null; then
    write_error "$PHASE" "nodes_not_ready" "sre" "No AKS nodes reported Ready." "$phase_dir/kubectl-nodes.txt"
    write_status "$PHASE" "failed" "nodes_not_ready" "sre" true
    exit 1
  fi
  write_status "$PHASE" "passed" "" "sre" true
  append_summary "H1 validation passed"
}

phase_validate_h2() {
  PHASE="validate-h2"
  local phase_dir="$RUN_DIR/04-validate-h2"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  configure_kubectl "$phase_dir" || true
  for ns in argocd observability external-secrets backstage ai-services; do
    kubectl get namespace "$ns" -o json > "$phase_dir/ns-${ns}.json" 2> "$phase_dir/ns-${ns}.err" || true
    kubectl get pods -n "$ns" -o wide > "$phase_dir/pods-${ns}.txt" 2> "$phase_dir/pods-${ns}.err" || true
  done
  if grep -RniE 'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError' "$phase_dir" >/dev/null 2>&1; then
    grep -RniE 'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError' "$phase_dir" > "$phase_dir/pod-errors.txt" || true
    write_error "$PHASE" "pod_errors" "sre" "H2 pod errors detected." "$phase_dir/pod-errors.txt"
    write_status "$PHASE" "failed" "pod_errors" "sre" true
    exit 1
  fi
  write_status "$PHASE" "passed" "" "sre" true
  append_summary "H2 validation passed or optional namespaces absent"
}

phase_validate_h3() {
  PHASE="validate-h3"
  local phase_dir="$RUN_DIR/05-validate-h3"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  configure_kubectl "$phase_dir" || true
  az cognitiveservices account list -o json > "$phase_dir/cognitive-accounts.json" 2> "$phase_dir/cognitive-accounts.err" || true
  az search service list -o json > "$phase_dir/search-services.json" 2> "$phase_dir/search-services.err" || true
  kubectl get pods -n ai-services -o wide > "$phase_dir/pods-ai-services.txt" 2> "$phase_dir/pods-ai-services.err" || true
  kubectl get svc -n ai-services -o wide > "$phase_dir/services-ai-services.txt" 2> "$phase_dir/services-ai-services.err" || true
  if [[ -s "$phase_dir/pods-ai-services.txt" ]] && grep -qE 'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError' "$phase_dir/pods-ai-services.txt"; then
    write_error "$PHASE" "h3_pod_errors" "sre" "H3 pod errors detected." "$phase_dir/pods-ai-services.txt"
    write_status "$PHASE" "failed" "h3_pod_errors" "sre" true
    exit 1
  fi
  write_status "$PHASE" "passed" "" "sre" true
  append_summary "H3 validation completed"
}

phase_inventory() {
  PHASE="inventory"
  local phase_dir="$RUN_DIR/07-inventory"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  az resource list -g "$RESOURCE_GROUP" -o json > "$phase_dir/resources.json" 2> "$phase_dir/resources.err" || true
  terraform -chdir="$TERRAFORM_DIR" output -json > "$phase_dir/terraform-output.json" 2> "$phase_dir/terraform-output.err" || true
  if command -v jq >/dev/null 2>&1 && [[ -s "$phase_dir/resources.json" ]]; then
    jq '[.[] | {name, type, location, id}]' "$phase_dir/resources.json" > "$phase_dir/resources-summary.json" || true
    jq -r '.[] | [.type, .name, .location] | @tsv' "$phase_dir/resources.json" > "$phase_dir/resources.tsv" || true
  fi
  write_status "$PHASE" "passed" "" "azure-portal-deploy" true
  append_summary "Inventory captured"
}

phase_docs() {
  PHASE="docs"
  local phase_dir="$RUN_DIR/08-docs"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  local resources_json="$RUN_DIR/07-inventory/resources-summary.json"
  cat > "$phase_dir/resource-inventory.md" <<MD
# Azure Validation Resource Inventory

Run: $RUN_ID

| Field | Value |
| --- | --- |
| Customer | $CUSTOMER_NAME |
| Environment | $ENVIRONMENT |
| Region | $LOCATION |
| Resource Group | $RESOURCE_GROUP |
| Generated | $(date -u +%Y-%m-%dT%H:%M:%SZ) |

## Resources

MD
  if [[ -s "$resources_json" ]] && command -v jq >/dev/null 2>&1; then
    printf '| Type | Name | Location |\n| --- | --- | --- |\n' >> "$phase_dir/resource-inventory.md"
    jq -r '.[] | "| `\(.type)` | `\(.name)` | `\(.location)` |"' "$resources_json" >> "$phase_dir/resource-inventory.md" || true
  else
    printf 'Resource inventory was not available. Run --phase inventory after apply.\n' >> "$phase_dir/resource-inventory.md"
  fi
  write_status "$PHASE" "passed" "" "deploy" true
  append_summary "Documentation artifact generated: $phase_dir/resource-inventory.md"
}

phase_destroy() {
  PHASE="destroy"
  local phase_dir="$RUN_DIR/10-destroy"
  mkdir -p "$phase_dir"
  clear_errors
  write_status "$PHASE" "running"
  write_validation_tfvars
  if [[ "$CONFIRM_DESTROY" != true || "$DESTROY_CONFIRM_TEXT" != "${CUSTOMER_NAME}-${ENVIRONMENT}" ]]; then
    write_error "$PHASE" "destroy_not_confirmed" "deploy" "Destroy requires --confirm-destroy --destroy-confirm-text ${CUSTOMER_NAME}-${ENVIRONMENT}." ""
    write_status "$PHASE" "failed" "destroy_not_confirmed" "deploy" false
    exit 1
  fi
  cd "$TERRAFORM_DIR"
  if [[ "$AUTO_APPROVE" == true ]]; then
    run_logged "$phase_dir" "terraform-destroy" terraform destroy "$(terraform_var_files | sed -n '1p')" "$(terraform_var_files | sed -n '2p')" -auto-approve -no-color >/dev/null
  else
    run_logged "$phase_dir" "terraform-destroy" terraform destroy "$(terraform_var_files | sed -n '1p')" "$(terraform_var_files | sed -n '2p')" -no-color >/dev/null
  fi
  cd "$PROJECT_DIR"
  az resource list -g "$RESOURCE_GROUP" -o json > "$phase_dir/post-destroy-resources.json" 2> "$phase_dir/post-destroy-resources.err" || true
  if [[ "$DELETE_RG" == true ]]; then
    az group delete -n "$RESOURCE_GROUP" --yes --no-wait > "$phase_dir/az-group-delete.log" 2>&1 || true
  fi
  write_status "$PHASE" "passed" "" "deploy" true
  append_summary "Destroy completed"
}

case "$PHASE" in
  preflight) phase_preflight ;;
  plan) phase_plan ;;
  apply) phase_apply ;;
  validate-h1) phase_validate_h1 ;;
  validate-h2) phase_validate_h2 ;;
  validate-h3) phase_validate_h3 ;;
  validate-all) phase_validate_h1; phase_validate_h2; phase_validate_h3 ;;
  inventory) phase_inventory ;;
  docs) phase_docs ;;
  destroy) phase_destroy ;;
  all-safe) phase_preflight; phase_plan ;;
  *) echo "Unsupported phase: $PHASE" >&2; usage; exit 2 ;;
esac

append_summary "Phase $PHASE completed"
echo "Run artifacts: $RUN_DIR"
echo "Status: $STATUS_FILE"
