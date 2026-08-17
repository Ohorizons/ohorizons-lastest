---
applyTo: "**/*.agent.md,**/*.prompt.md,**/*.instructions.md,**/SKILL.md"
description: "Use when creating or modifying Open Horizons Copilot agents, prompts, instruction files, and SKILL.md files."
---

# Agent Customization Standards — Agents, Prompts, Instructions, and Skills

This file activates when you edit Copilot customization primitives under `.github/` or any `SKILL.md`. It teaches the official frontmatter contract, the repo template shape, and validation expectations for Open Horizons agents, prompts, instruction files, and skills. It does **not** cover the implementation standards those primitives route to: use [GitHub Actions standards](github-actions.instructions.md), [Shell script standards](shell.instructions.md), [Terraform standards](terraform.instructions.md), [Kubernetes standards](kubernetes.instructions.md), [Dockerfile standards](dockerfile.instructions.md), [Docker Compose standards](docker-compose.instructions.md), [Python standards](python.instructions.md), [TypeScript standards](typescript.instructions.md), and [Issue form standards](issue-forms.instructions.md) for the underlying files.

> [!IMPORTANT]
> These files are loaded by VS Code, Copilot CLI, and the cloud agent. Keep schemas strict, examples English-only, and routing descriptions actionable.

## Agent Frontmatter

Agents require a `description` and may use only the verified keys below. `infer` is deprecated, `infer_tools` is invalid, and `vscode` is not a valid tool alias.

```markdown
---
description: "Use when orchestrating end-to-end Open Horizons deployment across Terraform, AKS, ArgoCD, and Backstage."
name: deploy
tools: ["read", "search", "execute", "edit", "agent", "web", "todo", "github/*"]
user-invocable: true
handoffs: ["terraform", "security", "sre"]
---
```

```markdown
# Wrong: tools: ["vscode", "infer_tools"]
tools: ["read", "search", "execute", "edit"]
```

## Prompt Frontmatter

Prompts route one repeatable request. Use `${input:name}` variables; `{{var}}` is literal text and never interpolates.

```markdown
---
description: "Use when validating a dev deployment and returning a concise operator report."
mode: agent
tools: ["read", "search", "execute"]
argument-hint: "environment"
name: validate-deployment
---

Validate `${input:environment}` with the repository validation scripts.
```

```markdown
# Wrong: Validate {{environment}}
Validate `${input:environment}` with `scripts/validate-deployment.sh`.
```

## Instruction Frontmatter

Instruction files require `applyTo` and may include `excludeAgent`. Open Horizons keeps `description` as a house routing convention; make it start with `Use when ...`.

```markdown
---
applyTo: "**/*.sh"
description: "Use when editing Open Horizons shell automation, validation, and deployment scripts."
---
```

```markdown
# Wrong: applyTo:
# Wrong:   - "**/*.sh"
applyTo: "**/*.sh"
```

## Skill Frontmatter

`SKILL.md` files require `name` and `description`. The skill name is lowercase-hyphen, 1-64 characters, and must match the containing directory. Description length is 10-1024 characters. Optional keys are `license` and `allowed-tools`; `argument-hint` is not valid in skills.

```markdown
---
name: kubectl-cli
description: Kubernetes CLI operations for AKS cluster management and manifest verification.
allowed-tools: ["execute", "read"]
---
```

```markdown
# Wrong: argument-hint: namespace
allowed-tools: ["execute", "read"]
```

> [!WARNING]
> Do not place credentials, tokens, tenant-specific secrets, or private endpoints in customization primitives. Use placeholders and point operators to Key Vault, environment files, or GitHub secrets.

## Reference Templates

Use this shape for prompt files:

```markdown
---
description: "Use when <task and routing signal>."
mode: agent
tools: ["read", "search", "execute"]
argument-hint: "<input>"
name: <prompt-name>
---

# <Prompt Title>

Run the task for `${input:<input>}` and return evidence.
```

Use this shape for instruction files:

```markdown
---
applyTo: "<comma-separated globs>"
description: "Use when <file family and task>."
---

# <Domain> Conventions — <Scope>

Opening scope paragraph with cross-links.

## Conventions
| Rule | Rationale |
|---|---|
| <Rule> | <Why> |

## Do / Do Not
| Do | Do not |
|---|---|
| <Preferred> | <Avoided> |

## Checklist Before Opening a PR
- [ ] <Verifiable item>
```

Use this shape for skills:

```markdown
---
name: <directory-name>
description: Use this skill when <specific capability and boundaries>.
allowed-tools: ["read", "search", "execute"]
---

# <Skill Name>

## When to use

## Procedure

## Validation
```

## Conventions

| Rule | Rationale |
|---|---|
| Start every `description` with `Use when ...` | Agents route better from intent signals than labels. |
| Keep `applyTo` as one comma-separated string | The verified instruction schema expects a string, not a YAML array. |
| Use only verified agent keys: `description`, `name`, `tools`, `model`, `target`, `user-invocable`, `disable-model-invocation`, `handoffs`, `agents`, `mcp-servers`, `metadata`, `argument-hint` | Unknown keys are ignored or rejected across VS Code and cloud surfaces. |
| Use only valid tool aliases: `execute`, `read`, `edit`, `search`, `agent`, `web`, `todo`, plus MCP `server/*` or `server/tool` | Invalid aliases silently remove capabilities or fail validation. |
| Keep reusable procedures in skills and one-shot workflows in prompts | This prevents agent files from becoming duplicated runbooks. |
| Run `.github/skills/validation-scripts/scripts/validate-agents.py --strict` after primitive changes | The validator enforces schemas, globs, and repository-specific routing rules. |

## Do / Do Not

| Do | Do not |
|---|---|
| Link to sibling instruction files when a primitive delegates implementation details | Duplicate Terraform, Kubernetes, Python, or TypeScript standards in agent files. |
| Use `${input:name}` in prompts | Use `{{name}}` and expect interpolation. |
| Match skill `name` to its directory | Rename skills only in frontmatter. |
| Keep examples realistic for Open Horizons agents and skills | Use unrelated sample applications or placeholder-only content. |

## Checklist Before Opening a PR

- [ ] Frontmatter uses only verified keys for its primitive type.
- [ ] `description` starts with `Use when ...` and is specific enough for routing.
- [ ] Skill names match directory names and descriptions are 10-1024 characters.
- [ ] Prompt variables use `${input:...}` syntax.
- [ ] All cross-links resolve to existing repository files.
- [ ] Strict validator passes.
