#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# validate-docs.sh — Documentation Link Validator
# Open Horizons Platform v4
#
# Scans all Markdown files for broken relative links (files and anchors).
# Usage: ./scripts/validate-docs.sh [--verbose] [--fix-suggestions]
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERBOSE=false
FIX_SUGGESTIONS=false
INCLUDE_SKELETONS=false
ERRORS=0
WARNINGS=0
CHECKED=0
FILES_SCANNED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Validates all documentation links in the repository.

Options:
    --verbose           Show all checked links (not just broken ones)
    --fix-suggestions   Show suggested fixes for broken links
    --include-skeletons Validate generated Golden Path skeleton docs too
    -h, --help          Show this help message

Examples:
    $(basename "$0")                        # Quick validation
    $(basename "$0") --verbose              # Show all links
    $(basename "$0") --fix-suggestions      # Show fix suggestions
    $(basename "$0") --include-skeletons    # Include Golden Path skeleton docs
EOF
}

log_error() {
    echo -e "${RED}✗ ERROR${NC}: $1"
    ERRORS=$((ERRORS + 1))
}

log_warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    WARNINGS=$((WARNINGS + 1))
}

log_ok() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${GREEN}✓${NC} $1"
    fi
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if a relative file link target exists
check_file_link() {
    local source_file="$1"
    local link_target="$2"
    local source_dir
    source_dir="$(dirname "$source_file")"

    # Strip anchor (#...) from link
    local file_path="${link_target%%#*}"

    # Skip empty file paths (pure anchor links like #section)
    if [[ -z "$file_path" ]]; then
        return 0
    fi

    # Skip external URLs
    if [[ "$file_path" =~ ^https?:// ]] || [[ "$file_path" =~ ^mailto: ]]; then
        return 0
    fi

    # Skip URI schemes (vscode://, file://, etc.)
    if [[ "$file_path" =~ ^[a-zA-Z]+:// ]]; then
        return 0
    fi

    ((CHECKED++)) || true

    # Resolve relative path (macOS compatible)
    local resolved_path
    if [[ -e "$source_dir/$file_path" ]]; then
        resolved_path="$source_dir/$file_path"
    else
        resolved_path=""
    fi

    if [[ -z "$resolved_path" ]]; then
        local rel_source="${source_file#$ROOT_DIR/}"
        log_error "$rel_source → $link_target (target not found)"
        if [[ "$FIX_SUGGESTIONS" == true ]]; then
            suggest_fix "$source_file" "$file_path"
        fi
        return 1
    else
        local rel_source="${source_file#$ROOT_DIR/}"
        log_ok "$rel_source → $link_target"
        return 0
    fi
}

# Suggest possible fixes for broken links
suggest_fix() {
    local source_file="$1"
    local broken_path="$2"
    local basename_target
    basename_target="$(basename "$broken_path")"

    # Search for files with the same name
    local matches
    matches=$(find "$ROOT_DIR" -name "$basename_target" -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | head -5)

    if [[ -n "$matches" ]]; then
        echo -e "  ${YELLOW}Suggestions:${NC}"
        while IFS= read -r match; do
            local rel_match="${match#$ROOT_DIR/}"
            echo -e "    → $rel_match"
        done <<< "$matches"
    fi
}

# Extract markdown links from a file
extract_links() {
    local file="$1"
    # Match [text](link) patterns, extract the link part
    # Compatible with macOS (BSD grep) — no -P flag
    grep -oE '\[[^]]*\]\([^)]+\)' "$file" 2>/dev/null | \
        sed 's/.*](//' | \
        sed 's/)$//' | \
        { grep -v '^#' || true; } | \
        sort -u || true
}

# Main validation
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose) VERBOSE=true; shift ;;
            --fix-suggestions) FIX_SUGGESTIONS=true; shift ;;
            --include-skeletons) INCLUDE_SKELETONS=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    echo "======================================"
    echo " Documentation Link Validator"
    echo " Open Horizons Platform v4"
    echo "======================================"
    echo ""

    cd "$ROOT_DIR"

    # Find all markdown files
    local md_files
    local find_args=(
        -name '*.md'
        -not -path '*/node_modules/*'
        -not -path './.git/*'
        -not -path './vendor/*'
        -not -path '*/.terraform/*'
    )

    if [[ "$INCLUDE_SKELETONS" != true ]]; then
        find_args+=(-not -path '*/skeleton/*')
    fi

    md_files=$(find . "${find_args[@]}" | sort)

    for md_file in $md_files; do
        local full_path="$ROOT_DIR/${md_file#./}"
        ((FILES_SCANNED++)) || true

        # Extract and check links
        local links
        links=$(extract_links "$full_path")

        if [[ -n "$links" ]]; then
            while IFS= read -r link; do
                check_file_link "$full_path" "$link" || true
            done <<< "$links"
        fi
    done

    echo ""
    echo "======================================"
    echo " Results"
    echo "======================================"
    echo -e " Files scanned:  ${BLUE}${FILES_SCANNED}${NC}"
    echo -e " Links checked:  ${BLUE}${CHECKED}${NC}"
    echo -e " Errors:         ${RED}${ERRORS}${NC}"
    echo -e " Warnings:       ${YELLOW}${WARNINGS}${NC}"
    echo "======================================"

    if [[ $ERRORS -gt 0 ]]; then
        echo ""
        echo -e "${RED}Documentation validation FAILED with $ERRORS error(s).${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}Documentation validation PASSED. All links are valid.${NC}"
        exit 0
    fi
}

main "$@"
