#!/bin/bash
# =============================================================================
# setup-terraform-backend.sh — Create Azure Storage for Terraform state
# =============================================================================
# Usage: ./scripts/setup-terraform-backend.sh \
#          --customer-name contoso \
#          --environment prod \
#          --location brazilsouth
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

CUSTOMER_NAME=""
ENVIRONMENT=""
LOCATION="brazilsouth"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --customer-name|-c) CUSTOMER_NAME="$2"; shift 2 ;;
    --environment|-e)   ENVIRONMENT="$2"; shift 2 ;;
    --location|-l)      LOCATION="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 --customer-name <name> --environment <env> [--location <region>]"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$CUSTOMER_NAME" || -z "$ENVIRONMENT" ]]; then
  echo "Error: --customer-name and --environment are required"
  echo "Usage: $0 --customer-name contoso --environment prod"
  exit 1
fi

RG_NAME="rg-${CUSTOMER_NAME}-tfstate"
SA_NAME="st${CUSTOMER_NAME}${ENVIRONMENT}tfstate"
# Storage account names: max 24 chars, lowercase alphanumeric only
SA_NAME=$(echo "$SA_NAME" | tr -d '-' | cut -c1-24)
CONTAINER_NAME="tfstate"
STATE_KEY="${CUSTOMER_NAME}.${ENVIRONMENT}.tfstate"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       OPEN HORIZONS — Terraform Backend Setup             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Customer:    ${YELLOW}${CUSTOMER_NAME}${NC}"
echo -e "  Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "  Location:    ${YELLOW}${LOCATION}${NC}"
echo -e "  RG:          ${YELLOW}${RG_NAME}${NC}"
echo -e "  Storage:     ${YELLOW}${SA_NAME}${NC}"
echo -e "  Container:   ${YELLOW}${CONTAINER_NAME}${NC}"
echo -e "  State key:   ${YELLOW}${STATE_KEY}${NC}"
echo ""

read -rp "Create these resources? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Cancelled."
  exit 0
fi

echo ""
echo -e "${BLUE}Creating resource group...${NC}"
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  --tags "Purpose=terraform-state" "ManagedBy=setup-script" \
  --output none

echo -e "${BLUE}Creating storage account...${NC}"
az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

echo -e "${BLUE}Creating blob container...${NC}"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$SA_NAME" \
  --auth-mode login \
  --output none

echo ""
echo -e "${GREEN}━━━ Backend storage created successfully! ━━━${NC}"
echo ""
echo "Add this to your terraform/backend.tf:"
echo ""
cat <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "${RG_NAME}"
    storage_account_name = "${SA_NAME}"
    container_name       = "${CONTAINER_NAME}"
    key                  = "${STATE_KEY}"
  }
}
EOF
echo ""
echo "Then run: cd terraform && terraform init"
