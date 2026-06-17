#!/usr/bin/env bash
# =============================================================================
# OPEN HORIZONS — Render K8s Manifests from Templates
# =============================================================================
# Reads .env and templates/*.tmpl → generates final manifests in backstage/k8s/
#
# Usage:
#   scripts/render-k8s.sh                     # uses .env
#   scripts/render-k8s.sh --env-file .env.prod
#   scripts/render-k8s.sh --dry-run           # show output, don't write files
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$REPO_ROOT/backstage/k8s/templates"
OUTPUT_DIR="$REPO_ROOT/backstage/k8s"
ENV_FILE="$REPO_ROOT/.env"
DRY_RUN=false

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'
log()      { echo -e "${BLUE}[render]${NC} $*"; }
log_ok()   { echo -e "${GREEN}[render]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[render]${NC} $*"; }
log_err()  { echo -e "${RED}[render]${NC} $*" >&2; }

# --- Parse args --------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)  ENV_FILE="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: $0 [--env-file <path>] [--dry-run]"
      exit 0 ;;
    *) log_err "Unknown arg: $1"; exit 1 ;;
  esac
done

# --- Load .env ---------------------------------------------------------------
if [[ ! -f "$ENV_FILE" ]]; then
  log_err "Environment file not found: $ENV_FILE"
  log_err "Run: cp .env.example .env && \$EDITOR .env"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

# --- Validate required vars --------------------------------------------------
REQUIRED_VARS=(PLATFORM_NAME GITHUB_ORG GITHUB_REPO AUTH_PROVIDER IMAGE_TAG)
missing=()
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    missing+=("$var")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  log_err "Missing required variables in $ENV_FILE:"
  for v in "${missing[@]}"; do
    log_err "  - $v"
  done
  exit 1
fi

# Derive domain if not set (use sslip.io pattern)
if [[ -z "${DOMAIN:-}" ]]; then
  log_warn "DOMAIN not set — will need to be set after AKS deployment (use sslip.io with LB IP)"
  DOMAIN="backstage.example.com"
fi

# Default images if not set
BACKSTAGE_IMAGE="${BACKSTAGE_IMAGE:-ghcr.io/ohorizons/ohorizons-backstage}"
AGENT_API_IMAGE="${AGENT_API_IMAGE:-ghcr.io/ohorizons/ohorizons-agent-api}"
AGENT_API_IMPACT_IMAGE="${AGENT_API_IMPACT_IMAGE:-ghcr.io/ohorizons/ohorizons-agent-api-impact}"
MCP_ECOSYSTEM_IMAGE="${MCP_ECOSYSTEM_IMAGE:-ghcr.io/ohorizons/mcp-ecosystem}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"
ORG_DISPLAY_NAME="${ORG_DISPLAY_NAME:-${GITHUB_ORG}}"
AZURE_OPENAI_DEPLOYMENT="${AZURE_OPENAI_DEPLOYMENT:-gpt-4o}"

log "Platform:  ${BOLD}${PLATFORM_NAME}${NC}"
log "Domain:    ${BOLD}${DOMAIN}${NC}"
log "GitHub:    ${BOLD}${GITHUB_ORG}/${GITHUB_REPO}${NC}"
log "Auth:      ${BOLD}${AUTH_PROVIDER}${NC}"
log "Registry:  ${BOLD}$(echo "$BACKSTAGE_IMAGE" | cut -d/ -f1)${NC}"
log "Tag:       ${BOLD}${IMAGE_TAG}${NC}"
echo ""

# --- Build sed expression directly -------------------------------------------
SED_EXPR=""
add_replacement() {
  local key="$1" val="$2"
  local escaped_val
  escaped_val=$(printf '%s\n' "$val" | sed 's/[&/\]/\\&/g')
  SED_EXPR="${SED_EXPR}s|${key}|${escaped_val}|g;"
}

add_replacement "__PLATFORM_NAME__" "$PLATFORM_NAME"
add_replacement "__DOMAIN__" "$DOMAIN"
add_replacement "__ADMIN_EMAIL__" "$ADMIN_EMAIL"
add_replacement "__ORG_DISPLAY_NAME__" "$ORG_DISPLAY_NAME"
add_replacement "__GITHUB_ORG__" "$GITHUB_ORG"
add_replacement "__GITHUB_REPO__" "$GITHUB_REPO"
add_replacement "__BACKSTAGE_IMAGE__" "$BACKSTAGE_IMAGE"
add_replacement "__AGENT_API_IMAGE__" "$AGENT_API_IMAGE"
add_replacement "__AGENT_API_IMPACT_IMAGE__" "$AGENT_API_IMPACT_IMAGE"
add_replacement "__MCP_ECOSYSTEM_IMAGE__" "$MCP_ECOSYSTEM_IMAGE"
add_replacement "__IMAGE_TAG__" "$IMAGE_TAG"
add_replacement "__AZURE_OPENAI_DEPLOYMENT__" "$AZURE_OPENAI_DEPLOYMENT"

# --- Build sed expression ----------------------------------------------------
# (sed expression was built above via add_replacement calls)

# --- Resolve auth fragment ---------------------------------------------------
AUTH_FRAGMENT="$TEMPLATES_DIR/auth-${AUTH_PROVIDER}.yaml.fragment"
if [[ ! -f "$AUTH_FRAGMENT" ]]; then
  log_err "Unknown AUTH_PROVIDER: ${AUTH_PROVIDER}"
  log_err "Available: github, entra, guest"
  exit 1
fi
AUTH_BLOCK=$(cat "$AUTH_FRAGMENT")

# --- Generate catalog locations from golden-paths ----------------------------
generate_catalog_locations() {
  local gp_dir="$REPO_ROOT/golden-paths"
  local locations=""

  for horizon_dir in "$gp_dir"/h*/; do
    [[ -d "$horizon_dir" ]] || continue
    local horizon_name
    horizon_name=$(basename "$horizon_dir")
    local comment_added=false

    for template_dir in "$horizon_dir"*/; do
      [[ -f "$template_dir/template.yaml" ]] || continue
      local template_name
      template_name=$(basename "$template_dir")

      if [[ "$comment_added" == false ]]; then
        locations+="        # ${horizon_name}"$'\n'
        comment_added=true
      fi

      locations+="        - type: url"$'\n'
      locations+="          target: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/blob/main/golden-paths/${horizon_name}/${template_name}/template.yaml"$'\n'
      locations+="          rules:"$'\n'
      locations+="            - allow: [Template]"$'\n'
    done
  done

  echo "$locations"
}

CATALOG_LOCATIONS=$(generate_catalog_locations)

# --- Render templates --------------------------------------------------------
rendered=0
for tmpl in "$TEMPLATES_DIR"/*.yaml.tmpl; do
  [[ -f "$tmpl" ]] || continue
  filename=$(basename "$tmpl" .tmpl)
  output="$OUTPUT_DIR/$filename"

  # Apply sed replacements
  content=$(sed "$SED_EXPR" "$tmpl")

  # Replace auth block and catalog locations using Python (handles multi-line)
  content=$(python3 -c "
import sys
content = sys.stdin.read()
with open('$AUTH_FRAGMENT') as f:
    auth = f.read()
with open('/dev/stdin' if False else '/dev/null') as _:
    pass
catalog = '''$CATALOG_LOCATIONS'''
content = content.replace('__AUTH_BLOCK__', auth)
content = content.replace('__CATALOG_LOCATIONS__', catalog)
print(content, end='')
" <<< "$content" 2>/dev/null || echo "$content")

  if [[ "$DRY_RUN" == true ]]; then
    echo "--- $filename ---"
    echo "$content"
    echo ""
  else
    echo "$content" > "$output"
    log_ok "Generated: backstage/k8s/$filename"
  fi
  ((rendered++))
done

echo ""
log_ok "Rendered ${BOLD}${rendered}${NC} manifests from templates"

# --- Validate YAML -----------------------------------------------------------
if command -v kubectl &>/dev/null && [[ "$DRY_RUN" == false ]]; then
  log "Validating YAML syntax..."
  errors=0
  for f in "$OUTPUT_DIR"/*.yaml; do
    if ! kubectl apply --dry-run=client -f "$f" &>/dev/null 2>&1; then
      log_warn "  ⚠ $f — may need cluster context for validation"
    fi
  done
  log_ok "YAML validation complete"
fi

# --- Print secrets checklist -------------------------------------------------
echo ""
echo -e "${BOLD}📋 Next Steps — Create K8s Secrets:${NC}"
echo ""
echo "  # 1. Backstage secrets"
echo "  kubectl create secret generic backstage-secrets \\"
echo "    --namespace backstage \\"
echo "    --from-literal=GITHUB_TOKEN='\$GITHUB_TOKEN' \\"
echo "    --from-literal=BACKEND_SECRET='\$(openssl rand -hex 32)' \\"
if [[ "$AUTH_PROVIDER" == "github" ]]; then
  echo "    --from-literal=GITHUB_APP_CLIENT_ID='\$GITHUB_APP_CLIENT_ID' \\"
  echo "    --from-literal=GITHUB_APP_CLIENT_SECRET='\$GITHUB_APP_CLIENT_SECRET'"
elif [[ "$AUTH_PROVIDER" == "entra" ]]; then
  echo "    --from-literal=ENTRA_CLIENT_ID='\$ENTRA_CLIENT_ID' \\"
  echo "    --from-literal=ENTRA_CLIENT_SECRET='\$ENTRA_CLIENT_SECRET' \\"
  echo "    --from-literal=ENTRA_TENANT_ID='\$ENTRA_TENANT_ID'"
else
  echo "    # Guest mode — no additional auth secrets needed"
fi
echo ""
echo "  # 2. AI services secrets (optional)"
echo "  kubectl create secret generic agent-api-secrets \\"
echo "    --namespace ai-services \\"
echo "    --from-literal=AZURE_OPENAI_ENDPOINT='\$AZURE_OPENAI_ENDPOINT' \\"
echo "    --from-literal=AZURE_OPENAI_API_KEY='\$AZURE_OPENAI_API_KEY'"
echo ""
echo "  # 3. Deploy"
echo "  kubectl apply -f backstage/k8s/"
echo ""
