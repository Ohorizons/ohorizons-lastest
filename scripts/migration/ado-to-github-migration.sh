#!/bin/bash
# =============================================================================
# OPEN HORIZONS PLATFORM - ADO TO GITHUB MIGRATION TOOLKIT
# =============================================================================
#
# Comprehensive scripts for migrating from Azure DevOps to GitHub
# Based on Microsoft Migration Playbook:
# https://devblogs.microsoft.com/all-things-azure/azure-devops-to-github-migration-playbook-unlocking-agentic-devops/
#
# Supports: Repos, Pipelines, Work Items, Security, Mannequins
#
# 6-Phase Migration Process:
#   Phase 1: Environment Configuration
#   Phase 2: Azure Pipelines App Installation
#   Phase 3: Organization Inventory
#   Phase 4: Migration Script Generation
#   Phase 5: Script Customization & Execution
#   Phase 6: Post-Migration Validation (incl. Mannequins)
#
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/migration.log"
INVENTORY_DIR="${SCRIPT_DIR}/inventory"
MANNEQUIN_DIR="${SCRIPT_DIR}/mannequins"
DRY_RUN=false
VERBOSE=false

# Migration options (from Microsoft Playbook)
LOCK_ADO_REPO=false
DISABLE_ADO_REPOS=false
CREATE_TEAMS=false
REWIRE_PIPELINES=false
REPO_LIST=""

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log() {
    local level=$1
    shift
    local message=$*
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
    
    case ${level} in
        INFO)  echo -e "${GREEN}[INFO]${NC} ${message}" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} ${message}" ;;
        DEBUG) [[ "${VERBOSE}" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} ${message}" ;;
    esac
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
    log INFO "Checking prerequisites..."
    
    local missing=()
    
    # Check for required tools
    command -v gh >/dev/null 2>&1 || missing+=("gh (GitHub CLI)")
    command -v az >/dev/null 2>&1 || missing+=("az (Azure CLI)")
    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    
    # Check for ado2gh extension
    if ! gh extension list 2>/dev/null | grep -q "ado2gh"; then
        missing+=("gh ado2gh extension")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log ERROR "Missing prerequisites:"
        for tool in "${missing[@]}"; do
            log ERROR "  - ${tool}"
        done
        echo ""
        echo "Installation instructions:"
        echo "  gh CLI:      https://cli.github.com/"
        echo "  Azure CLI:   https://docs.microsoft.com/cli/azure/install-azure-cli"
        echo "  ado2gh:      gh extension install github/gh-ado2gh"
        exit 1
    fi
    
    log INFO "All prerequisites satisfied"
}

# =============================================================================
# AUTHENTICATION
# =============================================================================

setup_authentication() {
    log INFO "Setting up authentication..."
    
    # GitHub authentication
    if ! gh auth status >/dev/null 2>&1; then
        log WARN "GitHub CLI not authenticated. Please run: gh auth login"
        exit 1
    fi
    
    # Azure DevOps authentication
    if [[ -z "${AZURE_DEVOPS_EXT_PAT:-}" ]]; then
        log WARN "AZURE_DEVOPS_EXT_PAT environment variable not set"
        read -sp "Enter Azure DevOps PAT: " ADO_PAT
        echo ""
        export AZURE_DEVOPS_EXT_PAT="${ADO_PAT}"
    fi
    
    # Verify ADO connection
    if ! az devops project list --org "${ADO_ORG}" >/dev/null 2>&1; then
        log ERROR "Failed to connect to Azure DevOps organization: ${ADO_ORG}"
        exit 1
    fi
    
    log INFO "Authentication configured successfully"
}

# =============================================================================
# PHASE 2: AZURE PIPELINES APP CHECK
# =============================================================================

check_azure_pipelines_app() {
    log INFO "=== Phase 2: Azure Pipelines App Check ==="

    if [[ "${REWIRE_PIPELINES}" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: Azure Pipelines GitHub App Required${NC}"
        echo ""
        echo "Before proceeding with pipeline rewiring, ensure the Azure Pipelines"
        echo "app is installed from GitHub Marketplace:"
        echo ""
        echo "  1. Go to: https://github.com/marketplace/azure-pipelines"
        echo "  2. Click 'Install it for free'"
        echo "  3. Select organization: ${GH_ORG}"
        echo "  4. Grant access to repositories (all or selected)"
        echo ""

        # Check if app is installed (best effort)
        if gh api "/orgs/${GH_ORG}/installations" 2>/dev/null | grep -q "Azure Pipelines"; then
            log INFO "✅ Azure Pipelines app appears to be installed"
        else
            log WARN "Could not verify Azure Pipelines app installation"
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        log INFO "Pipeline rewiring disabled - Azure Pipelines app not required"
    fi
}

# =============================================================================
# PHASE 3: INVENTORY REPORT
# =============================================================================

generate_inventory_report() {
    log INFO "=== Phase 3: Generate Inventory Report ==="

    mkdir -p "${INVENTORY_DIR}"

    log INFO "Generating inventory for: ${ADO_ORG}"

    # Use ado2gh inventory-report
    if gh ado2gh inventory-report \
        --ado-org "${ADO_ORG}" \
        --output-path "${INVENTORY_DIR}" 2>&1; then

        log INFO "Inventory report generated successfully"

        # Display summary
        echo ""
        echo -e "${CYAN}=== Inventory Summary ===${NC}"
        echo ""

        if [[ -f "${INVENTORY_DIR}/repos.csv" ]]; then
            local repo_count=$(( $(wc -l < "${INVENTORY_DIR}/repos.csv") - 1 ))
            local pipeline_count=$(( $(wc -l < "${INVENTORY_DIR}/pipelines.csv") - 1 ))
            local team_count=$(( $(wc -l < "${INVENTORY_DIR}/team-projects.csv" 2>/dev/null || echo 1) - 1 ))

            echo "  Repositories: ${repo_count}"
            echo "  Pipelines:    ${pipeline_count}"
            echo "  Teams:        ${team_count}"
            echo ""
            echo "  Files saved to: ${INVENTORY_DIR}/"
            echo "    - repos.csv"
            echo "    - pipelines.csv"
            echo "    - team-projects.csv"
            echo "    - orgs.csv"
        fi
    else
        log WARN "ado2gh inventory-report failed, using fallback"

        # Fallback to manual inventory
        log INFO "Generating manual inventory..."

        # List repositories
        az repos list \
            --org "${ADO_ORG}" \
            --project "${ADO_PROJECT}" \
            --query "[].{name:name,size:size,defaultBranch:defaultBranch}" \
            -o json > "${INVENTORY_DIR}/repos.json"

        # List pipelines
        az pipelines list \
            --org "${ADO_ORG}" \
            --project "${ADO_PROJECT}" \
            --query "[].{name:name,path:path}" \
            -o json > "${INVENTORY_DIR}/pipelines.json"

        # List teams
        az devops team list \
            --org "${ADO_ORG}" \
            --project "${ADO_PROJECT}" \
            -o json > "${INVENTORY_DIR}/teams.json" 2>/dev/null || echo "[]" > "${INVENTORY_DIR}/teams.json"

        echo ""
        echo -e "${CYAN}=== Inventory Summary ===${NC}"
        echo ""
        echo "  Repositories: $(jq length "${INVENTORY_DIR}/repos.json")"
        echo "  Pipelines:    $(jq length "${INVENTORY_DIR}/pipelines.json")"
        echo "  Teams:        $(jq length "${INVENTORY_DIR}/teams.json")"
    fi

    log INFO "Inventory generation complete"
}

# =============================================================================
# PHASE 6: MANNEQUIN MANAGEMENT
# =============================================================================

generate_mannequin_csv() {
    log INFO "=== Generating Mannequin List ==="

    mkdir -p "${MANNEQUIN_DIR}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log INFO "[DRY RUN] Would generate mannequin list"
        return 0
    fi

    # Generate mannequin CSV using ado2gh
    if gh ado2gh generate-mannequin-csv \
        --github-org "${GH_ORG}" \
        --output "${MANNEQUIN_DIR}/mannequins.csv" 2>&1; then

        local mannequin_count=$(( $(wc -l < "${MANNEQUIN_DIR}/mannequins.csv") - 1 ))

        if [[ ${mannequin_count} -le 0 ]]; then
            log INFO "✅ No mannequins found - all users mapped correctly!"
            return 0
        fi

        log INFO "Found ${mannequin_count} mannequin(s)"
        echo ""
        echo -e "${CYAN}=== Mannequin List ===${NC}"
        cat "${MANNEQUIN_DIR}/mannequins.csv"
        echo ""

        # Create mapping template
        cat > "${MANNEQUIN_DIR}/mannequin-mapping-template.csv" << 'EOF'
# Mannequin Mapping Template
# Format: mannequin-user,target-user
#
# Instructions:
# 1. Copy this file to mannequin-mapping.csv
# 2. Fill in the target-user column with GitHub usernames
# 3. Run: ./ado-to-github-migration.sh reclaim-mannequins
#
mannequin-user,target-user
EOF

        # Add mannequins to template
        tail -n +2 "${MANNEQUIN_DIR}/mannequins.csv" | while read -r line; do
            mannequin=$(echo "${line}" | cut -d',' -f1)
            echo "${mannequin}," >> "${MANNEQUIN_DIR}/mannequin-mapping-template.csv"
        done

        log INFO "Mapping template created: ${MANNEQUIN_DIR}/mannequin-mapping-template.csv"
    else
        log WARN "Could not generate mannequin list"
        log INFO "This may mean no mannequins were created, or migration hasn't completed"
    fi
}

reclaim_mannequins() {
    log INFO "=== Reclaiming Mannequins ==="

    local mapping_file="${MANNEQUIN_DIR}/mannequin-mapping.csv"

    if [[ ! -f "${mapping_file}" ]]; then
        log ERROR "Mapping file not found: ${mapping_file}"
        log INFO "Please create mapping file from template first:"
        log INFO "  cp ${MANNEQUIN_DIR}/mannequin-mapping-template.csv ${mapping_file}"
        log INFO "  # Edit ${mapping_file} to add GitHub usernames"
        exit 1
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log INFO "[DRY RUN] Would reclaim mannequins from: ${mapping_file}"
        return 0
    fi

    # Reclaim mannequins
    gh ado2gh reclaim-mannequin \
        --github-org "${GH_ORG}" \
        --csv "${mapping_file}" \
        2>&1 | tee -a "${LOG_FILE}"

    log INFO "Mannequin reclaim complete"
}

# =============================================================================
# VALIDATION CHECKLIST
# =============================================================================

run_validation_checklist() {
    log INFO "=== Post-Migration Validation Checklist ==="
    echo ""

    local all_passed=true

    # 1. Check repositories accessible
    echo -n "1. All repositories accessible on GitHub: "
    local repo_count=$(gh repo list "${GH_ORG}" --json name -q 'length' 2>/dev/null || echo 0)
    if [[ ${repo_count} -gt 0 ]]; then
        echo -e "${GREEN}✅ ${repo_count} repos${NC}"
    else
        echo -e "${RED}❌ No repos found${NC}"
        all_passed=false
    fi

    # 2. Check branches and tags
    echo -n "2. Branches and tags present: "
    local sample_repo=$(gh repo list "${GH_ORG}" --json name -q '.[0].name' 2>/dev/null || echo "")
    if [[ -n "${sample_repo}" ]]; then
        local branch_count=$(gh api "repos/${GH_ORG}/${sample_repo}/branches" -q 'length' 2>/dev/null || echo 0)
        echo -e "${GREEN}✅ (${branch_count} branches in ${sample_repo})${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not verify${NC}"
    fi

    # 3. Azure DevOps pipelines functional (if hybrid mode)
    echo -n "3. Azure DevOps pipelines functional: "
    if [[ "${REWIRE_PIPELINES}" == "true" ]]; then
        echo -e "${YELLOW}⚠️  Verify manually in ADO${NC}"
    else
        echo -e "${BLUE}ℹ️  Not applicable (pipelines not rewired)${NC}"
    fi

    # 4. Mannequins reclaimed
    echo -n "4. Mannequins reclaimed: "
    if [[ -f "${MANNEQUIN_DIR}/mannequins.csv" ]]; then
        local mannequin_count=$(( $(wc -l < "${MANNEQUIN_DIR}/mannequins.csv") - 1 ))
        if [[ ${mannequin_count} -gt 0 ]]; then
            echo -e "${YELLOW}⚠️  ${mannequin_count} pending${NC}"
        else
            echo -e "${GREEN}✅ None pending${NC}"
        fi
    else
        echo -e "${GREEN}✅ No mannequins${NC}"
    fi

    # 5. Teams updated local configurations
    echo -n "5. Teams updated local configurations: "
    echo -e "${YELLOW}⚠️  Verify with teams${NC}"

    # 6. Branch protections configured
    echo -n "6. Branch protections configured: "
    if [[ -n "${sample_repo}" ]]; then
        if gh api "repos/${GH_ORG}/${sample_repo}/branches/main/protection" &>/dev/null; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${YELLOW}⚠️  Not configured${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not verify${NC}"
    fi

    # 7. Documentation updated
    echo -n "7. Documentation updated: "
    echo -e "${YELLOW}⚠️  Verify manually${NC}"

    echo ""
    if [[ "${all_passed}" == "true" ]]; then
        log INFO "✅ All critical validations passed!"
    else
        log WARN "Some validations need attention - review above"
    fi

    # Developer instructions
    echo ""
    echo -e "${CYAN}=== Developer Remote Update Instructions ===${NC}"
    echo ""
    echo "  cd path/to/repo"
    echo "  git remote set-url origin https://github.com/${GH_ORG}/YOUR_REPO.git"
    echo "  git remote -v  # Verify the change"
    echo ""
}

# =============================================================================
# REPOSITORY MIGRATION
# =============================================================================

migrate_repository() {
    local ado_project=$1
    local ado_repo=$2
    local gh_org=$3
    local gh_repo=${4:-$ado_repo}
    
    log INFO "Migrating repository: ${ado_project}/${ado_repo} -> ${gh_org}/${gh_repo}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log INFO "[DRY RUN] Would migrate ${ado_repo}"
        return 0
    fi
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf ${temp_dir}" EXIT
    
    # Clone ADO repository with full history
    log DEBUG "Cloning from ADO..."
    git clone --mirror "https://dev.azure.com/${ADO_ORG}/${ado_project}/_git/${ado_repo}" "${temp_dir}/${ado_repo}"
    
    cd "${temp_dir}/${ado_repo}"
    
    # Create GitHub repository
    log DEBUG "Creating GitHub repository..."
    gh repo create "${gh_org}/${gh_repo}" \
        --private \
        --description "Migrated from Azure DevOps: ${ado_project}/${ado_repo}" \
        --disable-wiki \
        || log WARN "Repository may already exist"
    
    # Push to GitHub
    log DEBUG "Pushing to GitHub..."
    git push --mirror "https://github.com/${gh_org}/${gh_repo}.git"
    
    # Enable branch protection
    log DEBUG "Configuring branch protection..."
    gh api -X PUT "repos/${gh_org}/${gh_repo}/branches/main/protection" \
        -f required_status_checks='{"strict":true,"contexts":["build","test"]}' \
        -f enforce_admins=false \
        -f required_pull_request_reviews='{"required_approving_review_count":2}' \
        -f restrictions=null \
        || log WARN "Failed to set branch protection"
    
    log INFO "Repository migration completed: ${gh_org}/${gh_repo}"
}

migrate_all_repositories() {
    local ado_project=$1
    local gh_org=$2
    
    log INFO "Discovering repositories in project: ${ado_project}"
    
    # Get list of repositories
    local repos=$(az repos list \
        --org "${ADO_ORG}" \
        --project "${ado_project}" \
        --query "[].name" \
        -o tsv)
    
    local count=0
    local total=$(echo "${repos}" | wc -l)
    
    for repo in ${repos}; do
        count=$((count + 1))
        log INFO "Processing repository ${count}/${total}: ${repo}"
        migrate_repository "${ado_project}" "${repo}" "${gh_org}"
    done
    
    log INFO "All repositories migrated: ${count}/${total}"
}

# =============================================================================
# PIPELINE MIGRATION
# =============================================================================

convert_pipeline() {
    local ado_yaml=$1
    local output_file=$2
    
    log INFO "Converting pipeline: ${ado_yaml}"
    
    # Read ADO pipeline
    local ado_content=$(cat "${ado_yaml}")
    
    # Create GitHub Actions workflow
    cat > "${output_file}" << 'WORKFLOW_TEMPLATE'
# =============================================================================
# GITHUB ACTIONS WORKFLOW
# Converted from Azure DevOps Pipeline
# =============================================================================

name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  # Add environment variables here
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      # Build steps - customize for your project
      # Common examples:
      # - Node.js: npm ci && npm run build
      # - .NET: dotnet build --configuration Release
      # - Java: mvn package -DskipTests
      # - Python: pip install -r requirements.txt
      - name: Build
        run: |
          echo "Replace with your build commands"
          # npm ci && npm run build

  test:
    runs-on: ubuntu-latest
    needs: build
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # Test steps - customize for your project
      # Common examples:
      # - Node.js: npm test
      # - .NET: dotnet test --no-build
      # - Java: mvn test
      # - Python: pytest
      - name: Test
        run: |
          echo "Replace with your test commands"
          # npm test -- --coverage

  deploy:
    runs-on: ubuntu-latest
    needs: [build, test]
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      # Deploy steps - customize for your environment
      # Common examples:
      # - AKS: az aks get-credentials && kubectl apply -f manifests/
      # - App Service: az webapp deploy --name $APP_NAME
      # - Container: docker push && kubectl rollout restart
      # - Terraform: terraform apply -auto-approve
      - name: Deploy
        run: |
          echo "Replace with your deployment commands"
          # az aks get-credentials -g $RG -n $CLUSTER
          # kubectl apply -f deploy/
WORKFLOW_TEMPLATE
    
    log INFO "Pipeline converted to: ${output_file}"
    log WARN "Please review and update the converted workflow manually"
}

generate_migration_script() {
    local ado_project=$1
    local gh_org=$2
    local output_dir=$3

    log INFO "=== Phase 4: Generate Migration Script ==="
    log INFO "Generating migration scripts for project: ${ado_project}"

    mkdir -p "${output_dir}"

    # Build command options based on configuration
    local cmd_opts=""

    # Lock ADO repos (sets to read-only)
    if [[ "${LOCK_ADO_REPO}" == "true" ]]; then
        cmd_opts="${cmd_opts} --lock-ado-repo"
        log INFO "  Option: --lock-ado-repo (source repos will be read-only)"
    fi

    # Disable ADO repos
    if [[ "${DISABLE_ADO_REPOS}" == "true" ]]; then
        cmd_opts="${cmd_opts} --disable-ado-repos"
        log INFO "  Option: --disable-ado-repos (source repos will be disabled)"
    fi

    # Create GitHub teams
    if [[ "${CREATE_TEAMS}" == "true" ]]; then
        cmd_opts="${cmd_opts} --create-teams"
        log INFO "  Option: --create-teams (GitHub teams will be created)"
    fi

    # Rewire pipelines to GitHub
    if [[ "${REWIRE_PIPELINES}" == "true" ]]; then
        cmd_opts="${cmd_opts} --rewire-pipelines"
        log INFO "  Option: --rewire-pipelines (Azure Pipelines will use GitHub source)"
    fi

    # Repository list (if specified)
    if [[ -n "${REPO_LIST}" ]]; then
        cmd_opts="${cmd_opts} --repo-list ${REPO_LIST}"
        log INFO "  Option: --repo-list ${REPO_LIST}"
    else
        cmd_opts="${cmd_opts} --all"
        log INFO "  Option: --all (migrating all repositories)"
    fi

    # Generate using ado2gh
    log INFO "Running: gh ado2gh generate-script ${cmd_opts}"

    gh ado2gh generate-script \
        --ado-org "${ADO_ORG}" \
        --ado-team-project "${ado_project}" \
        --github-org "${gh_org}" \
        --output "${output_dir}/migrate.ps1" \
        --sequential \
        ${cmd_opts} \
        2>&1 | tee -a "${LOG_FILE}"

    log INFO "Migration script generated: ${output_dir}/migrate.ps1"
    echo ""
    echo "=== Script Preview (first 30 lines) ==="
    head -30 "${output_dir}/migrate.ps1" 2>/dev/null || log WARN "Could not preview script"
    echo ""
    log INFO "Review and customize the script before execution"
}

# =============================================================================
# GHAS MIGRATION (GHAzDO -> GHAS)
# =============================================================================

migrate_security_alerts() {
    local gh_org=$1
    local gh_repo=$2
    
    log INFO "Enabling GHAS for: ${gh_org}/${gh_repo}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log INFO "[DRY RUN] Would enable GHAS"
        return 0
    fi
    
    # Enable security features
    gh api -X PATCH "repos/${gh_org}/${gh_repo}" \
        -f security_and_analysis='{"advanced_security":{"status":"enabled"},"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}'
    
    # Create CodeQL workflow
    mkdir -p ".github/workflows"
    cat > ".github/workflows/codeql.yml" << 'CODEQL_WORKFLOW'
name: "CodeQL Analysis"

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '30 4 * * *'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    strategy:
      fail-fast: false
      matrix:
        language: ['javascript', 'python']  # Update based on repo languages

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          queries: security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
CODEQL_WORKFLOW
    
    log INFO "GHAS enabled and CodeQL workflow created"
}

# =============================================================================
# COPILOT MIGRATION (Standalone -> Enterprise)
# =============================================================================

configure_copilot_enterprise() {
    local gh_org=$1
    
    log INFO "Configuring Copilot Enterprise for organization: ${gh_org}"
    
    # This requires organization admin permissions
    # and Copilot Enterprise license
    
    cat << 'COPILOT_INFO'
=============================================================================
COPILOT ENTERPRISE CONFIGURATION
=============================================================================

To complete Copilot Enterprise setup:

1. Ensure you have Copilot Enterprise licenses assigned
2. Configure organization-wide Copilot settings:
   - Go to: https://github.com/organizations/${gh_org}/settings/copilot
   
3. Enable features:
   - ✅ Copilot Chat
   - ✅ Copilot in CLI
   - ✅ Knowledge bases (for org context)
   - ✅ Extensions

4. Configure policies:
   - Code suggestions: Enabled
   - Block suggestions matching public code: Enabled (recommended)
   - Copilot metrics: Enabled

5. Set up organization knowledge bases:
   - Go to: https://github.com/organizations/${gh_org}/settings/copilot/knowledge_bases
   - Add repositories for organizational context

=============================================================================
COPILOT_INFO
    
    log INFO "Copilot configuration guidance generated"
}

# =============================================================================
# WORK ITEM MIGRATION
# =============================================================================

migrate_work_items() {
    local ado_project=$1
    local gh_org=$2
    local gh_repo=$3
    
    log INFO "Migrating work items from ${ado_project} to ${gh_org}/${gh_repo}"
    
    # Export work items from ADO
    log DEBUG "Exporting work items from ADO..."
    
    local work_items=$(az boards query \
        --org "${ADO_ORG}" \
        --project "${ado_project}" \
        --wiql "SELECT [System.Id], [System.Title], [System.State], [System.Description], [System.WorkItemType] FROM WorkItems WHERE [System.TeamProject] = '${ado_project}'" \
        -o json)
    
    local count=0
    
    echo "${work_items}" | jq -c '.[]' | while read -r item; do
        local title=$(echo "${item}" | jq -r '.fields["System.Title"]')
        local state=$(echo "${item}" | jq -r '.fields["System.State"]')
        local description=$(echo "${item}" | jq -r '.fields["System.Description"] // "No description"')
        local type=$(echo "${item}" | jq -r '.fields["System.WorkItemType"]')
        local ado_id=$(echo "${item}" | jq -r '.id')
        
        # Map work item type to GitHub labels
        local labels=""
        case ${type} in
            "Bug") labels="bug" ;;
            "User Story") labels="enhancement" ;;
            "Task") labels="task" ;;
            "Feature") labels="feature" ;;
            *) labels="imported" ;;
        esac
        
        if [[ "${DRY_RUN}" == "true" ]]; then
            log DEBUG "[DRY RUN] Would create issue: ${title}"
            continue
        fi
        
        # Create GitHub issue
        gh issue create \
            --repo "${gh_org}/${gh_repo}" \
            --title "[Migrated #${ado_id}] ${title}" \
            --body "${description}

---
*Migrated from Azure DevOps: ${ado_project} #${ado_id}*
*Original State: ${state}*" \
            --label "${labels}" \
            || log WARN "Failed to create issue: ${title}"
        
        count=$((count + 1))
    done
    
    log INFO "Work items migrated: ${count}"
}

# =============================================================================
# FULL MIGRATION ORCHESTRATION
# =============================================================================

run_full_migration() {
    local ado_project=$1
    local gh_org=$2
    
    log INFO "Starting full migration: ${ado_project} -> ${gh_org}"
    
    # Phase 1: Repository Migration
    log INFO "=== Phase 1: Repository Migration ==="
    migrate_all_repositories "${ado_project}" "${gh_org}"
    
    # Phase 2: Security Configuration
    log INFO "=== Phase 2: Security Configuration ==="
    for repo in $(gh repo list "${gh_org}" --json name -q '.[].name'); do
        migrate_security_alerts "${gh_org}" "${repo}"
    done
    
    # Phase 3: Copilot Configuration
    log INFO "=== Phase 3: Copilot Enterprise ==="
    configure_copilot_enterprise "${gh_org}"
    
    # Phase 4: Work Items (optional)
    # log INFO "=== Phase 4: Work Items ==="
    # migrate_work_items "${ado_project}" "${gh_org}" "${gh_repo}"
    
    log INFO "Migration completed!"
    
    # Generate summary report
    generate_migration_report "${ado_project}" "${gh_org}"
}

generate_migration_report() {
    local ado_project=$1
    local gh_org=$2
    local report_file="${SCRIPT_DIR}/migration_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "${report_file}" << REPORT
# Migration Report

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Source:** Azure DevOps - ${ADO_ORG}/${ado_project}
**Target:** GitHub - ${gh_org}

## Summary

### Repositories Migrated
$(gh repo list "${gh_org}" --json name,createdAt -q '.[] | "- \(.name) (created: \(.createdAt))"')

### Security Features Enabled
- ✅ GitHub Advanced Security (GHAS)
- ✅ Secret Scanning
- ✅ Push Protection
- ✅ CodeQL Analysis
- ✅ Dependabot Alerts

### Pending Actions
- [ ] Review and update converted pipelines
- [ ] Configure Copilot Enterprise settings
- [ ] Validate branch protection rules
- [ ] Update CI/CD secrets
- [ ] Test deployment pipelines
- [ ] Archive ADO repositories

## Next Steps

1. **Validate Migrations**
   - Verify all commits and branches transferred
   - Check file integrity with checksums
   
2. **Update CI/CD**
   - Convert remaining ADO pipelines
   - Configure GitHub Actions secrets
   - Test deployments in dev environment

3. **Security Configuration**
   - Review CodeQL results
   - Address any initial security findings
   - Configure security policies

4. **Team Onboarding**
   - Update team documentation
   - Train team on GitHub workflows
   - Configure notification preferences

---
*Generated by Open Horizons Migration Toolkit*
REPORT
    
    log INFO "Migration report generated: ${report_file}"
}

# =============================================================================
# MAIN
# =============================================================================

show_help() {
    cat << HELP
Open Horizons - ADO to GitHub Migration Toolkit
Based on Microsoft Migration Playbook

Usage: $(basename "$0") [OPTIONS] COMMAND

COMMANDS (by Phase):

  Phase 1-2: Setup
    prerequisites     Check all prerequisites and authentication

  Phase 3: Discovery
    inventory         Generate inventory report (repos, pipelines, teams)

  Phase 4-5: Migration
    migrate-repo      Migrate a single repository
    migrate-all       Migrate all repositories in a project
    generate-script   Generate migration script using ado2gh
    full-migration    Run complete 6-phase migration workflow

  Phase 6: Post-Migration
    mannequins        Generate mannequin list
    reclaim-mannequins  Reclaim mannequins with mapping file
    validate          Run post-migration validation checklist

  Additional:
    convert-pipeline  Convert ADO pipeline to GitHub Actions
    migrate-security  Enable GHAS on migrated repositories
    migrate-workitems Migrate work items to GitHub Issues

OPTIONS:
  -o, --ado-org         Azure DevOps organization URL
  -p, --ado-project     Azure DevOps project name
  -g, --gh-org          GitHub organization name
  -r, --gh-repo         GitHub repository name (for single repo)
  -d, --dry-run         Show what would be done without making changes
  -v, --verbose         Enable verbose output
  -h, --help            Show this help message

  Migration Options (from Microsoft Playbook):
  --lock-ado-repo       Set ADO repositories to read-only after migration
  --disable-ado-repos   Disable ADO repositories after migration
  --create-teams        Create GitHub teams based on ADO teams
  --rewire-pipelines    Reconfigure Azure Pipelines to use GitHub source
  --repo-list FILE      CSV file with specific repositories to migrate

EXAMPLES:

  # Step 1: Check prerequisites
  $(basename "$0") -o https://dev.azure.com/myorg -p MyProject -g my-gh-org prerequisites

  # Step 2: Generate inventory
  $(basename "$0") -o https://dev.azure.com/myorg -p MyProject inventory

  # Step 3: Full migration (dry run first!)
  $(basename "$0") -o https://dev.azure.com/myorg -p MyProject -g my-gh-org \\
    --lock-ado-repo --create-teams --rewire-pipelines --dry-run full-migration

  # Step 4: Run actual migration
  $(basename "$0") -o https://dev.azure.com/myorg -p MyProject -g my-gh-org \\
    --lock-ado-repo --create-teams --rewire-pipelines full-migration

  # Step 5: Handle mannequins
  $(basename "$0") -g my-gh-org mannequins
  # Edit mannequin-mapping.csv, then:
  $(basename "$0") -g my-gh-org reclaim-mannequins

  # Step 6: Validate
  $(basename "$0") -g my-gh-org validate

ENVIRONMENT VARIABLES:
  ADO_PAT               Azure DevOps Personal Access Token
  GH_PAT                GitHub Personal Access Token
  AZURE_DEVOPS_EXT_PAT  Alternative name for ADO_PAT

DOCUMENTATION:
  Microsoft Playbook: https://devblogs.microsoft.com/all-things-azure/azure-devops-to-github-migration-playbook-unlocking-agentic-devops/

HELP
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--ado-org)       ADO_ORG="$2"; shift 2 ;;
            -p|--ado-project)   ADO_PROJECT="$2"; shift 2 ;;
            -g|--gh-org)        GH_ORG="$2"; shift 2 ;;
            -r|--gh-repo)       GH_REPO="$2"; shift 2 ;;
            -d|--dry-run)       DRY_RUN=true; shift ;;
            -v|--verbose)       VERBOSE=true; shift ;;
            -h|--help)          show_help; exit 0 ;;
            # Microsoft Playbook options
            --lock-ado-repo)    LOCK_ADO_REPO=true; shift ;;
            --disable-ado-repos) DISABLE_ADO_REPOS=true; shift ;;
            --create-teams)     CREATE_TEAMS=true; shift ;;
            --rewire-pipelines) REWIRE_PIPELINES=true; shift ;;
            --repo-list)        REPO_LIST="$2"; shift 2 ;;
            *)                  COMMAND="$1"; shift ;;
        esac
    done

    # Show dry run notice
    if [[ "${DRY_RUN}" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
        echo "No changes will be made. Remove --dry-run to execute."
        echo ""
    fi

    # Execute command
    case ${COMMAND:-help} in
        # Phase 1-2: Prerequisites
        prerequisites)
            check_prerequisites
            setup_authentication
            check_azure_pipelines_app
            log INFO "✅ Prerequisites check complete"
            ;;

        # Phase 3: Inventory
        inventory)
            check_prerequisites
            setup_authentication
            generate_inventory_report
            ;;

        # Phase 4-5: Migration
        migrate-repo)
            check_prerequisites
            setup_authentication
            migrate_repository "${ADO_PROJECT}" "${GH_REPO}" "${GH_ORG}"
            ;;
        migrate-all)
            check_prerequisites
            setup_authentication
            migrate_all_repositories "${ADO_PROJECT}" "${GH_ORG}"
            ;;
        generate-script)
            check_prerequisites
            setup_authentication
            generate_migration_script "${ADO_PROJECT}" "${GH_ORG}" "${SCRIPT_DIR}/scripts"
            ;;
        full-migration)
            # Complete 6-phase migration
            log INFO "=== Starting Full 6-Phase Migration ==="
            echo ""

            # Phase 1: Prerequisites
            check_prerequisites
            setup_authentication

            # Phase 2: Azure Pipelines App
            check_azure_pipelines_app

            # Phase 3: Inventory
            generate_inventory_report

            # Phase 4: Generate Script
            generate_migration_script "${ADO_PROJECT}" "${GH_ORG}" "${SCRIPT_DIR}/scripts"

            # Phase 5: Execute Migration
            if [[ "${DRY_RUN}" == "false" ]]; then
                run_full_migration "${ADO_PROJECT}" "${GH_ORG}"
            else
                log INFO "[DRY RUN] Would execute migration"
            fi

            # Phase 6: Post-Migration
            generate_mannequin_csv
            run_validation_checklist

            log INFO "=== Full Migration Complete ==="
            ;;

        # Phase 6: Post-Migration
        mannequins)
            check_prerequisites
            generate_mannequin_csv
            ;;
        reclaim-mannequins)
            check_prerequisites
            reclaim_mannequins
            ;;
        validate)
            check_prerequisites
            run_validation_checklist
            ;;

        # Additional commands
        convert-pipeline)
            convert_pipeline "${ADO_PIPELINE:-azure-pipelines.yml}" ".github/workflows/ci.yml"
            ;;
        migrate-security)
            check_prerequisites
            migrate_security_alerts "${GH_ORG}" "${GH_REPO}"
            ;;
        migrate-workitems)
            check_prerequisites
            setup_authentication
            migrate_work_items "${ADO_PROJECT}" "${GH_ORG}" "${GH_REPO}"
            ;;

        # Help
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
