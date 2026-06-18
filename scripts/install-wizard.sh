#!/usr/bin/env bash
# =============================================================================
# OPEN HORIZONS PLATFORM - INSTALL WIZARD
# =============================================================================
#
# Lets a client pick what to install BEFORE running scripts/deploy-full.sh:
#   - Horizon level (h1 | h2 | h3 | all)
#   - Deployment mode (express | standard | enterprise)
#   - Portal profile (base | platform | full)
#   - Branding profile (neutral | open-horizons | custom)
#   - Terraform module toggles (11 enable_* flags)
#   - Backstage component toggles (6 toggles: AI Chat plugin, 4 agent APIs,
#     MCP ecosystem)
#   - Backstage feature packs (H2 platform pages, H3 AI, MCP)
#   - Subset of the 34 Golden Path templates surfaced in the catalog
#
# Outputs:
#   .openhorizons-selection.yaml    - persisted selection manifest (root)
#   .openhorizons-selection.history - append-only audit log (root)
#   terraform/environments/<env>.tfvars
#   backstage/app-config.production.yaml (regenerated)
#
# Usage:
#   scripts/install-wizard.sh                               # interactive
#   scripts/install-wizard.sh --auto --selection-file <p>   # CI/CD
#   scripts/install-wizard.sh --help                        # full options
#
# Spec: .specs/001-open-horizons-install-wizard-and-component-selection/
# =============================================================================
set -euo pipefail

# --- requires bash 4+ (associative arrays); macOS ships bash 3.2 by default ---
if (( ${BASH_VERSINFO[0]:-0} < 4 )); then
    echo "ERROR: this script requires bash 4 or newer (found ${BASH_VERSION:-unknown})." >&2
    echo "       On macOS run: brew install bash, then invoke the script with that bash." >&2
    exit 1
fi

# --- Colors & helpers --------------------------------------------------------
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; NC=''; BOLD=''
fi

log()      { echo -e "${BLUE}[wizard]${NC} $*"; }
log_ok()   { echo -e "${GREEN}[wizard]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[wizard]${NC} $*"; }
log_err()  { echo -e "${RED}[wizard]${NC} $*" >&2; }

# --- Repo paths --------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST_FILE="$REPO_ROOT/.openhorizons-selection.yaml"
HISTORY_FILE="$REPO_ROOT/.openhorizons-selection.history"
TFVARS_EXAMPLE="$REPO_ROOT/terraform/terraform.tfvars.example"
APP_CONFIG="$REPO_ROOT/backstage/app-config.production.yaml"
GOLDEN_PATHS_DIR="$REPO_ROOT/golden-paths"

# --- Defaults & exit codes ---------------------------------------------------
ENVIRONMENT=""
HORIZON=""
DEPLOYMENT_MODE=""
PORTAL_PROFILE="base"      # base | platform | full | custom
BRANDING_PROFILE="neutral" # neutral | open-horizons | custom
AUTO=false
DRY_RUN=false
NEXT_STEP="nothing"   # nothing | deploy
FORCE=false
SELECTION_FILE=""
PROFILE=""           # minimal | standard | full | (empty for custom)
SCHEMA_FILE="$SCRIPT_DIR/openhorizons-selection.schema.json"

EXIT_USAGE=1
EXIT_RULE=2
EXIT_VALIDATOR=3
EXIT_ABORT=4

# --- Module catalog ----------------------------------------------------------
# Parallel arrays (bash 3.2 compatible: no declare -A).
# Index i in MODULE_KEYS aligns with MODULE_DEFAULTS, MODULE_HORIZONS, MODULE_VALS.
MODULE_KEYS=(
  enable_container_registry
  enable_databases
  enable_defender
  enable_purview
  enable_argocd
  enable_external_secrets
  enable_observability
  enable_github_runners
  enable_cost_management
  enable_ai_foundry
  enable_foundry_agents
  enable_disaster_recovery
)
MODULE_DEFAULTS=(true true false false true true true false false false false false)
MODULE_HORIZONS=(h1 h1 h1 h1 h2 h2 h2 h2 h2 h3 h3 h0)
MODULE_VALS=()

BACKSTAGE_KEYS=(
  enable_ai_chat_plugin
  enable_agent_api
  enable_agent_api_impact
  enable_agent_api_maf
  enable_agent_api_sk
  enable_mcp_ecosystem
)
BACKSTAGE_DEFAULTS=(true true false false false false)
BACKSTAGE_VALS=()

FEATURE_PACK_KEYS=(
  enable_branding_pack
  enable_platform_pages
  enable_observability_pages
  enable_ai_chat
  enable_ai_impact
  enable_mcp_ecosystem
)
FEATURE_PACK_DEFAULTS=(false false false false false false)
FEATURE_PACK_VALS=()

SELECTED_PATHS=()
SELECTED_AGENTS=()
SELECTED_SKILLS=()
SELECTED_PROMPTS=()
SELECTED_MCP=()
PORTAL_PROFILE_EXPLICIT=false
FEATURE_PACKS_EXPLICIT=false

# Helper: index of key in array
index_of() {
  local needle="$1"; shift
  local i=0
  for k in "$@"; do
    [[ "$k" == "$needle" ]] && { echo "$i"; return 0; }
    i=$((i + 1))
  done
  return 1
}

mod_default()  { echo "${MODULE_DEFAULTS[$1]}"; }
mod_horizon()  { echo "${MODULE_HORIZONS[$1]}"; }
mod_get()      { echo "${MODULE_VALS[$1]}"; }
mod_set()      { MODULE_VALS[$1]="$2"; }
bs_default()   { echo "${BACKSTAGE_DEFAULTS[$1]}"; }
bs_get()       { echo "${BACKSTAGE_VALS[$1]}"; }
bs_set()       { BACKSTAGE_VALS[$1]="$2"; }
fp_default()   { echo "${FEATURE_PACK_DEFAULTS[$1]}"; }
fp_get()       { echo "${FEATURE_PACK_VALS[$1]}"; }
fp_set()       { FEATURE_PACK_VALS[$1]="$2"; }

# =============================================================================
# Helpers
# =============================================================================

usage() {
  cat <<EOF
Open Horizons Install Wizard

Usage:
  scripts/install-wizard.sh [options]

Options:
  --environment, -e <env>     Target environment (dev|staging|prod). Required when --auto.
  --horizon, -h <h>           h1 | h2 | h3 | all. Default: prompt or value from --selection-file.
  --deployment-mode <m>       express | standard | enterprise.
  --portal-profile <p>        base | platform | full.
  --branding-profile <p>      neutral | open-horizons | custom.
  --auto                      Non-interactive mode. Requires --selection-file.
  --selection-file <path>     YAML manifest in --auto mode (defaults to .openhorizons-selection.yaml).
  --dry-run                   Print diffs but write nothing.
  --next-step <s>             nothing | deploy. Default: nothing.
  --force                     Skip confirmation prompts on diffs (interactive only).
  --profile <p>               Apply a curated preset before prompts: minimal | standard | full.
                               minimal => H1 + clean Backstage base.
                               standard => H2 platform portal.
                               full => H2 + H3 AI/agent/MCP packs.
  --help                      Show this help.

Examples:
  scripts/install-wizard.sh
  scripts/install-wizard.sh --environment dev --horizon all
  scripts/install-wizard.sh --auto --selection-file .openhorizons-selection.yaml --next-step deploy

Exit codes:
  0 success, 1 usage error, 2 dependency rule violation,
  3 validator failure, 4 user aborted.
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_err "Required command not found: $cmd"
    return 1
  fi
}

iso_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

bool_normalize() {
  local raw
  raw="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$raw" in
    true|t|yes|y|1) echo "true" ;;
    false|f|no|n|0) echo "false" ;;
    *)              echo "" ;;
  esac
}

bool_to_yn() { [[ "$1" == "true" ]] && echo "yes" || echo "no"; }

lowercase() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

prompt_yn() {
  # $1 = prompt, $2 = default (true/false)
  local prompt="$1" default="$2" answer
  if $AUTO; then echo "$default"; return; fi
  read -r -p "$prompt [$(bool_to_yn "$default")]: " answer
  answer="$(lowercase "$answer")"
  if [[ -z "$answer" ]]; then echo "$default"; return; fi
  case "$answer" in
    y|yes|true|1) echo "true" ;;
    n|no|false|0) echo "false" ;;
    *)            echo "$default" ;;
  esac
}

prompt_choice() {
  # $1 = prompt, $2 = default, rest = options
  local prompt="$1" default="$2"
  shift 2
  local choices=("$@") answer
  if $AUTO; then echo "$default"; return; fi
  read -r -p "$prompt [$(IFS=/; echo "${choices[*]}"); default=$default]: " answer
  answer="${answer:-$default}"
  for c in "${choices[@]}"; do
    [[ "$answer" == "$c" ]] && { echo "$answer"; return; }
  done
  log_warn "Invalid choice '$answer', using default '$default'."
  echo "$default"
}

list_golden_paths() {
  # Emit "<horizon>/<template>" identifiers found on disk.
  if [[ -d "$GOLDEN_PATHS_DIR" ]]; then
    find "$GOLDEN_PATHS_DIR" -mindepth 3 -maxdepth 3 -type f -name template.yaml \
      | sed "s|$GOLDEN_PATHS_DIR/||" \
      | sed 's|/template.yaml$||' \
      | sort
  fi
}

# =============================================================================
# Manifest loader (T-004)
# =============================================================================

load_manifest() {
  local source_file="${1:-$MANIFEST_FILE}"
  local i k
  if [[ ! -f "$source_file" ]]; then
    log "No manifest at $source_file, using defaults."
    HORIZON="${HORIZON:-all}"
    DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-express}"
    for i in "${!MODULE_KEYS[@]}";    do MODULE_VALS[$i]="${MODULE_DEFAULTS[$i]}"; done
    for i in "${!BACKSTAGE_KEYS[@]}"; do BACKSTAGE_VALS[$i]="${BACKSTAGE_DEFAULTS[$i]}"; done
    for i in "${!FEATURE_PACK_KEYS[@]}"; do FEATURE_PACK_VALS[$i]="${FEATURE_PACK_DEFAULTS[$i]}"; done
    apply_portal_profile_defaults
    while IFS= read -r tpl; do SELECTED_PATHS+=("$tpl"); done < <(list_golden_paths)
    return
  fi

  log "Loading manifest from $source_file"
  local raw
  raw="$(yq '.horizon' "$source_file")"
  [[ "$raw" == "null" || -z "$raw" ]] && raw="all"
  HORIZON="${HORIZON:-$raw}"
  raw="$(yq '.deployment_mode' "$source_file")"
  [[ "$raw" == "null" || -z "$raw" ]] && raw="express"
  DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-$raw}"
  PORTAL_PROFILE_EXPLICIT=false
  raw="$(yq '.portal_profile' "$source_file")"
  if [[ "$raw" == "null" || -z "$raw" ]]; then
    raw="base"
  else
    PORTAL_PROFILE_EXPLICIT=true
  fi
  PORTAL_PROFILE="$raw"
  raw="$(yq '.branding_profile' "$source_file")"
  [[ "$raw" == "null" || -z "$raw" ]] && raw="neutral"
  BRANDING_PROFILE="$raw"
  if [[ -z "$ENVIRONMENT" ]]; then
    raw="$(yq '.environment' "$source_file")"
    [[ "$raw" == "null" || -z "$raw" ]] && raw=""
    ENVIRONMENT="$raw"
  fi

  for i in "${!MODULE_KEYS[@]}"; do
    k="${MODULE_KEYS[$i]}"
    raw="$(yq ".modules.$k" "$source_file")"
    if [[ "$raw" == "null" || -z "$raw" ]]; then
      raw="${MODULE_DEFAULTS[$i]}"
    fi
    MODULE_VALS[$i]="$(bool_normalize "$raw")"
  done
  for i in "${!BACKSTAGE_KEYS[@]}"; do
    k="${BACKSTAGE_KEYS[$i]}"
    raw="$(yq ".backstage_components.$k" "$source_file")"
    if [[ "$raw" == "null" || -z "$raw" ]]; then
      raw="${BACKSTAGE_DEFAULTS[$i]}"
    fi
    BACKSTAGE_VALS[$i]="$(bool_normalize "$raw")"
  done
  FEATURE_PACKS_EXPLICIT=false
  for i in "${!FEATURE_PACK_KEYS[@]}"; do
    k="${FEATURE_PACK_KEYS[$i]}"
    raw="$(yq ".feature_packs.$k" "$source_file")"
    if [[ "$raw" == "null" || -z "$raw" ]]; then
      raw="${FEATURE_PACK_DEFAULTS[$i]}"
    else
      FEATURE_PACKS_EXPLICIT=true
    fi
    FEATURE_PACK_VALS[$i]="$(bool_normalize "$raw")"
  done
  if $FEATURE_PACKS_EXPLICIT; then
    align_feature_packs_to_components
  elif $PORTAL_PROFILE_EXPLICIT; then
    apply_portal_profile_defaults
  else
    derive_feature_packs_from_components
  fi

  SELECTED_PATHS=()
  while IFS= read -r tpl; do
    [[ -n "$tpl" && "$tpl" != "null" ]] && SELECTED_PATHS+=("$tpl")
  done < <(yq '.golden_paths[]?' "$source_file")
  if [[ ${#SELECTED_PATHS[@]} -eq 0 ]]; then
    while IFS= read -r tpl; do SELECTED_PATHS+=("$tpl"); done < <(list_golden_paths)
  fi

  SELECTED_AGENTS=()
  while IFS= read -r v; do
    [[ -n "$v" && "$v" != "null" ]] && SELECTED_AGENTS+=("$v")
  done < <(yq '.agents[]?' "$source_file")

  SELECTED_SKILLS=()
  while IFS= read -r v; do
    [[ -n "$v" && "$v" != "null" ]] && SELECTED_SKILLS+=("$v")
  done < <(yq '.skills[]?' "$source_file")

  SELECTED_PROMPTS=()
  while IFS= read -r v; do
    [[ -n "$v" && "$v" != "null" ]] && SELECTED_PROMPTS+=("$v")
  done < <(yq '.prompts[]?' "$source_file")

  SELECTED_MCP=()
  while IFS= read -r v; do
    [[ -n "$v" && "$v" != "null" ]] && SELECTED_MCP+=("$v")
  done < <(yq '.mcp_servers[]?' "$source_file")
}

# =============================================================================
# Primitive helpers (Specky 002)
# =============================================================================

list_agents()      { ls "$REPO_ROOT/.github/agents"     2>/dev/null | sed -n 's/\.agent\.md$//p'  | sort; }
list_skills()      { (cd "$REPO_ROOT/.github/skills" 2>/dev/null && ls -d */ 2>/dev/null) | sed 's|/$||' | sort; }
list_prompts()     { ls "$REPO_ROOT/.github/prompts"    2>/dev/null | sed -n 's/\.prompt\.md$//p' | sort; }
list_mcp_servers() { ls "$REPO_ROOT/mcp-servers/src/tools" 2>/dev/null | sed -n 's/\.ts$//p'   | sort; }

validate_primitive_ids() {
  local kind="$1" available="$2"
  shift 2
  local rc=0 id known
  for id in "$@"; do
    [[ -z "$id" ]] && continue
    known=false
    while IFS= read -r line; do
      [[ "$id" == "$line" ]] && known=true && break
    done <<< "$available"
    if ! $known; then
      log_err "Unknown $kind id: $id"
      rc=1
    fi
  done
  return $rc
}

# =============================================================================
# Interactive prompts (T-005)
# =============================================================================

prompt_environment() {
  if [[ -z "$ENVIRONMENT" ]]; then
    if $AUTO; then
      log_err "--auto requires --environment or environment field in manifest."
      exit "$EXIT_USAGE"
    fi
    ENVIRONMENT="$(prompt_choice "Environment" "dev" dev staging prod)"
  fi
}

prompt_horizon_choice() {
  HORIZON="$(prompt_choice "Horizon" "$HORIZON" h1 h2 h3 all)"
}

prompt_deployment_mode_choice() {
  DEPLOYMENT_MODE="$(prompt_choice "Deployment mode" "$DEPLOYMENT_MODE" express standard enterprise)"
}

prompt_portal_profile_choice() {
  if $AUTO && ! $PORTAL_PROFILE_EXPLICIT && [[ -z "$PROFILE" ]]; then
    return 0
  fi
  PORTAL_PROFILE="$(prompt_choice "Portal profile" "$PORTAL_PROFILE" base platform full custom)"
  apply_portal_profile_defaults
}

prompt_branding_profile_choice() {
  if $AUTO && [[ -z "$PROFILE" ]]; then
    return 0
  fi
  BRANDING_PROFILE="$(prompt_choice "Branding profile" "$BRANDING_PROFILE" neutral open-horizons custom)"
}

apply_portal_profile_defaults() {
  case "$PORTAL_PROFILE" in
    base)
      fp_set 0 false; fp_set 1 false; fp_set 2 false; fp_set 3 false; fp_set 4 false; fp_set 5 false
      ;;
    platform)
      fp_set 0 true; fp_set 1 true; fp_set 2 true; fp_set 3 false; fp_set 4 false; fp_set 5 false
      ;;
    full)
      fp_set 0 true; fp_set 1 true; fp_set 2 true; fp_set 3 true; fp_set 4 true; fp_set 5 true
      ;;
    custom)
      # Keep whatever feature packs the operator already selected (interactive
      # prompts or the selection manifest). The custom profile never forces a
      # preset, it only aligns the legacy component flags below.
      ;;
    *)
      log_err "Unknown portal_profile: $PORTAL_PROFILE (use base | platform | full | custom)"
      exit "$EXIT_USAGE"
      ;;
  esac

  align_feature_packs_to_components
  return 0
}

align_feature_packs_to_components() {
  # Keep legacy component flags aligned with the higher-level feature packs.
  local i_chat i_api i_impact i_mcp i_aif
  i_chat=$(index_of enable_ai_chat_plugin "${BACKSTAGE_KEYS[@]}") || true
  i_api=$(index_of enable_agent_api "${BACKSTAGE_KEYS[@]}") || true
  i_impact=$(index_of enable_agent_api_impact "${BACKSTAGE_KEYS[@]}") || true
  i_mcp=$(index_of enable_mcp_ecosystem "${BACKSTAGE_KEYS[@]}") || true
  i_aif=$(index_of enable_ai_foundry "${MODULE_KEYS[@]}") || true

  [[ -n "$i_chat" ]] && bs_set "$i_chat" "${FEATURE_PACK_VALS[3]}"
  [[ -n "$i_api" ]] && bs_set "$i_api" "${FEATURE_PACK_VALS[3]}"
  [[ -n "$i_impact" ]] && bs_set "$i_impact" "${FEATURE_PACK_VALS[4]}"
  [[ -n "$i_mcp" ]] && bs_set "$i_mcp" "${FEATURE_PACK_VALS[5]}"
  [[ -n "$i_aif" && ( "${FEATURE_PACK_VALS[3]}" == "true" || "${FEATURE_PACK_VALS[4]}" == "true" ) ]] && mod_set "$i_aif" true
  return 0
}

derive_feature_packs_from_components() {
  # Legacy manifests only set backstage_components. Derive the higher-level
  # feature packs from them so downstream rendering (which reads feature_packs
  # first) stays consistent with the legacy intent.
  local i_chat i_api i_impact i_mcp chat_val
  i_chat=$(index_of enable_ai_chat_plugin "${BACKSTAGE_KEYS[@]}") || true
  i_api=$(index_of enable_agent_api "${BACKSTAGE_KEYS[@]}") || true
  i_impact=$(index_of enable_agent_api_impact "${BACKSTAGE_KEYS[@]}") || true
  i_mcp=$(index_of enable_mcp_ecosystem "${BACKSTAGE_KEYS[@]}") || true

  chat_val=false
  [[ -n "$i_chat" && "${BACKSTAGE_VALS[$i_chat]}" == "true" ]] && chat_val=true
  [[ -n "$i_api" && "${BACKSTAGE_VALS[$i_api]}" == "true" ]] && chat_val=true
  FEATURE_PACK_VALS[3]="$chat_val"
  [[ -n "$i_impact" ]] && FEATURE_PACK_VALS[4]="${BACKSTAGE_VALS[$i_impact]}"
  [[ -n "$i_mcp" ]] && FEATURE_PACK_VALS[5]="${BACKSTAGE_VALS[$i_mcp]}"
  return 0
}

prompt_modules() {
  $AUTO && return
  echo
  log "Terraform module toggles (Enter to keep default):"
  local i k horizon_tag
  for i in "${!MODULE_KEYS[@]}"; do
    k="${MODULE_KEYS[$i]}"
    horizon_tag="${MODULE_HORIZONS[$i]}"
    if [[ "$horizon_tag" != "h0" && "$HORIZON" != "all" && "$HORIZON" != "$horizon_tag" ]]; then
      MODULE_VALS[$i]=false
      continue
    fi
    MODULE_VALS[$i]="$(prompt_yn "  $k (${horizon_tag})" "${MODULE_VALS[$i]}")"
  done
}

prompt_backstage() {
  $AUTO && return
  echo
  log "Backstage feature packs:"
  local i k
  for i in "${!FEATURE_PACK_KEYS[@]}"; do
    k="${FEATURE_PACK_KEYS[$i]}"
    FEATURE_PACK_VALS[$i]="$(prompt_yn "  $k" "${FEATURE_PACK_VALS[$i]}")"
  done
  apply_portal_profile_defaults

  echo
  log "Backstage component toggles (advanced):"
  local i k
  for i in "${!BACKSTAGE_KEYS[@]}"; do
    k="${BACKSTAGE_KEYS[$i]}"
    BACKSTAGE_VALS[$i]="$(prompt_yn "  $k" "${BACKSTAGE_VALS[$i]}")"
  done
}

prompt_paths() {
  $AUTO && return
  echo
  log "Golden Path selection. Enter 'a' for all, 'n' for none, or list ids."
  log "Available templates:"
  list_golden_paths | sed 's/^/  - /'
  read -r -p "Selection [a]: " ans
  ans="${ans:-a}"
  case "$ans" in
    a|A|all)
      SELECTED_PATHS=()
      while IFS= read -r tpl; do SELECTED_PATHS+=("$tpl"); done < <(list_golden_paths)
      ;;
    n|N|none)
      SELECTED_PATHS=()
      ;;
    *)
      SELECTED_PATHS=()
      # Accept comma- or space-separated identifiers
      IFS=', ' read -r -a parts <<< "$ans"
      for p in "${parts[@]}"; do
        [[ -n "$p" ]] && SELECTED_PATHS+=("$p")
      done
      ;;
  esac
}

# =============================================================================
# Profile presets (T-018)
# =============================================================================

apply_profile() {
  local profile="$1"
  [[ -z "$profile" ]] && return 0
  log "Applying profile: $profile"
  case "$profile" in
    minimal)
      PORTAL_PROFILE="base"
      BRANDING_PROFILE="neutral"
      HORIZON="h1"
      DEPLOYMENT_MODE="express"
      mod_set 0 true   # container_registry
      mod_set 1 true   # databases
      mod_set 2 false; mod_set 3 false
      mod_set 4 false; mod_set 5 false; mod_set 6 false
      mod_set 7 false; mod_set 8 false; mod_set 9 false
      mod_set 10 false # foundry_agents (H3)
      mod_set 11 false # disaster_recovery
      bs_set 0 false; bs_set 1 false; bs_set 2 false
      bs_set 3 false; bs_set 4 false; bs_set 5 false
      apply_portal_profile_defaults
      SELECTED_PATHS=(
        h1-foundation/basic-cicd
        h1-foundation/web-application
        h1-foundation/security-baseline
      )
      ;;
    standard)
      PORTAL_PROFILE="platform"
      BRANDING_PROFILE="open-horizons"
      HORIZON="h2"
      DEPLOYMENT_MODE="standard"
      mod_set 0 true; mod_set 1 true
      mod_set 2 true; mod_set 3 false
      mod_set 4 true; mod_set 5 true; mod_set 6 true
      mod_set 7 false; mod_set 8 true; mod_set 9 false
      mod_set 10 false # foundry_agents (H3)
      mod_set 11 false # disaster_recovery
      bs_set 0 true; bs_set 1 true
      bs_set 2 false; bs_set 3 false; bs_set 4 false; bs_set 5 false
      apply_portal_profile_defaults
      SELECTED_PATHS=()
      while IFS= read -r tpl; do
        if [[ "$tpl" == h1-foundation/* || "$tpl" == h2-enhancement/* ]]; then
          SELECTED_PATHS+=("$tpl")
        fi
      done < <(list_golden_paths)
      ;;
    full)
      PORTAL_PROFILE="full"
      BRANDING_PROFILE="open-horizons"
      HORIZON="all"
      DEPLOYMENT_MODE="enterprise"
      mod_set 0 true; mod_set 1 true
      mod_set 2 true; mod_set 3 true
      mod_set 4 true; mod_set 5 true; mod_set 6 true
      mod_set 7 true; mod_set 8 true; mod_set 9 true
      mod_set 10 true  # foundry_agents (H3, valid: horizon=all + ai_foundry)
      mod_set 11 true  # disaster_recovery
      bs_set 0 true; bs_set 1 true
      bs_set 2 true; bs_set 3 true; bs_set 4 true; bs_set 5 true
      apply_portal_profile_defaults
      SELECTED_PATHS=()
      while IFS= read -r tpl; do SELECTED_PATHS+=("$tpl"); done < <(list_golden_paths)
      ;;
    *)
      log_err "Unknown profile: $profile (use minimal | standard | full)"
      exit "$EXIT_USAGE"
      ;;
  esac
}

# =============================================================================
# Schema validation (T-019)
# =============================================================================

validate_schema() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  if [[ ! -f "$SCHEMA_FILE" ]]; then
    log_warn "Schema file not found at $SCHEMA_FILE, skipping schema check."
    return 0
  fi
  python3 - "$file" "$SCHEMA_FILE" <<'PY' || return 1
import json, re, sys
try:
    import yaml
except ImportError:
    print("[schema] PyYAML not available; doing minimal manual checks", file=sys.stderr)
    yaml = None

manifest_path, schema_path = sys.argv[1], sys.argv[2]
with open(schema_path) as f:
    schema = json.load(f)

if yaml is None:
    # Manual checks: required keys + secret-like keys forbidden
    with open(manifest_path) as f:
        text = f.read()
    forbidden = re.compile(r'^\s*(secret_|token_|password_|key_)', re.MULTILINE)
    if forbidden.search(text):
        print("[schema] forbidden secret-like key detected", file=sys.stderr)
        sys.exit(2)
    for key in schema.get('required', []):
        if not re.search(rf'^\s*{re.escape(key)}\s*:', text, re.MULTILINE):
            print(f"[schema] missing required top-level key: {key}", file=sys.stderr)
            sys.exit(2)
    sys.exit(0)

with open(manifest_path) as f:
    data = yaml.safe_load(f) or {}

errors = []
for key in schema.get('required', []):
    if key not in data:
        errors.append(f"missing required key: {key}")
allowed_top = set(schema.get('properties', {}).keys())
for key in data.keys():
    if key not in allowed_top:
        errors.append(f"unknown top-level key: {key}")
    if re.match(r'^(secret_|token_|password_|key_)', key):
        errors.append(f"forbidden secret-like key: {key}")

# Enum checks
for key in ('horizon', 'environment', 'deployment_mode'):
    if key in data and 'enum' in schema['properties'].get(key, {}):
        allowed = schema['properties'][key]['enum']
        if data[key] not in allowed:
            errors.append(f"{key}={data[key]!r} not in {allowed}")

if errors:
    for e in errors:
        print(f"[schema] {e}", file=sys.stderr)
    sys.exit(2)
PY
}

# =============================================================================
# Validators (T-006)
# =============================================================================

validate_dependencies() {
  local err=0
  local i_aif i_fa i_dr i_chat i_api i_mcp
  i_aif=$(index_of enable_ai_foundry "${MODULE_KEYS[@]}") || true
  i_fa=$(index_of enable_foundry_agents "${MODULE_KEYS[@]}") || true
  i_dr=$(index_of enable_disaster_recovery "${MODULE_KEYS[@]}") || true
  i_chat=$(index_of enable_ai_chat_plugin "${BACKSTAGE_KEYS[@]}") || true
  i_api=$(index_of enable_agent_api "${BACKSTAGE_KEYS[@]}") || true
  i_mcp=$(index_of enable_mcp_ecosystem "${BACKSTAGE_KEYS[@]}") || true

  if [[ -n "$i_aif" && "${MODULE_VALS[$i_aif]}" == "true" ]]; then
    if [[ "$HORIZON" != "h3" && "$HORIZON" != "all" ]]; then
      log_err "[RULE-001] enable_ai_foundry=true requires --horizon h3 or all."
      err=1
    fi
  fi
  if [[ -n "$i_fa" && "${MODULE_VALS[$i_fa]}" == "true" ]]; then
    if [[ "$HORIZON" != "h3" && "$HORIZON" != "all" ]]; then
      log_err "[RULE-001b] enable_foundry_agents=true requires --horizon h3 or all."
      err=1
    fi
    if [[ -n "$i_aif" && "${MODULE_VALS[$i_aif]}" != "true" ]]; then
      log_err "[RULE-001c] enable_foundry_agents=true requires enable_ai_foundry=true (the L6 gateway fronts Azure AI Foundry)."
      err=1
    fi
  fi
  if [[ -n "$i_chat" && "${BACKSTAGE_VALS[$i_chat]}" == "true" \
     && -n "$i_api"  && "${BACKSTAGE_VALS[$i_api]}" != "true" ]]; then
    log_err "[RULE-002] enable_ai_chat_plugin=true requires enable_agent_api=true."
    err=1
  fi
  if [[ -n "$i_mcp" && "${BACKSTAGE_VALS[$i_mcp]}" == "true" ]]; then
    local mcp_found=false
    for tpl in "${SELECTED_PATHS[@]}"; do
      if [[ "$tpl" == *"/mcp-"* ]]; then mcp_found=true; break; fi
    done
    if ! $mcp_found; then
      log_err "[RULE-003] enable_mcp_ecosystem=true requires at least one mcp-* Golden Path selected."
      err=1
    fi
  fi
  local i_ai_impact
  i_ai_impact=$(index_of enable_agent_api_impact "${BACKSTAGE_KEYS[@]}") || true
  if [[ -n "$i_ai_impact" && "${FEATURE_PACK_VALS[4]}" == "true" && "${BACKSTAGE_VALS[$i_ai_impact]}" != "true" ]]; then
    log_err "[RULE-005] enable_ai_impact=true requires enable_agent_api_impact=true."
    err=1
  fi
  if [[ -n "$i_dr" && "${MODULE_VALS[$i_dr]}" == "true" && "$DEPLOYMENT_MODE" == "express" ]]; then
    log_err "[RULE-004] enable_disaster_recovery=true requires deployment_mode standard or enterprise."
    err=1
  fi

  # Specky 002 - validate primitive ids exist on disk (REQ-AGENTS/SKILLS/PROMPTS/MCP-001)
  local available
  if [[ ${#SELECTED_AGENTS[@]} -gt 0 ]]; then
    available="$(list_agents)"
    validate_primitive_ids "agent" "$available" "${SELECTED_AGENTS[@]}" || err=1
  fi
  if [[ ${#SELECTED_SKILLS[@]} -gt 0 ]]; then
    available="$(list_skills)"
    validate_primitive_ids "skill" "$available" "${SELECTED_SKILLS[@]}" || err=1
  fi
  if [[ ${#SELECTED_PROMPTS[@]} -gt 0 ]]; then
    available="$(list_prompts)"
    validate_primitive_ids "prompt" "$available" "${SELECTED_PROMPTS[@]}" || err=1
  fi
  if [[ ${#SELECTED_MCP[@]} -gt 0 ]]; then
    available="$(list_mcp_servers)"
    validate_primitive_ids "mcp_server" "$available" "${SELECTED_MCP[@]}" || err=1
  fi
  return $err
}

# =============================================================================
# Diff/confirm (T-009)
# =============================================================================

diff_and_confirm() {
  local old_file="$1" new_file="$2"
  if [[ ! -f "$old_file" ]]; then
    if $DRY_RUN; then
      log "--dry-run set, would create $old_file"
      return 1
    fi
    log "New file: $old_file"
    if $FORCE || $AUTO; then return 0; fi
    read -r -p "Create $old_file? [y/N]: " ans
    ans="$(lowercase "$ans")"
    [[ "$ans" == "y" || "$ans" == "yes" ]]
    return $?
  fi
  if cmp -s "$old_file" "$new_file"; then
    log "No changes for $old_file"
    return 1   # Signal "skip write"
  fi
  echo
  log "Diff for $old_file:"
  diff -u "$old_file" "$new_file" || true
  echo
  if $DRY_RUN; then
    log "--dry-run set, not writing $old_file"
    return 1
  fi
  if $FORCE || $AUTO; then return 0; fi
  read -r -p "Apply changes to $old_file? [y/N]: " ans
  ans="$(lowercase "$ans")"
  [[ "$ans" == "y" || "$ans" == "yes" ]]
}

# =============================================================================
# Manifest writer (T-007 helper, REQ-OUTPUT-001)
# =============================================================================

build_manifest_yaml() {
  local out="$1"
  {
    echo "# Open Horizons selection manifest"
    echo "# Generated by scripts/install-wizard.sh"
    echo "# Do not store secrets here. Read sensitive values from TF_VAR_* env vars."
    echo "horizon: $HORIZON"
    echo "environment: $ENVIRONMENT"
    echo "deployment_mode: $DEPLOYMENT_MODE"
    echo "portal_profile: $PORTAL_PROFILE"
    echo "branding_profile: $BRANDING_PROFILE"
    echo "modules:"
    local i
    for i in "${!MODULE_KEYS[@]}"; do
      echo "  ${MODULE_KEYS[$i]}: ${MODULE_VALS[$i]}"
    done
    echo "backstage_components:"
    for i in "${!BACKSTAGE_KEYS[@]}"; do
      echo "  ${BACKSTAGE_KEYS[$i]}: ${BACKSTAGE_VALS[$i]}"
    done
    echo "feature_packs:"
    for i in "${!FEATURE_PACK_KEYS[@]}"; do
      echo "  ${FEATURE_PACK_KEYS[$i]}: ${FEATURE_PACK_VALS[$i]}"
    done
    echo "golden_paths:"
    if [[ ${#SELECTED_PATHS[@]} -eq 0 ]]; then
      echo "  []"
    else
      for tpl in "${SELECTED_PATHS[@]}"; do
        echo "  - $tpl"
      done
    fi
    _emit_list "agents" SELECTED_AGENTS
    _emit_list "skills" SELECTED_SKILLS
    _emit_list "prompts" SELECTED_PROMPTS
    _emit_list "mcp_servers" SELECTED_MCP
  } > "$out"
}

_emit_list() {
  local key="$1" arr_name="$2"
  eval "local len=\${#${arr_name}[@]}"
  echo "$key:"
  if [[ "$len" -eq 0 ]]; then
    echo "  []"
  else
    eval "for v in \"\${${arr_name}[@]}\"; do echo \"  - \$v\"; done"
  fi
}

# =============================================================================
# tfvars renderer (T-007)
# =============================================================================

render_tfvars() {
  local target="$REPO_ROOT/terraform/environments/${ENVIRONMENT}.tfvars"
  local tmp; tmp="$(mktemp)"

  if [[ -f "$target" ]]; then
    cp "$target" "$tmp"
  else
    if [[ ! -f "$TFVARS_EXAMPLE" ]]; then
      log_err "Missing template: $TFVARS_EXAMPLE"
      return 1
    fi
    cp "$TFVARS_EXAMPLE" "$tmp"
  fi

  python3 - "$tmp" "$ENVIRONMENT" "$DEPLOYMENT_MODE" \
    "${MODULE_KEYS[@]}" "::sep::" \
    "${BACKSTAGE_KEYS[@]}" <<'PY' || return 1
import re, sys
path, environment, deployment_mode, *rest = sys.argv[1:]
sep_idx = rest.index('::sep::')
module_keys = rest[:sep_idx]
backstage_keys = rest[sep_idx + 1:]

with open(path) as f:
    text = f.read()

import os
mod_vals = {k: os.environ[f'WIZ_MODULE_{k}'] for k in module_keys}
bs_vals  = {k: os.environ[f'WIZ_BACKSTAGE_{k}'] for k in backstage_keys}

def upsert(text, key, value, header=None):
    pattern = re.compile(rf'^(\s*){re.escape(key)}\s*=.*$', re.MULTILINE)
    line = f'{key} = {value}'
    if pattern.search(text):
        return pattern.sub(line, text, count=1)
    sep = '' if text.endswith('\n') else '\n'
    block = f'\n{header}\n{line}\n' if header else f'\n{line}\n'
    return text + sep + block

text = upsert(text, 'environment', f'"{environment}"')
text = upsert(text, 'deployment_mode', f'"{deployment_mode}"')
for k, v in mod_vals.items():
    text = upsert(text, k, v)
for k, v in bs_vals.items():
    text = upsert(text, k, v, header='# --- BACKSTAGE COMPONENTS (managed by install-wizard.sh) ---')

with open(path, 'w') as f:
    f.write(text)
PY

  if diff_and_confirm "$target" "$tmp"; then
    if [[ -f "$target" ]]; then
      cp "$target" "${target}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
    fi
    mv "$tmp" "$target"
    log_ok "Wrote $target"
  else
    rm -f "$tmp"
  fi
}

# =============================================================================
# app-config renderer (T-008)
# =============================================================================

render_app_config() {
  if [[ ${#SELECTED_PATHS[@]} -eq 0 ]]; then
    log_warn "No Golden Paths selected; skipping app-config regeneration."
    return 0
  fi
  if [[ ! -f "$APP_CONFIG" ]]; then
    log_warn "Missing $APP_CONFIG; skipping."
    return 0
  fi

  local tmp; tmp="$(mktemp)"
  # Determine plugin toggles for the python filter (REQ-PLUGIN-001).
  local i_chat i_impact
  i_chat=$(index_of enable_ai_chat_plugin "${BACKSTAGE_KEYS[@]}")
  i_impact=$(index_of enable_agent_api_impact "${BACKSTAGE_KEYS[@]}")
  local chat_enabled="true" impact_enabled="false"
  [[ -n "$i_chat" ]]   && chat_enabled="${BACKSTAGE_VALS[$i_chat]}"
  [[ -n "$i_impact" ]] && impact_enabled="${BACKSTAGE_VALS[$i_impact]}"

    WIZ_CHAT_ENABLED="$chat_enabled" WIZ_IMPACT_ENABLED="$impact_enabled" \
    python3 -c 'import sys, textwrap; exec(textwrap.dedent(sys.stdin.read()))' \
      "$APP_CONFIG" "$tmp" "${SELECTED_PATHS[@]}" <<'PY' || return 1
  import os
  import re
  import sys

  src, dst, *paths = sys.argv[1:]
  allowed = set(paths)
  chat_enabled = os.environ.get("WIZ_CHAT_ENABLED", "true") == "true"
  impact_enabled = os.environ.get("WIZ_IMPACT_ENABLED", "false") == "true"

  with open(src) as f:
      lines = f.readlines()


  def golden_path_blocks(paths):
      out = ["    # Golden Path Templates (managed by install-wizard.sh)\n"]
      for path in sorted(paths):
          out.extend([
              "    - type: url\n",
              "      target: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/blob/${GITHUB_BRANCH:-main}/golden-paths/%s/template.yaml\n" % path,
              "      rules:\n",
              "        - allow: [Template]\n",
          ])
      return out


  out = []
  i = 0
  n = len(lines)
  inserted_golden_paths = False

  while i < n:
      line = lines[i]
      stripped = line.lstrip()

      if "Golden Path Templates" in stripped:
        i += 1
        continue

      if stripped == "locations:\n" and not inserted_golden_paths:
          out.append(line)
          out.extend(golden_path_blocks(allowed))
          inserted_golden_paths = True
          i += 1
          continue

      if stripped.startswith("- type: url"):
          block = [line]
          j = i + 1
          while j < n and (
              not lines[j].lstrip().startswith("- ")
              or lines[j].lstrip().startswith("- allow:")
          ):
              block.append(lines[j])
              j += 1
          target_line = next((bl for bl in block if "target:" in bl), "")
          m = re.search(r"golden-paths/(?P<id>[^/]+/[^/]+)/template\.yaml", target_line)
          if not m:
              out.extend(block)
          i = j
          continue

      if stripped.startswith("'/agent-api'") and not chat_enabled:
          i += 4
          continue
      if stripped.startswith("'/ai-impact'") and not impact_enabled:
          i += 4
          continue

      out.append(line)
      i += 1

  if not inserted_golden_paths:
      out.extend(["\ncatalog:\n", "  locations:\n"])
      out.extend(golden_path_blocks(allowed))

  with open(dst, "w") as f:
      f.writelines(out)
PY

  if diff_and_confirm "$APP_CONFIG" "$tmp"; then
    cp "$APP_CONFIG" "${APP_CONFIG}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
    mv "$tmp" "$APP_CONFIG"
    log_ok "Wrote $APP_CONFIG"
  else
    rm -f "$tmp"
  fi
}

# =============================================================================
# Validators post-write (T-010)
# =============================================================================

run_validators() {
  local rc=0
  if [[ "${WIZARD_SKIP_VALIDATORS:-}" == "1" ]]; then
    log_warn "WIZARD_SKIP_VALIDATORS=1, skipping post-write validators."
    return 0
  fi
  if [[ -x "$REPO_ROOT/scripts/validate-scaffolder-templates.sh" ]]; then
    log "Running validate-scaffolder-templates.sh"
    "$REPO_ROOT/scripts/validate-scaffolder-templates.sh" golden-paths || rc=$?
  fi
  return $rc
}

persist_audit() {
  local sha
  if command -v shasum >/dev/null 2>&1; then
    sha="$(shasum -a 256 "$MANIFEST_FILE" | awk '{print $1}')"
  else
    sha="$(sha256sum "$MANIFEST_FILE" | awk '{print $1}')"
  fi
  printf '%s %s %s sha256=%s\n' "$(iso_now)" "${USER:-unknown}" "$ENVIRONMENT" "$sha" >> "$HISTORY_FILE"
}

# =============================================================================
# Primitive renderer (Specky 002)
# =============================================================================

render_primitives() {
  local source="$REPO_ROOT/golden-paths/common/agents"
  local target="$source/.rendered"
  if [[ ! -d "$source" ]]; then
    log_warn "Skipping primitive render: $source not found."
    return 0
  fi
  rm -rf "$target"
  mkdir -p "$target/.github/agents" "$target/.github/skills" "$target/.github/prompts" "$target/mcp-servers"

  _render_filter() {
    local kind="$1" src_dir="$2" out_dir="$3" suffix="$4" arr_name="$5"
    [[ ! -d "$src_dir" ]] && return 0
    eval "local sel_count=\${#${arr_name}[@]}"
    local include_all=false
    [[ "$sel_count" -eq 0 ]] && include_all=true
    local f base id keep
    while IFS= read -r f; do
      base="$(basename "$f")"
      id="${base%${suffix}}"
      keep=$include_all
      if ! $include_all; then
        eval "for v in \"\${${arr_name}[@]}\"; do [[ \"\$v\" == \"$id\" ]] && keep=true; done"
      fi
      $keep && cp "$f" "$out_dir/"
    done < <(find "$src_dir" -maxdepth 1 -type f -name "*${suffix}")
  }

  # Agents from .github/agents
  if [[ -d "$REPO_ROOT/.github/agents" ]]; then
    _render_filter agents "$REPO_ROOT/.github/agents" "$target/.github/agents" ".agent.md" SELECTED_AGENTS
  fi
  # Prompts from .github/prompts
  if [[ -d "$REPO_ROOT/.github/prompts" ]]; then
    _render_filter prompts "$REPO_ROOT/.github/prompts" "$target/.github/prompts" ".prompt.md" SELECTED_PROMPTS
  fi
  # Skills are folders; copy whole folder when included
  if [[ -d "$REPO_ROOT/.github/skills" ]]; then
    local include_all=false
    [[ ${#SELECTED_SKILLS[@]} -eq 0 ]] && include_all=true
    local f base
    while IFS= read -r f; do
      base="$(basename "$f")"
      local keep=$include_all
      if ! $include_all; then
        for v in "${SELECTED_SKILLS[@]}"; do [[ "$v" == "$base" ]] && keep=true; done
      fi
      $keep && cp -R "$f" "$target/.github/skills/"
    done < <(find "$REPO_ROOT/.github/skills" -mindepth 1 -maxdepth 1 -type d)
  fi
  # MCP servers selection emitted as a ConfigMap-style file consumed by render-manifests when the ecosystem is enabled.
  if [[ ${#SELECTED_MCP[@]} -gt 0 ]]; then
    {
      echo "# MCP servers selected by install-wizard. Used by render-manifests.sh."
      for s in "${SELECTED_MCP[@]}"; do echo "$s"; done
    } > "$target/mcp-servers/enabled.txt"
  fi

  log_ok "Rendered primitives to $target"
}

# =============================================================================
# Handoff (T-012, T-013)
# =============================================================================

emit_handoff() {
  echo
  log_ok "Selection complete."
  log "Recommended next commands:"
  echo "  ./scripts/deploy-full.sh --environment $ENVIRONMENT --horizon $HORIZON"

  local needs_oidc=false
  local i
  for i in "${!MODULE_KEYS[@]}"; do
    [[ "${MODULE_VALS[$i]}" == "true" ]] && needs_oidc=true && break
  done
  if $needs_oidc; then
    local org_default
    org_default="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null | sed -E 's|.*github.com[:/]([^/]+)/.*|\1|')"
    org_default="${org_default:-Ohorizons}"
    echo "  ./scripts/setup-identity-federation.sh \\"
    echo "    --github-org $org_default \\"
    echo "    --github-repo open-horizons-platform \\"
    echo "    --resource-group rg-${ENVIRONMENT}-openhorizons"
  fi

  if [[ "$NEXT_STEP" == "deploy" ]]; then
    # Render K8s manifests first
    if [[ -f "$REPO_ROOT/.env" ]]; then
      log "Rendering K8s manifests before deployment..."
      "$REPO_ROOT/scripts/render-k8s.sh" --env-file "$REPO_ROOT/.env" || { log_err "render failed"; exit "$EXIT_VALIDATOR"; }
    fi
    log "--next-step deploy was set; handing off to deploy-full.sh"
    local extra=()
    $AUTO && extra+=(--auto-approve)
    exec "$REPO_ROOT/scripts/deploy-full.sh" --environment "$ENVIRONMENT" --horizon "$HORIZON" "${extra[@]}"
  fi
}

# =============================================================================
# Phase 0: Initial Setup — Platform Identity & Configuration
# =============================================================================
# Collects org-specific configuration and writes to .env file.
# This phase runs BEFORE module/component selection.
# =============================================================================

prompt_initial_setup() {
  $AUTO && return  # In auto mode, .env must already exist

  local env_file="$REPO_ROOT/.env"
  if [[ -f "$env_file" ]]; then
    log "Found existing .env — loading configuration"
    # shellcheck disable=SC1090
    source "$env_file"
    local do_reconfigure
    do_reconfigure="$(prompt_yn "Reconfigure platform settings?" "false")"
    [[ "$do_reconfigure" == "false" ]] && return
  fi

  echo
  echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}  Phase 0: Platform Setup${NC}"
  echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
  echo

  # --- Platform Identity ---
  log "${BOLD}Platform Identity${NC}"
  local github_org_default
  github_org_default="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null | sed -E 's|.*github.com[:/]([^/]+)/.*|\1|')"
  github_org_default="${github_org_default:-}"

  read -r -p "  GitHub Organization [$github_org_default]: " GITHUB_ORG
  GITHUB_ORG="${GITHUB_ORG:-$github_org_default}"

  local repo_default
  repo_default="$(basename "$REPO_ROOT")"
  read -r -p "  GitHub Repository [$repo_default]: " GITHUB_REPO
  GITHUB_REPO="${GITHUB_REPO:-$repo_default}"

  read -r -p "  Platform name [openhorizons]: " PLATFORM_NAME
  PLATFORM_NAME="${PLATFORM_NAME:-openhorizons}"

  read -r -p "  Organization display name [$GITHUB_ORG]: " ORG_DISPLAY_NAME
  ORG_DISPLAY_NAME="${ORG_DISPLAY_NAME:-$GITHUB_ORG}"

  read -r -p "  Custom domain [openhorizons.example.com]: " DOMAIN
  DOMAIN="${DOMAIN:-openhorizons.example.com}"

  read -r -p "  Admin email [admin@${DOMAIN:-example.com}]: " ADMIN_EMAIL
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN:-example.com}}"

  echo

  # --- Authentication ---
  log "${BOLD}Authentication Provider${NC}"
  AUTH_PROVIDER="$(prompt_choice "  Auth provider" "github" github entra guest)"

  echo

  # --- Container Registry ---
  log "${BOLD}Container Images${NC}"
  CONTAINER_REGISTRY="$(prompt_choice "  Registry" "ghcr" ghcr acr dockerhub)"

  if [[ "$CONTAINER_REGISTRY" == "ghcr" ]]; then
    BACKSTAGE_IMAGE="ghcr.io/ohorizons/ohorizons-backstage"
    AGENT_API_IMAGE="ghcr.io/ohorizons/ohorizons-agent-api"
    AGENT_API_IMPACT_IMAGE="ghcr.io/ohorizons/ohorizons-agent-api-impact"
    MCP_ECOSYSTEM_IMAGE="ghcr.io/ohorizons/mcp-ecosystem"
  elif [[ "$CONTAINER_REGISTRY" == "acr" ]]; then
    read -r -p "  ACR name (e.g., myacr): " ACR_NAME
    BACKSTAGE_IMAGE="${ACR_NAME}.azurecr.io/ohorizons-backstage"
    AGENT_API_IMAGE="${ACR_NAME}.azurecr.io/ohorizons-agent-api"
    AGENT_API_IMPACT_IMAGE="${ACR_NAME}.azurecr.io/ohorizons-agent-api-impact"
    MCP_ECOSYSTEM_IMAGE="${ACR_NAME}.azurecr.io/mcp-ecosystem"
  fi

  read -r -p "  Image tag [v7.2.4]: " IMAGE_TAG
  IMAGE_TAG="${IMAGE_TAG:-v7.2.4}"

  echo

  # --- Azure Infrastructure ---
  log "${BOLD}Azure Infrastructure${NC}"
  read -r -p "  Azure Subscription ID: " AZURE_SUBSCRIPTION_ID
  read -r -p "  Resource Group: " AZURE_RESOURCE_GROUP
  read -r -p "  Azure Location [eastus2]: " AZURE_LOCATION
  AZURE_LOCATION="${AZURE_LOCATION:-eastus2}"
  read -r -p "  AKS Cluster Name: " AKS_CLUSTER_NAME

  echo

  # --- AI Services (optional) ---
  local enable_ai
  enable_ai="$(prompt_yn "  Enable AI services (Chat & Impact plugins)?" "true")"
  if [[ "$enable_ai" == "true" ]]; then
    read -r -p "  Azure OpenAI Endpoint: " AZURE_OPENAI_ENDPOINT
    read -r -p "  Azure OpenAI Deployment [gpt-4o]: " AZURE_OPENAI_DEPLOYMENT
    AZURE_OPENAI_DEPLOYMENT="${AZURE_OPENAI_DEPLOYMENT:-gpt-4o}"
  fi

  # --- Write .env ---
  log "Writing configuration to .env"
  cat > "$env_file" << ENVFILE
# =============================================================================
# Open Horizons Platform Configuration
# Generated by install-wizard.sh on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# =============================================================================

# Platform Identity
PLATFORM_NAME=${PLATFORM_NAME}
DOMAIN=${DOMAIN}
ADMIN_EMAIL=${ADMIN_EMAIL}
ORG_DISPLAY_NAME="${ORG_DISPLAY_NAME}"

# GitHub Integration
GITHUB_ORG=${GITHUB_ORG}
GITHUB_REPO=${GITHUB_REPO}
GITHUB_TOKEN=

# Authentication (github | entra | guest)
AUTH_PROVIDER=${AUTH_PROVIDER}
GITHUB_APP_CLIENT_ID=
GITHUB_APP_CLIENT_SECRET=
ENTRA_TENANT_ID=
ENTRA_CLIENT_ID=
ENTRA_CLIENT_SECRET=

# Container Images
CONTAINER_REGISTRY=${CONTAINER_REGISTRY}
BACKSTAGE_IMAGE=${BACKSTAGE_IMAGE:-ghcr.io/ohorizons/ohorizons-backstage}
AGENT_API_IMAGE=${AGENT_API_IMAGE:-ghcr.io/ohorizons/ohorizons-agent-api}
AGENT_API_IMPACT_IMAGE=${AGENT_API_IMPACT_IMAGE:-ghcr.io/ohorizons/ohorizons-agent-api-impact}
MCP_ECOSYSTEM_IMAGE=${MCP_ECOSYSTEM_IMAGE:-ghcr.io/ohorizons/mcp-ecosystem}
IMAGE_TAG=${IMAGE_TAG}

# Azure Infrastructure
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP:-}
AZURE_LOCATION=${AZURE_LOCATION}
AKS_CLUSTER_NAME=${AKS_CLUSTER_NAME:-}

# AI Services
AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT:-}
AZURE_OPENAI_API_KEY=
AZURE_OPENAI_DEPLOYMENT=${AZURE_OPENAI_DEPLOYMENT:-gpt-4o}

# Observability
ARGOCD_AUTH_TOKEN=
GRAFANA_TOKEN=

# Backstage Backend
BACKEND_SECRET=
ENVFILE

  log_ok "Configuration saved to .env"
  log_warn "⚠  Edit .env to add sensitive values (tokens, secrets, API keys)"
  echo

  # --- Render K8s manifests ---
  local do_render
  do_render="$(prompt_yn "  Render K8s manifests now?" "true")"
  if [[ "$do_render" == "true" ]]; then
    "$REPO_ROOT/scripts/render-k8s.sh" --env-file "$env_file"
  fi
}

# =============================================================================
# Main
# =============================================================================

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --environment|-e)     ENVIRONMENT="$2"; shift 2 ;;
      --horizon|-h)         HORIZON="$2"; shift 2 ;;
      --deployment-mode)    DEPLOYMENT_MODE="$2"; shift 2 ;;
      --portal-profile)     PORTAL_PROFILE="$2"; PORTAL_PROFILE_EXPLICIT=true; shift 2 ;;
      --branding-profile)   BRANDING_PROFILE="$2"; shift 2 ;;
      --auto)               AUTO=true; shift ;;
      --selection-file)     SELECTION_FILE="$2"; shift 2 ;;
      --dry-run)            DRY_RUN=true; shift ;;
      --next-step)          NEXT_STEP="$2"; shift 2 ;;
      --force)              FORCE=true; shift ;;
      --profile)            PROFILE="$2"; shift 2 ;;
      --help|-?)            usage; exit 0 ;;
      *)                    log_err "Unknown flag: $1"; usage; exit "$EXIT_USAGE" ;;
    esac
  done
  if $AUTO && [[ -z "$SELECTION_FILE" ]]; then
    SELECTION_FILE="$MANIFEST_FILE"
  fi
}

main() {
  parse_args "$@"

  require_cmd yq      || exit "$EXIT_USAGE"
  require_cmd python3 || exit "$EXIT_USAGE"

  # Phase 0: Initial platform setup (org, domain, auth, registry)
  prompt_initial_setup

  load_manifest "${SELECTION_FILE:-$MANIFEST_FILE}"

  # Validate input manifest schema BEFORE normalization (REQ-OUTPUT-004 + schema)
  if [[ -n "$SELECTION_FILE" && -f "$SELECTION_FILE" ]]; then
    if ! validate_schema "$SELECTION_FILE"; then
      log_err "Input manifest failed schema validation."
      exit "$EXIT_RULE"
    fi
  fi

  apply_profile "$PROFILE"

  prompt_environment
  prompt_horizon_choice
  prompt_deployment_mode_choice
  prompt_portal_profile_choice
  prompt_branding_profile_choice
  prompt_modules
  prompt_backstage
  prompt_paths

  # Export for python helpers
  local i
  for i in "${!MODULE_KEYS[@]}";    do export "WIZ_MODULE_${MODULE_KEYS[$i]}=${MODULE_VALS[$i]}"; done
  for i in "${!BACKSTAGE_KEYS[@]}"; do export "WIZ_BACKSTAGE_${BACKSTAGE_KEYS[$i]}=${BACKSTAGE_VALS[$i]}"; done

  if ! validate_dependencies; then
    log_err "Dependency rules failed; no files written."
    exit "$EXIT_RULE"
  fi

  # Build candidate manifest first to drive diffs and audit hash
  local manifest_tmp; manifest_tmp="$(mktemp)"
  build_manifest_yaml "$manifest_tmp"

  if ! validate_schema "$manifest_tmp"; then
    log_err "Schema validation failed; manifest rejected."
    rm -f "$manifest_tmp"
    exit "$EXIT_RULE"
  fi

  if $DRY_RUN; then
    log "--dry-run: would persist the following manifest"
    cat "$manifest_tmp"
    rm -f "$manifest_tmp"
    log "--dry-run: skipping tfvars/app-config rendering and validators"
    log "Re-run without --dry-run to apply changes."
    exit 0
  fi

  if diff_and_confirm "$MANIFEST_FILE" "$manifest_tmp"; then
    [[ -f "$MANIFEST_FILE" ]] && cp "$MANIFEST_FILE" "${MANIFEST_FILE}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
    mv "$manifest_tmp" "$MANIFEST_FILE"
    log_ok "Wrote $MANIFEST_FILE"
  else
    rm -f "$manifest_tmp"
    if [[ -f "$MANIFEST_FILE" ]]; then
      log_ok "Manifest already up to date. No changes needed."
      exit 0
    fi
    log_warn "User declined manifest write. Aborting."
    exit "$EXIT_ABORT"
  fi

  render_tfvars     || { log_err "tfvars render failed"; exit "$EXIT_VALIDATOR"; }
  render_app_config || { log_err "app-config render failed"; exit "$EXIT_VALIDATOR"; }
  render_primitives || { log_err "primitive render failed"; exit "$EXIT_VALIDATOR"; }

  if ! run_validators; then
    log_err "Post-write validation failed. Inspect *.bak.* files to recover."
    exit "$EXIT_VALIDATOR"
  fi

  persist_audit
  emit_handoff
}

main "$@"
