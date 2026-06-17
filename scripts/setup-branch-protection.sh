#!/bin/bash
# =============================================================================
# OPEN HORIZONS PLATFORM - BRANCH PROTECTION SETUP
# =============================================================================
#
# This script configures branch protection rules for the repository.
# Requires GitHub CLI (gh) to be installed and authenticated.
#
# Usage:
#   ./scripts/setup-branch-protection.sh [OWNER/REPO]
#
# Example:
#   ./scripts/setup-branch-protection.sh myorg/agentic-devops-platform
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get repository from argument or detect from git
REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)}"

if [ -z "$REPO" ]; then
    echo -e "${RED}Error: Could not determine repository.${NC}"
    echo "Usage: $0 [OWNER/REPO]"
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Branch Protection Setup${NC}"
echo -e "${BLUE}Repository: ${REPO}${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI is not authenticated.${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${YELLOW}Setting up branch protection rules...${NC}"
echo ""

# =============================================================================
# MAIN BRANCH PROTECTION
# =============================================================================
echo -e "${GREEN}Configuring 'main' branch protection...${NC}"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/branches/main/protection" \
  -f required_status_checks='{"strict":true,"contexts":["validate-pr-source","CI / terraform-validate","CI / terraform-security","CI / ci-summary"]}' \
  -F enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
  -f restrictions=null \
  -F allow_force_pushes=false \
  -F allow_deletions=false \
  -F required_linear_history=false \
  -F required_conversation_resolution=true \
  2>/dev/null && echo -e "${GREEN}✓ Main branch protection configured${NC}" || echo -e "${YELLOW}⚠ Could not configure main branch (may require admin permissions)${NC}"

# =============================================================================
# DEVELOP BRANCH PROTECTION
# =============================================================================
echo -e "${GREEN}Configuring 'develop' branch protection...${NC}"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/branches/develop/protection" \
  -f required_status_checks='{"strict":true,"contexts":["CI / terraform-validate","CI / ci-summary"]}' \
  -F enforce_admins=false \
  -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  -f restrictions=null \
  -F allow_force_pushes=false \
  -F allow_deletions=false \
  2>/dev/null && echo -e "${GREEN}✓ Develop branch protection configured${NC}" || echo -e "${YELLOW}⚠ Could not configure develop branch (may require admin permissions)${NC}"

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Branch protection setup complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "Branch rules configured:"
echo -e "  ${GREEN}main${NC}    - Requires PR from develop, 1 approval, CI pass"
echo -e "  ${GREEN}develop${NC} - Requires 1 approval, CI pass"
echo ""
echo -e "Workflow:"
echo -e "  feature/* ──> develop ──> main"
echo ""
echo -e "${YELLOW}Note: You may need to manually configure additional settings in GitHub UI:${NC}"
echo -e "  Settings > Branches > Branch protection rules"
echo ""
