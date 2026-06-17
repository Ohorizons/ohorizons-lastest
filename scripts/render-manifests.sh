#!/usr/bin/env bash
# =============================================================================
# OPEN HORIZONS - RENDER BACKSTAGE MANIFESTS BASED ON SELECTION
# =============================================================================
#
# Reads .openhorizons-selection.yaml and copies the manifests in
# backstage/k8s/ that match the enabled Backstage components into
# backstage/k8s/.rendered/. The rendered directory is what
# deploy-full.sh applies to the cluster.
#
# Usage:
#   scripts/render-manifests.sh                       # uses repo manifest
#   scripts/render-manifests.sh --selection <path>
#   scripts/render-manifests.sh --output <dir>
#   scripts/render-manifests.sh --dry-run             # print plan only
#
# Maps each manifest file to a wizard flag. When the flag is true the file is
# included; when it is false the file is left out. Files not in the map are
# always included (Backstage core).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi
log()      { echo -e "${BLUE}[render]${NC} $*"; }
log_ok()   { echo -e "${GREEN}[render]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[render]${NC} $*"; }
log_err()  { echo -e "${RED}[render]${NC} $*" >&2; }

SELECTION_FILE="$REPO_ROOT/.openhorizons-selection.yaml"
SOURCE_DIR="$REPO_ROOT/backstage/k8s"
OUTPUT_DIR="$SOURCE_DIR/.rendered"
ENV_FILE="$REPO_ROOT/.env"
DRY_RUN=false
RENDER_SOURCE_DIR=""

usage() {
  cat <<EOF
Usage: scripts/render-manifests.sh [options]

Options:
  --selection <path>   Path to selection manifest (default: .openhorizons-selection.yaml).
  --env-file <path>    Path to env file for template fallback rendering (default: .env).
  --source <dir>       Source manifests dir (default: backstage/k8s).
  --output <dir>       Render dir (default: backstage/k8s/.rendered).
  --dry-run            Print include/exclude plan, do not write.
  -h, --help           Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --selection) SELECTION_FILE="$2"; shift 2 ;;
    --env-file)  ENV_FILE="$2"; shift 2 ;;
    --source)    SOURCE_DIR="$2"; shift 2 ;;
    --output)    OUTPUT_DIR="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           log_err "Unknown flag: $1"; usage; exit 1 ;;
  esac
done

if ! command -v yq >/dev/null 2>&1; then
  log_err "yq is required."
  exit 1
fi

cleanup() {
  if [[ -n "$RENDER_SOURCE_DIR" && -d "$RENDER_SOURCE_DIR" ]]; then
    rm -rf "$RENDER_SOURCE_DIR"
  fi
}
trap cleanup EXIT

if [[ ! -d "$SOURCE_DIR" ]]; then
  log_err "Source dir not found: $SOURCE_DIR"
  exit 1
fi

read_flag() {
  # $1 = key, $2 = default
  local key="$1" default="$2" raw
  if [[ ! -f "$SELECTION_FILE" ]]; then
    echo "$default"; return
  fi
  raw="$(yq ".backstage_components.$key" "$SELECTION_FILE" 2>/dev/null || echo "")"
  if [[ "$raw" == "null" || -z "$raw" ]]; then
    echo "$default"
  else
    echo "$raw"
  fi
}

ENABLE_AGENT_API="$(read_flag enable_agent_api true)"
ENABLE_AGENT_API_IMPACT="$(read_flag enable_agent_api_impact false)"
ENABLE_MCP_ECOSYSTEM="$(read_flag enable_mcp_ecosystem false)"

declare_enabled() {
  local file="$1" enabled="$2"
  if [[ "$enabled" == "true" ]]; then
    log_ok "include $file"
  else
    log_warn "skip    $file (flag off)"
  fi
}

# File -> required flag (true means always include)
FILE_FLAGS=(
  "namespace.yaml=true"
  "configmap.yaml=true"
  "deployment.yaml=true"
  "service.yaml=true"
  "ingress.yaml=true"
  "tls.yaml=true"
  "agent-identity.yaml=true"
  "agent-api-deployment.yaml=$ENABLE_AGENT_API"
  "agent-api-service.yaml=$ENABLE_AGENT_API"
  "agent-api-impact-deployment.yaml=$ENABLE_AGENT_API_IMPACT"
  "mcp-ecosystem-deployment.yaml=$ENABLE_MCP_ECOSYSTEM"
)

render_templates_to_temp_source() {
  local templates_dir="$SOURCE_DIR/templates"
  if [[ ! -d "$templates_dir" ]]; then
    return 1
  fi

  RENDER_SOURCE_DIR="$(mktemp -d)"

  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  else
    log_warn "No env file found at $ENV_FILE; using non-secret smoke-test defaults for template fallback."
  fi

  local platform_name="${PLATFORM_NAME:-openhorizons}"
  local github_org="${GITHUB_ORG:-example-org}"
  local github_repo="${GITHUB_REPO:-$(basename "$REPO_ROOT")}"
  local domain="${DOMAIN:-backstage.example.com}"
  local admin_email="${ADMIN_EMAIL:-admin@example.com}"
  local org_display_name="${ORG_DISPLAY_NAME:-$github_org}"
  local backstage_image="${BACKSTAGE_IMAGE:-ghcr.io/ohorizons/ohorizons-backstage}"
  local agent_api_image="${AGENT_API_IMAGE:-ghcr.io/ohorizons/ohorizons-agent-api}"
  local agent_api_impact_image="${AGENT_API_IMPACT_IMAGE:-ghcr.io/ohorizons/ohorizons-agent-api-impact}"
  local mcp_ecosystem_image="${MCP_ECOSYSTEM_IMAGE:-ghcr.io/ohorizons/mcp-ecosystem}"
  local image_tag="${IMAGE_TAG:-v7.2.4}"
  local azure_openai_deployment="${AZURE_OPENAI_DEPLOYMENT:-gpt-4o}"
  local auth_provider="${AUTH_PROVIDER:-guest}"
  local auth_fragment="$templates_dir/auth-${auth_provider}.yaml.fragment"

  if [[ ! -f "$auth_fragment" ]]; then
    log_warn "Unknown AUTH_PROVIDER '$auth_provider'; using guest auth fragment for fallback render."
    auth_fragment="$templates_dir/auth-guest.yaml.fragment"
  fi

  local sed_expr=""
  add_replacement() {
    local key="$1" val="$2" escaped_val
    escaped_val=$(printf '%s\n' "$val" | sed 's/[&/\]/\\&/g')
    sed_expr="${sed_expr}s|${key}|${escaped_val}|g;"
  }

  add_replacement "__PLATFORM_NAME__" "$platform_name"
  add_replacement "__DOMAIN__" "$domain"
  add_replacement "__ADMIN_EMAIL__" "$admin_email"
  add_replacement "__ORG_DISPLAY_NAME__" "$org_display_name"
  add_replacement "__GITHUB_ORG__" "$github_org"
  add_replacement "__GITHUB_REPO__" "$github_repo"
  add_replacement "__BACKSTAGE_IMAGE__" "$backstage_image"
  add_replacement "__AGENT_API_IMAGE__" "$agent_api_image"
  add_replacement "__AGENT_API_IMPACT_IMAGE__" "$agent_api_impact_image"
  add_replacement "__MCP_ECOSYSTEM_IMAGE__" "$mcp_ecosystem_image"
  add_replacement "__IMAGE_TAG__" "$image_tag"
  add_replacement "__AZURE_OPENAI_DEPLOYMENT__" "$azure_openai_deployment"

  local tmpl filename output content unresolved auth_block
  auth_block="$(cat "$auth_fragment")"
  for tmpl in "$templates_dir"/*.yaml.tmpl; do
    [[ -f "$tmpl" ]] || continue
    filename="$(basename "$tmpl" .tmpl)"
    output="$RENDER_SOURCE_DIR/$filename"
    content="$(sed "$sed_expr" "$tmpl")"
    content="${content/__AUTH_BLOCK__/$auth_block}"
    content="${content//__CATALOG_LOCATIONS__/}"
    unresolved="$(printf '%s' "$content" | grep -oE '__[A-Z0-9_]+__' | sort -u || true)"
    if [[ -n "$unresolved" ]]; then
      log_err "Unresolved template placeholders remain in $filename:"
      printf '%s\n' "$unresolved" >&2
      return 1
    fi
    printf '%s' "$content" > "$output"
  done

  if [[ -f "$SOURCE_DIR/agent-identity.yaml" ]]; then
    cp "$SOURCE_DIR/agent-identity.yaml" "$RENDER_SOURCE_DIR/agent-identity.yaml"
  fi

  SOURCE_DIR="$RENDER_SOURCE_DIR"
  log_warn "Source manifests missing; rendered fallback source from $templates_dir"
}

if [[ ! -f "$SOURCE_DIR/namespace.yaml" ]]; then
  render_templates_to_temp_source || log_warn "Could not render fallback manifests; missing source files will be skipped."
fi

if ! $DRY_RUN; then
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
fi

INCLUDED=()
SKIPPED=()
for entry in "${FILE_FLAGS[@]}"; do
  file="${entry%%=*}"
  flag="${entry#*=}"
  src="$SOURCE_DIR/$file"
  if [[ ! -f "$src" ]]; then
    log_warn "missing $file (in source) - skipping"
    continue
  fi
  declare_enabled "$file" "$flag"
  if [[ "$flag" == "true" ]]; then
    INCLUDED+=("$file")
    if ! $DRY_RUN; then cp "$src" "$OUTPUT_DIR/$file"; fi
  else
    SKIPPED+=("$file")
  fi
done

if ! $DRY_RUN; then
  # Generate kustomization.yaml so kubectl apply -k works.
  {
    echo "apiVersion: kustomize.config.k8s.io/v1beta1"
    echo "kind: Kustomization"
    echo "resources:"
    for f in "${INCLUDED[@]}"; do echo "  - $f"; done
  } > "$OUTPUT_DIR/kustomization.yaml"
  log_ok "Wrote $OUTPUT_DIR/kustomization.yaml"
fi

echo
log "Included: ${#INCLUDED[@]} manifest(s)"
log "Skipped:  ${#SKIPPED[@]} manifest(s)"
$DRY_RUN && log_warn "--dry-run: nothing written."
exit 0
