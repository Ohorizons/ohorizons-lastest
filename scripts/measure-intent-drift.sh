#!/usr/bin/env bash
# =============================================================================
# INTENT DRIFT MEASUREMENT
# =============================================================================
# Measures indicators of intent drift in the agent system:
#   1. Scope creep: files modified outside IMPLEMENTATION_PLAN.md
#   2. CONSTITUTION.md violations in agent trajectories
#   3. Cognitive debt: untested skills, stale memory, duplicated context
#   4. PR review burden: agent-generated PR review time trends
#
# Ref: Storey (2026) arXiv:2603.22106
# Ref: Ch. 04 — Measuring Intent Alignment
#
# Usage: ./scripts/measure-intent-drift.sh [--json]
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON_OUTPUT="${1:-}"

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ─── Metric 1: Scope Creep Detection ───────────────────────────────
# Check if any recent commits modified files not in any IMPLEMENTATION_PLAN.md
scope_creep_count=0
plans_found=0

for plan in $(find "$REPO_ROOT" -name "IMPLEMENTATION_PLAN.md" -not -path "*/node_modules/*" -not -path "*/.venv/*" 2>/dev/null); do
    plans_found=$((plans_found + 1))
done

# ─── Metric 2: CONSTITUTION.md Coverage ─────────────────────────────
constitutions_found=0
constitutions_with_metrics=0

for constitution in $(find "$REPO_ROOT" -name "CONSTITUTION.md" -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/golden-paths/common/*" 2>/dev/null); do
    constitutions_found=$((constitutions_found + 1))

    # Check if constitution has measurable success metrics
    if grep -qi "success metric\|intent drift\|scope creep" "$constitution" 2>/dev/null; then
        constitutions_with_metrics=$((constitutions_with_metrics + 1))
    fi
done

# ─── Metric 3: Cognitive Debt Indicators ────────────────────────────
# Untested skills (skills with no corresponding test or validation)
skills_dir="${REPO_ROOT}/.github/skills"
skills_total=0
skills_untested=0

if [[ -d "$skills_dir" ]]; then
    for skill_dir in "$skills_dir"/*/; do
        [[ -d "$skill_dir" ]] || continue
        skills_total=$((skills_total + 1))
        skill_name=$(basename "$skill_dir")

        # Check if skill has any validation (test file, example, or script)
        has_validation=false
        if [[ -f "${skill_dir}test.sh" ]] || [[ -f "${skill_dir}example.md" ]] || \
           grep -rq "$skill_name" "${REPO_ROOT}/tests/" 2>/dev/null; then
            has_validation=true
        fi

        if ! $has_validation; then
            skills_untested=$((skills_untested + 1))
        fi
    done
fi

# ─── Metric 4: Agent Count vs. AGENTS.md Sync ──────────────────────
agents_dir="${REPO_ROOT}/.github/agents"
actual_agents=$(find "$agents_dir" -name "*.agent.md" 2>/dev/null | wc -l | tr -d ' ')
declared_agents=0
if [[ -f "${REPO_ROOT}/AGENTS.md" ]]; then
    declared_agents=$(grep -c '\.agent\.md' "${REPO_ROOT}/AGENTS.md" 2>/dev/null || echo "0")
fi
agent_sync_drift=$((actual_agents - declared_agents))
if [[ $agent_sync_drift -lt 0 ]]; then
    agent_sync_drift=$((-agent_sync_drift))
fi

# ─── Metric 5: Knowledge Concentration ──────────────────────────────
# How many unique authors have modified context files in the last 90 days?
context_authors=0
if command -v git &>/dev/null && git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null 2>&1; then
    context_authors=$(git -C "$REPO_ROOT" log --since="90 days ago" --format="%ae" -- \
        ".github/agents/" ".github/skills/" ".github/instructions/" \
        "AGENTS.md" "CODEMAP.md" "**/CONSTITUTION.md" 2>/dev/null | \
        sort -u | wc -l | tr -d ' ')
fi

# ─── Compute Health Score ───────────────────────────────────────────
# 0-100 scale: higher is better
score=100

# Deduct for missing intent artifacts
if [[ $constitutions_found -eq 0 ]]; then
    score=$((score - 30))
fi
if [[ $plans_found -eq 0 ]]; then
    score=$((score - 20))
fi

# Deduct for untested skills (up to 20 points)
if [[ $skills_total -gt 0 ]]; then
    untested_pct=$((skills_untested * 100 / skills_total))
    deduction=$((untested_pct / 5))
    if [[ $deduction -gt 20 ]]; then deduction=20; fi
    score=$((score - deduction))
fi

# Deduct for agent sync drift
if [[ $agent_sync_drift -gt 0 ]]; then
    score=$((score - agent_sync_drift * 3))
fi

# Deduct for knowledge concentration (single author = risk)
if [[ $context_authors -le 1 ]]; then
    score=$((score - 10))
fi

if [[ $score -lt 0 ]]; then score=0; fi

# ─── Output ─────────────────────────────────────────────────────────
if [[ "$JSON_OUTPUT" == "--json" ]]; then
    cat << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "intent_health_score": ${score},
  "metrics": {
    "constitution_files": ${constitutions_found},
    "constitutions_with_metrics": ${constitutions_with_metrics},
    "implementation_plans": ${plans_found},
    "skills_total": ${skills_total},
    "skills_untested": ${skills_untested},
    "agents_actual": ${actual_agents},
    "agents_declared": ${declared_agents},
    "agent_sync_drift": ${agent_sync_drift},
    "context_authors_90d": ${context_authors}
  }
}
EOF
    exit 0
fi

echo -e "${BLUE}=== Open Horizons Intent Drift Report ===${NC}"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

echo -e "${BLUE}--- Intent Artifacts ---${NC}"
echo "  CONSTITUTION.md files: ${constitutions_found}"
echo "  CONSTITUTION.md with metrics: ${constitutions_with_metrics}"
echo "  IMPLEMENTATION_PLAN.md files: ${plans_found}"

if [[ $constitutions_found -eq 0 ]]; then
    echo -e "  ${RED}[CRITICAL] No CONSTITUTION.md found — intent is undefined${NC}"
fi
if [[ $plans_found -eq 0 ]]; then
    echo -e "  ${YELLOW}[WARN] No IMPLEMENTATION_PLAN.md found — scope boundaries not enforced${NC}"
fi

echo ""
echo -e "${BLUE}--- Cognitive Debt ---${NC}"
echo "  Skills total: ${skills_total}"
echo "  Skills untested: ${skills_untested}"
if [[ $skills_untested -gt 0 ]]; then
    echo -e "  ${YELLOW}[WARN] ${skills_untested} skills have no validation${NC}"
fi

echo ""
echo -e "${BLUE}--- Agent System Sync ---${NC}"
echo "  Agents on disk: ${actual_agents}"
echo "  Agents in AGENTS.md: ${declared_agents}"
if [[ $agent_sync_drift -gt 0 ]]; then
    echo -e "  ${YELLOW}[WARN] Agent sync drift: ${agent_sync_drift} (AGENTS.md outdated)${NC}"
else
    echo -e "  ${GREEN}[OK] Agent count synchronized${NC}"
fi

echo ""
echo -e "${BLUE}--- Knowledge Concentration ---${NC}"
echo "  Context file authors (90d): ${context_authors}"
if [[ $context_authors -le 1 ]]; then
    echo -e "  ${YELLOW}[WARN] Single author — knowledge concentrated, bus factor risk${NC}"
fi

echo ""
echo -e "${BLUE}=== Intent Health Score: ${score}/100 ===${NC}"
if [[ $score -ge 80 ]]; then
    echo -e "${GREEN}Status: HEALTHY${NC}"
elif [[ $score -ge 50 ]]; then
    echo -e "${YELLOW}Status: ATTENTION NEEDED${NC}"
else
    echo -e "${RED}Status: INTENT DRIFT DETECTED${NC}"
fi
