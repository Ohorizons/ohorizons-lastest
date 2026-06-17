---
applyTo: ".github/ISSUE_TEMPLATE/**/*.yml,.github/ISSUE_TEMPLATE/**/*.yaml,**/.github/ISSUE_TEMPLATE/**/*.yml,**/.github/ISSUE_TEMPLATE/**/*.yaml"
description: "GitHub Issue Forms standards for Open Horizons agent routing, workflow labels, and safe metadata."
---

# Issue Forms Standards

## Routing Labels

- Use canonical `agent:<id>` labels that match `.github/agents/*.agent.md` names.
- Use `agent:deploy` for full platform deployment and infrastructure requests unless a more specific canonical agent owns the task.
- Use `workflow:<name>` only for workflows supported by `.github/workflows/agent-router.yml`.
- Include `env:dev`, `env:staging`, or `env:prod` when the requested operation depends on environment policy.

## Form Content

- Use clear required fields for subscription, environment, horizon, owner, and risk level when relevant.
- Do not request secrets, tokens, passwords, private keys, or credentials in issue forms.
- Prefer placeholders that show format, not real customer or internal values.
- Keep issue bodies machine-readable enough for IssueOps and Agent Router automation.

## Validation

- After changing labels or workflow names, run the Copilot primitive validator in strict mode.
