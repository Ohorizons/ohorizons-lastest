#!/usr/bin/env bash
# =============================================================================
# OPEN HORIZONS — Deploy runtime services without GitHub integration
# =============================================================================
# Deploys the internal AKS runtime layer after Azure H1/H2/H3 infrastructure is
# applied: Backstage in guest mode, Agent API, AI Impact API, and MCP Ecosystem.
# Secrets are created from Azure/Terraform state without printing secret values.
#
# Usage:
#   scripts/deploy-runtime-nogithub.sh \
#     --customer-name contoso \
#     --environment prod \
#     --resource-group rg-contoso-prod \
#     --aks-name aks-contoso-prod \
#     --domain contoso-prod.validation.example.com
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$REPO_ROOT/terraform"

CUSTOMER_NAME=""
ENVIRONMENT="prod"
RESOURCE_GROUP=""
AKS_NAME=""
DOMAIN=""
PLATFORM_NAME="open-horizons"
IMAGE_TAG="v7.2.4"
BACKSTAGE_IMAGE="ghcr.io/ohorizons/ohorizons-backstage"
AGENT_API_IMAGE="ghcr.io/ohorizons/ohorizons-agent-api"
AGENT_API_IMPACT_IMAGE="ghcr.io/ohorizons/ohorizons-agent-api-impact"
MCP_ECOSYSTEM_IMAGE="ghcr.io/ohorizons/mcp-ecosystem"
ORG_DISPLAY_NAME="Open Horizons"
AZURE_OPENAI_DEPLOYMENT="gpt-5.1"
APPLY_INGRESS=false
ENABLE_MCP_ECOSYSTEM="${ENABLE_MCP_ECOSYSTEM:-auto}"

usage() {
  cat <<'USAGE'
Usage: scripts/deploy-runtime-nogithub.sh [options]

Required:
  --customer-name NAME       Customer slug, for example contoso
  --environment ENV          Environment, for example prod
  --resource-group RG        Azure resource group
  --aks-name NAME            AKS cluster name
  --domain DOMAIN            Runtime domain/base URL

Optional:
  --platform-name NAME       Kubernetes resource prefix (default: open-horizons)
  --image-tag TAG            Image tag (default: v7.2.4)
  --apply-ingress            Also apply generated ingress.yaml and tls.yaml
  --enable-mcp               Apply MCP Ecosystem even if image preflight cannot verify it
  --disable-mcp              Skip MCP Ecosystem and delete any existing MCP deployment/service
  --help                     Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --customer-name) CUSTOMER_NAME="$2"; shift 2 ;;
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    --aks-name) AKS_NAME="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --platform-name) PLATFORM_NAME="$2"; shift 2 ;;
    --image-tag) IMAGE_TAG="$2"; shift 2 ;;
    --mcp-ecosystem-image) MCP_ECOSYSTEM_IMAGE="$2"; shift 2 ;;
    --enable-mcp) ENABLE_MCP_ECOSYSTEM=true; shift ;;
    --disable-mcp) ENABLE_MCP_ECOSYSTEM=false; shift ;;
    --apply-ingress) APPLY_INGRESS=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

missing=()
[[ -n "$CUSTOMER_NAME" ]] || missing+=(--customer-name)
[[ -n "$ENVIRONMENT" ]] || missing+=(--environment)
[[ -n "$RESOURCE_GROUP" ]] || missing+=(--resource-group)
[[ -n "$AKS_NAME" ]] || missing+=(--aks-name)
[[ -n "$DOMAIN" ]] || missing+=(--domain)
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required arguments: ${missing[*]}" >&2
  usage
  exit 1
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

require_cmd az
require_cmd kubectl
require_cmd python3
require_cmd openssl

state_value() {
  local resource_type="$1" resource_name="$2" attr="$3"
  local state_file
  state_file="$(mktemp)"
  terraform -chdir="$TERRAFORM_DIR" state pull > "$state_file"
  python3 - "$resource_type" "$resource_name" "$attr" "$state_file" <<'PY'
import json
import sys

resource_type, resource_name, attr, state_file = sys.argv[1:5]
with open(state_file) as handle:
    state = json.load(handle)
for resource in state.get("resources", []):
    if resource.get("type") == resource_type and resource.get("name") == resource_name:
        for instance in resource.get("instances", []):
            attrs = instance.get("attributes", {})
            value = attrs.get(attr)
            if value:
                print(value)
                raise SystemExit(0)
raise SystemExit(1)
PY
  local exit_code=$?
  rm -f "$state_file"
  return "$exit_code"
}

echo "[runtime] Selecting AKS credentials"
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --admin --overwrite-existing >/dev/null

echo "[runtime] Resolving Azure resource values"
POSTGRES_HOST="$(az postgres flexible-server show -g "$RESOURCE_GROUP" -n "psql-${CUSTOMER_NAME}-${ENVIRONMENT}" --query fullyQualifiedDomainName -o tsv)"
POSTGRES_PASSWORD="$(state_value random_password postgresql result)"
AZURE_OPENAI_ENDPOINT="$(az cognitiveservices account show -g "$RESOURCE_GROUP" -n "oai-${CUSTOMER_NAME}-${ENVIRONMENT}" --query properties.endpoint -o tsv)"
AZURE_OPENAI_API_KEY="$(az cognitiveservices account keys list -g "$RESOURCE_GROUP" -n "oai-${CUSTOMER_NAME}-${ENVIRONMENT}" --query key1 -o tsv)"

if [[ -z "$POSTGRES_PASSWORD" || -z "$AZURE_OPENAI_ENDPOINT" || -z "$AZURE_OPENAI_API_KEY" ]]; then
  echo "Failed to resolve required runtime secrets" >&2
  exit 1
fi

tmp_env="$(mktemp)"
trap 'rm -f "$tmp_env"' EXIT
write_env_var() {
  local key="$1" value="$2"
  printf '%s=%q\n' "$key" "$value" >> "$tmp_env"
}

write_env_var PLATFORM_NAME "$PLATFORM_NAME"
write_env_var DOMAIN "$DOMAIN"
write_env_var ADMIN_EMAIL "admin@$DOMAIN"
write_env_var ORG_DISPLAY_NAME "$ORG_DISPLAY_NAME"
write_env_var AUTH_PROVIDER "guest"
write_env_var IMAGE_TAG "$IMAGE_TAG"
write_env_var GITHUB_ORG "local"
write_env_var GITHUB_REPO "open-horizons-platform"
write_env_var BACKSTAGE_IMAGE "$BACKSTAGE_IMAGE"
write_env_var AGENT_API_IMAGE "$AGENT_API_IMAGE"
write_env_var AGENT_API_IMPACT_IMAGE "$AGENT_API_IMPACT_IMAGE"
write_env_var MCP_ECOSYSTEM_IMAGE "$MCP_ECOSYSTEM_IMAGE"
write_env_var AZURE_OPENAI_DEPLOYMENT "$AZURE_OPENAI_DEPLOYMENT"

echo "[runtime] Rendering no-GitHub manifests"
NO_GITHUB_MODE=true "$REPO_ROOT/scripts/render-k8s.sh" --env-file "$tmp_env" >/tmp/open-horizons-render-runtime.log

if [[ "$ENABLE_MCP_ECOSYSTEM" == "auto" ]]; then
  if command -v docker >/dev/null 2>&1 && docker manifest inspect "${MCP_ECOSYSTEM_IMAGE}:${IMAGE_TAG}" >/dev/null 2>&1; then
    ENABLE_MCP_ECOSYSTEM=true
  else
    ENABLE_MCP_ECOSYSTEM=false
  fi
fi

echo "[runtime] Applying namespaces"
kubectl apply -f "$REPO_ROOT/backstage/k8s/namespace.yaml"

echo "[runtime] Applying runtime secrets"
kubectl -n backstage create secret generic backstage-secrets \
  --from-literal=BACKEND_SECRET="$(openssl rand -hex 32)" \
  --from-literal=POSTGRES_HOST="$POSTGRES_HOST" \
  --from-literal=POSTGRES_PORT="5432" \
  --from-literal=POSTGRES_USER="pgadmin" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=POSTGRES_DATABASE="backstage" \
  --from-literal=APP_BASE_URL="https://$DOMAIN" \
  --from-literal=GITHUB_TOKEN="not-configured" \
  --from-literal=GITHUB_APP_CLIENT_ID="not-configured" \
  --from-literal=GITHUB_APP_CLIENT_SECRET="not-configured" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n ai-services create secret generic agent-api-secrets \
  --from-literal=AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
  --from-literal=AZURE_OPENAI_API_KEY="$AZURE_OPENAI_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[runtime] Applying runtime manifests"
kubectl apply -f "$REPO_ROOT/backstage/k8s/agent-identity.yaml"
kubectl apply -f "$REPO_ROOT/backstage/k8s/configmap.yaml"
kubectl apply -f "$REPO_ROOT/backstage/k8s/service.yaml"
kubectl apply -f "$REPO_ROOT/backstage/k8s/deployment.yaml"
kubectl apply -f "$REPO_ROOT/backstage/k8s/agent-api-service.yaml"
kubectl apply -f "$REPO_ROOT/backstage/k8s/agent-api-deployment.yaml"
kubectl apply -f "$REPO_ROOT/backstage/k8s/agent-api-impact-deployment.yaml"
if [[ "$ENABLE_MCP_ECOSYSTEM" == true ]]; then
  kubectl apply -f "$REPO_ROOT/backstage/k8s/mcp-ecosystem-deployment.yaml"
  kubectl apply -f "$REPO_ROOT/backstage/k8s/mcp-ecosystem-networkpolicy.yaml"
else
  echo "[runtime] Skipping MCP Ecosystem; image is not available or --disable-mcp was set"
  kubectl -n ai-services delete deployment mcp-ecosystem --ignore-not-found=true
  kubectl -n ai-services delete service mcp-ecosystem --ignore-not-found=true
  kubectl -n ai-services delete serviceaccount mcp-ecosystem --ignore-not-found=true
  kubectl -n ai-services delete networkpolicy mcp-ecosystem --ignore-not-found=true
fi

if [[ "$APPLY_INGRESS" == true ]]; then
  kubectl apply -f "$REPO_ROOT/backstage/k8s/tls.yaml"
  kubectl apply -f "$REPO_ROOT/backstage/k8s/ingress.yaml"
fi

echo "[runtime] Waiting for deployments"
kubectl rollout status deployment/"${PLATFORM_NAME}"-backstage -n backstage --timeout=300s
kubectl rollout status deployment/"${PLATFORM_NAME}"-agent-api -n ai-services --timeout=300s
kubectl rollout status deployment/"${PLATFORM_NAME}"-agent-api-impact -n ai-services --timeout=300s
if [[ "$ENABLE_MCP_ECOSYSTEM" == true ]]; then
  kubectl rollout status deployment/mcp-ecosystem -n ai-services --timeout=300s
fi

echo "[runtime] Runtime deployment complete"
kubectl get deploy,svc -n backstage
kubectl get deploy,svc -n ai-services