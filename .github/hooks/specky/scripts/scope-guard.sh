#!/usr/bin/env bash
# =============================================================================
# SCOPE GUARD — preToolUse Hook for Spec-Driven Development
# =============================================================================
# Blocks file writes that fall outside the IMPLEMENTATION_PLAN.md scope.
# Zero token cost: runs as a shell conditional, not an LLM call.
#
# Ref: SDD (2026) arXiv:2602.00180
# Ref: Ch. 04 — Hooks as Zero-Cost Intent Enforcement
#
# Usage: Called automatically by the hook system before any file write.
#   Input (stdin JSON): {"tool": "write_file", "path": "/abs/path/to/file.py"}
#   Output: exit 0 = allow, exit 1 = block (message on stdout)
# =============================================================================

set -euo pipefail

# Find the implementation plan
find_plan() {
    local search_dir="${1:-.}"
    local plan=""

    # Search current dir, then parent, up to repo root
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "${search_dir}/IMPLEMENTATION_PLAN.md" ]]; then
            plan="${search_dir}/IMPLEMENTATION_PLAN.md"
            break
        fi
        search_dir=$(dirname "$search_dir")
    done

    echo "$plan"
}

# Parse allowed files from the plan's "Files in Scope" section
parse_allowed_files() {
    local plan_file="$1"
    local in_scope=false

    while IFS= read -r line; do
        # Detect start of scope block
        if echo "$line" | grep -qi "files in scope"; then
            in_scope=true
            continue
        fi

        # Detect end of scope block
        if $in_scope && echo "$line" | grep -qi "files.*out of scope\|^##\|^###"; then
            in_scope=false
            continue
        fi

        # Extract file paths from scope block
        if $in_scope; then
            # Match lines like "  src/module.py  [CREATE]" or "  src/module.py  [MODIFY]"
            file_path=$(echo "$line" | sed -n 's/^[[:space:]]*\([^ ]*\.[a-z]*\).*/\1/p')
            if [[ -n "$file_path" ]]; then
                echo "$file_path"
            fi
        fi
    done < "$plan_file"
}

# Main: read tool invocation from stdin or arguments
TOOL="${1:-}"
FILE_PATH="${2:-}"

# If no arguments, try reading JSON from stdin
if [[ -z "$TOOL" ]]; then
    if command -v jq &>/dev/null; then
        input=$(cat)
        TOOL=$(echo "$input" | jq -r '.tool // empty' 2>/dev/null || echo "")
        FILE_PATH=$(echo "$input" | jq -r '.path // empty' 2>/dev/null || echo "")
    fi
fi

# Only guard write operations
case "$TOOL" in
    write_file|create_file|edit_file|replace_in_file)
        ;;
    *)
        # Not a write operation, allow
        exit 0
        ;;
esac

# Find the implementation plan
PLAN=$(find_plan "$(dirname "$FILE_PATH" 2>/dev/null || echo ".")")

if [[ -z "$PLAN" ]]; then
    # No plan found — in SDD strict mode this would block all writes.
    # In permissive mode (default), allow writes when no plan exists.
    exit 0
fi

# Parse allowed files
ALLOWED_FILES=$(parse_allowed_files "$PLAN")

if [[ -z "$ALLOWED_FILES" ]]; then
    # Plan exists but has no parseable scope section — allow (permissive)
    exit 0
fi

# Check if the target file is in scope
REL_PATH=$(echo "$FILE_PATH" | sed "s|.*/||")  # basename as fallback

for allowed in $ALLOWED_FILES; do
    # Match on basename or relative path
    if [[ "$FILE_PATH" == *"$allowed"* ]] || [[ "$REL_PATH" == "$(basename "$allowed")" ]]; then
        exit 0
    fi
done

# File not in scope — block the write
echo "SCOPE GUARD: File '${FILE_PATH}' is not in the approved scope."
echo "Approved files (from ${PLAN}):"
echo "$ALLOWED_FILES" | sed 's/^/  - /'
echo ""
echo "To modify this file, add it to the 'Files in Scope' section of IMPLEMENTATION_PLAN.md"
exit 1
