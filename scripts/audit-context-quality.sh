#!/usr/bin/env bash
# =============================================================================
# CONTEXT QUALITY AUDIT — Context Rot Measurement
# =============================================================================
# Measures freshness and quality of context artifacts (skills, agents,
# instructions, MCP tools) to detect context rot before it degrades agents.
#
# Ref: DataHub (2026) "State of AI Context Report"
# Ref: FlowHunt (2026) "Context Rot Across Leading LLMs"
#
# Usage: ./scripts/audit-context-quality.sh [--verbose]
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERBOSE="${1:-}"
NOW=$(date +%s)
STALE_THRESHOLD_DAYS=30
STALE_SECONDS=$((STALE_THRESHOLD_DAYS * 86400))

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

total_issues=0
total_checked=0

log_issue() {
    local severity="$1" color="$2" msg="$3"
    echo -e "  ${color}[${severity}]${NC} ${msg}"
    total_issues=$((total_issues + 1))
}

echo -e "${BLUE}=== Open Horizons Context Quality Audit ===${NC}"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Stale threshold: ${STALE_THRESHOLD_DAYS} days"
echo ""

# ─── Check Skills ───────────────────────────────────────────────────
echo -e "${BLUE}--- Skills (.github/skills/) ---${NC}"
skills_dir="${REPO_ROOT}/.github/skills"
skills_total=0
skills_no_desc=0
skills_stale=0

if [[ -d "$skills_dir" ]]; then
    for skill_dir in "$skills_dir"/*/; do
        [[ -d "$skill_dir" ]] || continue
        skill_name=$(basename "$skill_dir")
        skill_file="${skill_dir}SKILL.md"
        skills_total=$((skills_total + 1))
        total_checked=$((total_checked + 1))

        if [[ ! -f "$skill_file" ]]; then
            log_issue "ERROR" "$RED" "Skill '${skill_name}' has no SKILL.md"
            continue
        fi

        # Check for description (routing description)
        if ! grep -qi "^description:" "$skill_file" 2>/dev/null && \
           ! grep -qi "USE FOR:" "$skill_file" 2>/dev/null; then
            log_issue "WARN" "$YELLOW" "Skill '${skill_name}' lacks routing description (invisible to agents)"
            skills_no_desc=$((skills_no_desc + 1))
        fi

        # Check staleness
        last_modified=$(stat -f %m "$skill_file" 2>/dev/null || stat -c %Y "$skill_file" 2>/dev/null || echo "0")
        age=$((NOW - last_modified))
        if [[ $age -gt $STALE_SECONDS ]]; then
            days_old=$((age / 86400))
            if [[ "$VERBOSE" == "--verbose" ]]; then
                log_issue "INFO" "$YELLOW" "Skill '${skill_name}' last modified ${days_old} days ago"
            fi
            skills_stale=$((skills_stale + 1))
        fi
    done
fi

echo "  Skills: ${skills_total} total, ${skills_no_desc} missing description, ${skills_stale} stale (>${STALE_THRESHOLD_DAYS}d)"

# ─── Check Agents ───────────────────────────────────────────────────
echo -e "${BLUE}--- Agents (.github/agents/) ---${NC}"
agents_dir="${REPO_ROOT}/.github/agents"
agents_total=0
agents_no_tools=0
agents_stale=0

if [[ -d "$agents_dir" ]]; then
    for agent_file in "$agents_dir"/*.agent.md; do
        [[ -f "$agent_file" ]] || continue
        agent_name=$(basename "$agent_file" .agent.md)
        agents_total=$((agents_total + 1))
        total_checked=$((total_checked + 1))

        # Check for tools definition
        if ! grep -qi "^tools:" "$agent_file" 2>/dev/null; then
            if [[ "$VERBOSE" == "--verbose" ]]; then
                log_issue "INFO" "$YELLOW" "Agent '${agent_name}' has no tools: frontmatter"
            fi
            agents_no_tools=$((agents_no_tools + 1))
        fi

        # Check staleness
        last_modified=$(stat -f %m "$agent_file" 2>/dev/null || stat -c %Y "$agent_file" 2>/dev/null || echo "0")
        age=$((NOW - last_modified))
        if [[ $age -gt $STALE_SECONDS ]]; then
            agents_stale=$((agents_stale + 1))
        fi
    done
fi

echo "  Agents: ${agents_total} total, ${agents_no_tools} no tools, ${agents_stale} stale"

# ─── Check Instructions ─────────────────────────────────────────────
echo -e "${BLUE}--- Instructions (.github/instructions/) ---${NC}"
instr_dir="${REPO_ROOT}/.github/instructions"
instr_total=0
instr_no_apply=0

if [[ -d "$instr_dir" ]]; then
    for instr_file in "$instr_dir"/*.instructions.md; do
        [[ -f "$instr_file" ]] || continue
        instr_name=$(basename "$instr_file" .instructions.md)
        instr_total=$((instr_total + 1))
        total_checked=$((total_checked + 1))

        if ! grep -qi "^applyTo:" "$instr_file" 2>/dev/null; then
            log_issue "WARN" "$YELLOW" "Instruction '${instr_name}' missing applyTo (loaded globally, wasting tokens)"
            instr_no_apply=$((instr_no_apply + 1))
        fi
    done
fi

echo "  Instructions: ${instr_total} total, ${instr_no_apply} missing applyTo"

# ─── Check MCP Tool Descriptions ────────────────────────────────────
echo -e "${BLUE}--- MCP Tool Descriptions (mcp-servers/src/tools/) ---${NC}"
tools_dir="${REPO_ROOT}/mcp-servers/src/tools"
tools_total=0
tools_vague=0

if [[ -d "$tools_dir" ]]; then
    for tool_file in "$tools_dir"/*.ts; do
        [[ -f "$tool_file" ]] || continue
        tool_name=$(basename "$tool_file" .ts)
        tools_total=$((tools_total + 1))
        total_checked=$((total_checked + 1))

        # Check for vague descriptions (tool description smells)
        if grep -q 'description:.*"[^"]\{0,30\}"' "$tool_file" 2>/dev/null; then
            log_issue "WARN" "$YELLOW" "MCP tool '${tool_name}' may have vague description (<30 chars)"
            tools_vague=$((tools_vague + 1))
        fi
    done
fi

echo "  MCP tools: ${tools_total} total, ${tools_vague} potentially vague descriptions"

# ─── Check AGENTS.md sync ───────────────────────────────────────────
echo -e "${BLUE}--- AGENTS.md Sync Check ---${NC}"
agents_md="${REPO_ROOT}/AGENTS.md"
if [[ -f "$agents_md" ]]; then
    declared_agents=$(grep -c '\.agent\.md' "$agents_md" 2>/dev/null || echo "0")
    actual_agents=$(find "$agents_dir" -name "*.agent.md" 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$declared_agents" -ne "$actual_agents" ]]; then
        log_issue "ERROR" "$RED" "AGENTS.md lists ${declared_agents} agents but ${actual_agents} exist on disk"
    else
        echo -e "  ${GREEN}[OK]${NC} AGENTS.md agent count matches (${actual_agents})"
    fi
fi

# ─── Summary ────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo "  Artifacts checked: ${total_checked}"
echo "  Issues found: ${total_issues}"

if [[ $total_issues -eq 0 ]]; then
    echo -e "  ${GREEN}Context quality: HEALTHY${NC}"
    exit 0
elif [[ $total_issues -lt 5 ]]; then
    echo -e "  ${YELLOW}Context quality: ATTENTION NEEDED${NC}"
    exit 0
else
    echo -e "  ${RED}Context quality: DEGRADED — context rot detected${NC}"
    exit 1
fi
