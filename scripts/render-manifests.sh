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
DRY_RUN=false

usage() {
  cat <<EOF
Usage: scripts/render-manifests.sh [options]

Options:
  --selection <path>   Path to selection manifest (default: .openhorizons-selection.yaml).
  --source <dir>       Source manifests dir (default: backstage/k8s).
  --output <dir>       Render dir (default: backstage/k8s/.rendered).
  --dry-run            Print include/exclude plan, do not write.
  -h, --help           Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --selection) SELECTION_FILE="$2"; shift 2 ;;
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
    echo "namespace: backstage"
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
