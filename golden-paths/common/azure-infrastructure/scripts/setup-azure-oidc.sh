#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/setup-azure-oidc.sh --resource-group <name> [options]

Configures GitHub Actions OIDC for the current repository by creating or reusing
an Entra app registration, adding federated credentials for GitHub environments,
assigning least required Azure RBAC, and setting repository secrets.

Required:
  --resource-group <name>        Azure resource group used by infrastructure deployments

Options:
  --repo <owner/repo>            GitHub repository. Defaults to gh repo view
  --subscription <id>            Azure subscription. Defaults to az account show
  --tenant <id>                  Azure tenant. Defaults to az account show
  --location <region>            Resource group location when creating it. Default: centralus
  --environments <csv>           GitHub environments. Default: dev,staging,prod
  --app-name <name>              Entra app display name. Default derived from repo
  --role <role>                  Azure RBAC role. Default: Contributor
  --create-resource-group        Create the resource group if it does not exist
  --dry-run                      Print actions without changing Azure or GitHub
  -h, --help                     Show this help

Prerequisites:
  az login
  gh auth login
  Azure permission to create app registrations, federated credentials, and role assignments
  GitHub permission to write repository secrets
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

repo=""
subscription_id=""
tenant_id=""
resource_group=""
location="centralus"
environments="dev,staging,prod"
app_name=""
role="Contributor"
create_resource_group=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="$2"
      shift 2
      ;;
    --subscription)
      subscription_id="$2"
      shift 2
      ;;
    --tenant)
      tenant_id="$2"
      shift 2
      ;;
    --resource-group)
      resource_group="$2"
      shift 2
      ;;
    --location)
      location="$2"
      shift 2
      ;;
    --environments)
      environments="$2"
      shift 2
      ;;
    --app-name)
      app_name="$2"
      shift 2
      ;;
    --role)
      role="$2"
      shift 2
      ;;
    --create-resource-group)
      create_resource_group=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_cmd az
require_cmd gh

if [[ -z "$resource_group" ]]; then
  echo "--resource-group is required" >&2
  usage >&2
  exit 1
fi

if [[ -z "$repo" ]]; then
  if $dry_run && ! gh auth status >/dev/null 2>&1; then
    repo="<owner>/<repo>"
  else
    repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  fi
fi

if [[ -z "$subscription_id" ]]; then
  if $dry_run && ! az account show >/dev/null 2>&1; then
    subscription_id="<subscription-id>"
  else
    subscription_id="$(az account show --query id -o tsv)"
  fi
fi

if [[ -z "$tenant_id" ]]; then
  if $dry_run && ! az account show >/dev/null 2>&1; then
    tenant_id="<tenant-id>"
  else
    tenant_id="$(az account show --query tenantId -o tsv)"
  fi
fi

if [[ -z "$app_name" ]]; then
  safe_repo="$(printf '%s' "$repo" | tr '/[:upper:]' '-[:lower:]' | tr -cd 'a-z0-9-')"
  if [[ "$safe_repo" == ohorizons-* ]]; then
    app_name="${safe_repo}-github-oidc"
  else
    app_name="ohorizons-${safe_repo}-github-oidc"
  fi
fi

run() {
  if $dry_run; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

run az account set --subscription "$subscription_id"

if $create_resource_group; then
  run az group create \
    --name "$resource_group" \
    --location "$location" \
    --tags managedBy=open-horizons-golden-path purpose=github-oidc \
    --output none
else
  if ! $dry_run; then
    az group show --name "$resource_group" --output none
  fi
fi

if $dry_run; then
  client_id="<client-id>"
else
  client_id="$(az ad app list --display-name "$app_name" --query '[0].appId' -o tsv)"
fi

if [[ -z "$client_id" ]]; then
  echo "Creating Entra app registration: $app_name"
  run az ad app create --display-name "$app_name" --output none
  client_id="$(az ad app list --display-name "$app_name" --query '[0].appId' -o tsv)"
else
  echo "Using existing Entra app registration: $app_name"
fi

if ! $dry_run; then
  if ! az ad sp show --id "$client_id" --output none 2>/dev/null; then
    echo "Creating service principal for app registration"
    az ad sp create --id "$client_id" --output none
  fi
fi

scope="/subscriptions/${subscription_id}/resourceGroups/${resource_group}"
if $dry_run; then
  assignment_id=""
else
  assignment_id="$(az role assignment list \
    --assignee "$client_id" \
    --scope "$scope" \
    --role "$role" \
    --query '[0].id' \
    -o tsv)"
fi

if [[ -z "$assignment_id" ]]; then
  echo "Assigning Azure role '$role' on $scope"
  run az role assignment create \
    --assignee "$client_id" \
    --role "$role" \
    --scope "$scope" \
    --output none
else
  echo "Azure role assignment already exists"
fi

IFS=',' read -r -a environment_list <<< "$environments"
for environment in "${environment_list[@]}"; do
  environment="$(printf '%s' "$environment" | xargs)"
  [[ -n "$environment" ]] || continue

  credential_name="github-${environment}"
  subject="repo:${repo}:environment:${environment}"

  if $dry_run; then
    existing_credential=""
  else
    existing_credential="$(az ad app federated-credential list \
      --id "$client_id" \
      --query "[?name=='${credential_name}'].name | [0]" \
      -o tsv)"
  fi

  if [[ -n "$existing_credential" ]]; then
    echo "Federated credential already exists for environment: $environment"
    continue
  fi

  if $dry_run; then
    echo "[dry-run] az ad app federated-credential create --id $client_id --parameters <json: $credential_name $subject>"
    continue
  fi

  credential_file="$(mktemp)"
  cat > "$credential_file" <<JSON
{
  "name": "${credential_name}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${subject}",
  "description": "GitHub Actions OIDC for ${repo} ${environment}",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
JSON

  echo "Creating federated credential for environment: $environment"
  az ad app federated-credential create \
    --id "$client_id" \
    --parameters "$credential_file" \
    --output none
  rm -f "$credential_file"
done

echo "Writing GitHub repository secrets for $repo"
run gh secret set AZURE_CLIENT_ID --repo "$repo" --body "$client_id"
run gh secret set AZURE_TENANT_ID --repo "$repo" --body "$tenant_id"
run gh secret set AZURE_SUBSCRIPTION_ID --repo "$repo" --body "$subscription_id"

if $dry_run; then
  echo "[dry-run] Azure OIDC configuration plan complete for $repo"
else
  echo "Azure OIDC is configured for $repo"
fi
echo "Resource group: $resource_group"
echo "GitHub environments: $environments"
