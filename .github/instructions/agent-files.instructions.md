---
applyTo: "**/*.agent.md,**/*.prompt.md,**/*.instructions.md,**/SKILL.md"
description: "Standards for Open Horizons Copilot customization primitives: agents, prompts, skills, and instruction files."
---

# Agent Customization File Standards

## Frontmatter

- Always include YAML frontmatter between `---` markers.
- Use `description` to state when the primitive should be used.
- Use `user-invocable`, not `user-invokable` or `infer`, in custom agents.
- Skill `name` values must match the parent folder and use lowercase letters, numbers, and hyphens only.
- Prompt `agent` values must reference an existing custom agent or a built-in agent such as `ask`, `agent`, or `plan`.
- Do not leave placeholder fields such as `todo`, `TODO`, `TBD`, or `[fill in]`.

## Structure

- Keep agents lean: identity, workflow, boundaries, operating rules, and handoffs.
- Put reusable domain procedures, command references, templates, and scripts in skills.
- Keep prompts focused on one repeatable task and use `${input:name}` variables for user-provided values.
- Keep instruction files scoped with specific `applyTo` patterns; avoid `**` or broad all-file globs.

## Operating Rules

- Prefer the existing Open Horizons agent, skill, and prompt naming conventions.
- Update validation when introducing a new primitive type or frontmatter field.
- Run `.github/skills/validation-scripts/scripts/validate-agents.py --strict` after changes.
