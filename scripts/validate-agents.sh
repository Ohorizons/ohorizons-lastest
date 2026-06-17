#!/bin/bash
#
# validate-agents.sh - Validate all agent specification files
#
# This script checks:
# - All agent files exist and are non-empty
# - Required sections are present in each file
# - MCP server references are valid
# - Cross-references between agents are valid
#
# Usage: ./scripts/validate-agents.sh [--verbose]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$PROJECT_ROOT/.github/agents"

# Counters
TOTAL_AGENTS=0
VALID_AGENTS=0
WARNINGS=0
ERRORS=0

# Verbose mode
VERBOSE=false
if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
    VERBOSE=true
fi

# Print functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

print_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}ℹ️  $1${NC}"
    fi
}

# Required sections in agent files
REQUIRED_SECTIONS=(
    "tools"
    "description"
)

# Expected agent files (flat structure in .github/agents/).
# Keep as parallel indexed arrays for compatibility with macOS Bash 3.2.
EXPECTED_AGENT_FILES=(
    "deploy.agent.md"
    "architect.agent.md"
    "devops.agent.md"
    "platform.agent.md"
    "terraform.agent.md"
    "security.agent.md"
    "sre.agent.md"
    "reviewer.agent.md"
    "test.agent.md"
    "docs.agent.md"
    "backstage-expert.agent.md"
    "azure-portal-deploy.agent.md"
    "github-integration.agent.md"
    "ado-integration.agent.md"
    "hybrid-scenarios.agent.md"
    "prompt.agent.md"
    "compass.agent.md"
    "pipeline.agent.md"
    "sentinel.agent.md"
)

EXPECTED_AGENT_NAMES=(
    "Deploy Agent"
    "Architect Agent"
    "DevOps Agent"
    "Platform Agent"
    "Terraform Agent"
    "Security Agent"
    "SRE Agent"
    "Reviewer Agent"
    "Test Agent"
    "Docs Agent"
    "Backstage Expert Agent"
    "Azure Portal Deploy Agent"
    "GitHub Integration Agent"
    "ADO Integration Agent"
    "Hybrid Scenarios Agent"
    "Prompt Engineer Agent"
    "Compass Agent"
    "Pipeline Agent"
    "Sentinel Agent"
)

# Valid MCP servers
VALID_MCP_SERVERS=(
    "kubernetes"
    "azure"
    "github"
    "helm"
    "terraform"
    "git"
    "azure-ai"
    "prometheus"
)

# Validate single agent file
validate_agent() {
    local file_path="$1"
    local agent_name="$2"
    local full_path="$AGENTS_DIR/$file_path"
    local file_valid=true

    print_info "Validating: $agent_name"

    # Check file exists
    if [[ ! -f "$full_path" ]]; then
        print_error "$agent_name: File not found ($file_path)"
        return 1
    fi

    # Check file is not empty
    if [[ ! -s "$full_path" ]]; then
        print_error "$agent_name: File is empty"
        return 1
    fi

    # Get line count
    local line_count
    line_count=$(wc -l < "$full_path")
    if [[ $line_count -lt 50 ]]; then
        print_warning "$agent_name: File seems too short ($line_count lines)"
        file_valid=false
    fi

    # Check required sections
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if ! grep -qi "$section" "$full_path"; then
            print_warning "$agent_name: Missing section '$section'"
            file_valid=false
        fi
    done

    # Check for MCP server references
    if ! grep -qi "mcp" "$full_path"; then
        print_warning "$agent_name: No MCP server references found"
        file_valid=false
    fi

    # Check for YAML frontmatter (---)
    if ! head -1 "$full_path" | grep -q '^---'; then
        print_warning "$agent_name: Missing YAML frontmatter"
        file_valid=false
    fi

    if [[ "$file_valid" == true ]]; then
        print_success "$agent_name: Valid ($line_count lines)"
        return 0
    else
        return 1
    fi
}

# Validate directory structure
validate_structure() {
    print_header "Validating Directory Structure"

    if [[ -d "$AGENTS_DIR" ]]; then
        local count
        count=$(find "$AGENTS_DIR" -maxdepth 1 -name "*.agent.md" | wc -l)
        print_success "Agent directory found: $count agents"
    else
        print_error "Agent directory not found: $AGENTS_DIR"
    fi
}

# Validate all agent files
validate_agents() {
    print_header "Validating Agent Specifications"

    local index
    for index in "${!EXPECTED_AGENT_FILES[@]}"; do
        local file_path="${EXPECTED_AGENT_FILES[$index]}"
        local agent_name="${EXPECTED_AGENT_NAMES[$index]}"

        ((TOTAL_AGENTS++))
        if validate_agent "$file_path" "$agent_name"; then
            ((VALID_AGENTS++))
        fi
    done
}

# Validate documentation files
validate_docs() {
    print_header "Validating Documentation Files"

    local docs=(
        "README.md"
        "INDEX.md"
        "DEPLOYMENT_SEQUENCE.md"
        "MCP_SERVERS_GUIDE.md"
        "TERRAFORM_MODULES_REFERENCE.md"
        "DEPENDENCY_GRAPH.md"
    )

    for doc in "${docs[@]}"; do
        if [[ -f "$AGENTS_DIR/$doc" ]]; then
            local line_count
            line_count=$(wc -l < "$AGENTS_DIR/$doc")
            print_success "$doc: Found ($line_count lines)"
        else
            print_warning "$doc: Not found (optional)"
        fi
    done
}

# Check cross-references
validate_crossrefs() {
    print_header "Validating Cross-References"

    # Check for broken links within agents directory
    local broken_links=0

    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Extract markdown links
            while IFS= read -r link; do
                # Skip external links
                if [[ "$link" == http* ]]; then
                    continue
                fi

                # Check if referenced file exists
                local ref_path="$AGENTS_DIR/$link"
                local dir_path
                dir_path=$(dirname "$file")
                local rel_path="$dir_path/$link"

                if [[ ! -f "$ref_path" && ! -f "$rel_path" ]]; then
                    if [[ "$VERBOSE" == true ]]; then
                        print_warning "Broken link in $(basename "$file"): $link"
                    fi
                    ((broken_links++))
                fi
            done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$file" 2>/dev/null | sed 's/.*](//' | sed 's/)$//' || true)
        fi
    done < <(find "$AGENTS_DIR" -type f -name '*.md' | sort)

    if [[ $broken_links -eq 0 ]]; then
        print_success "No broken cross-references found"
    else
        print_warning "$broken_links potential broken links found (run with --verbose for details)"
    fi
}

# Generate summary
print_summary() {
    print_header "Validation Summary"

    echo -e "Total Agents:    ${BLUE}$TOTAL_AGENTS${NC}"
    echo -e "Valid Agents:    ${GREEN}$VALID_AGENTS${NC}"
    echo -e "Warnings:        ${YELLOW}$WARNINGS${NC}"
    echo -e "Errors:          ${RED}$ERRORS${NC}"
    echo ""

    local percentage=$((VALID_AGENTS * 100 / TOTAL_AGENTS))

    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        print_success "All validations passed! ($percentage% agents valid)"
        exit 0
    elif [[ $ERRORS -eq 0 ]]; then
        print_warning "Validation completed with warnings ($percentage% agents valid)"
        exit 0
    else
        print_error "Validation failed with errors ($percentage% agents valid)"
        exit 1
    fi
}

# Main execution
main() {
    print_header "Open Horizons Agent Validator"

    echo "Project Root: $PROJECT_ROOT"
    echo "Agents Dir:   $AGENTS_DIR"
    echo ""

    validate_structure
    validate_agents
    validate_docs
    validate_crossrefs
    print_summary
}

main "$@"
