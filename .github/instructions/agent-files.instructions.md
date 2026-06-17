---
applyTo: "**/*.agent.md,**/*.prompt.md,**/*.instructions.md,**/SKILL.md"
description: "Standards for writing agent customization files — ensures consistent frontmatter, descriptions, and structure across all AI primitives."
---

# Agent Customization File Standards

## Frontmatter

- Always include YAML frontmatter between `---` markers
- `description` is mandatory — it drives agent auto-discovery
- Use the "USE FOR / DO NOT USE FOR" pattern in descriptions for agents and skills
- Quote descriptions containing colons: `description: "Use when: doing X"`
- `name` must match folder name (for skills) or be descriptive (for agents)
- Never use tabs in YAML — spaces only
- Keep `applyTo` patterns specific — never use `**` alone (burns context on every file)

### DO

```yaml
---
name: "docx-creator"
description: "Create Word documents. USE FOR: create docx, write report. DO NOT USE FOR: presentations."
---
```

### DON'T

```yaml
---
name: docx creator      # Spaces in name — should be kebab-case
description: Creates documents   # No trigger phrases, no USE FOR/DO NOT USE FOR
applyTo: "**"            # Too broad — matches all files, burns context
---
```

## Description Writing

- Include trigger phrases the user might say
- Be specific — generic descriptions don't get matched
- Include verbs ("create", "review", "debug") and domain nouns ("Dockerfile", "agent", "diagram")
- Keep under 300 characters when possible — long descriptions dilute matching

### Description formula

```
[What it does]. USE FOR: [trigger 1], [trigger 2], [trigger 3]. DO NOT USE FOR: [anti-trigger].
```

## Content Structure

- Start with a `# Title` immediately after frontmatter
- Use numbered steps (`## Step 1`, `## Step 2`) for sequential workflows (agents/skills)
- Use bullet lists for constraints and rules (instructions)
- Use tables for reference data and comparisons
- Keep examples concrete and copy-pasteable — no pseudo-code
- End with `## Operating Rules` (agents) or a checklist (skills)

### File Type Patterns

| Type | Structure | Ends with |
|------|-----------|----------|
| `.agent.md` | Steps workflow | Operating Rules |
| `SKILL.md` | Domain knowledge | Quality Checklist |
| `.prompt.md` | Input → Instructions → Output | Output format |
| `.instructions.md` | Bullet rules with DO/DON'T | — |

## Language

- All content in English
- Use `{{variable}}` for template dynamic values
- Variable names in snake_case: `{{client_name}}`, `{{author_name}}`
- Never leave placeholder text — no "TODO", "TBD", or "[fill in]"
