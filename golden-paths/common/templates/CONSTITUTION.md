# CONSTITUTION.md — Template

> Machine-readable intent artifact for agent governance.
> Version: 0.1.0 | Owner: [TEAM_NAME] | Last reviewed: [DATE]
>
> Ref: Vishnyakova (2026) arXiv:2603.09619
> Ref: SDD (2026) arXiv:2601.03878

## Non-Negotiable Principles

<!-- List 4-8 principles that are NEVER violated, regardless of context. -->
<!-- These are your organizational values encoded for machines. -->

1. **[PRINCIPLE_1]** — [Description of what this means in practice]
2. **[PRINCIPLE_2]** — [Description]
3. **[PRINCIPLE_3]** — [Description]
4. **Agents NEVER fabricate data** — if data is unavailable, say so explicitly

## Trade-Off Hierarchy

<!-- When two goals conflict, which wins? List in priority order. -->

1. **Security** > Speed > Cost
2. **Accuracy** > Completeness
3. **User safety** > Agent autonomy

## Scope Boundaries

### ALWAYS (Green — no approval needed)

- [Action the agent can always take]
- [Another always-permitted action]

### ASK FIRST (Yellow — requires human confirmation)

- [Action that needs human approval before execution]
- [Another gated action]

### NEVER (Red — hard block, no exceptions)

- [Action the agent must never take]
- Never modify production infrastructure without approval
- Never expose secrets, tokens, or credentials in responses

## Agent RBAC Levels

| Level | Permissions | Assigned To |
|---|---|---|
| viewer | Read catalog, read docs | [agent_names] |
| contributor | + Create issues, search repos | [agent_names] |
| deployer | + Trigger deployments, modify infra | [agent_names] |
| owner | + Modify CONSTITUTION.md, promote agents | [human_roles] |

## Success Metrics

<!-- How do you know the agent is doing its job? -->

| Metric | Target | Measurement |
|---|---|---|
| Intent drift rate | < 0.1% | % of decisions violating this constitution |
| Scope creep rate | < 5% per session | % of proposed edits outside IMPLEMENTATION_PLAN.md |
| Human review time | Decreasing trend | Minutes per agent-generated PR |

## Review Cadence

- **Weekly:** Agent owner reviews trajectory logs for drift
- **Monthly:** Team reviews CONSTITUTION.md for relevance
- **Quarterly:** Architecture review of agent scope and RBAC levels
