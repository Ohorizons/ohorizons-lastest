# Reference Examples

These files are illustrative examples of the template contract. They are not installed Open Horizons primitives, are not platform guidance, and must not be copied verbatim into `.github/agents/`, `.github/skills/`, `.github/instructions/`, or `.github/prompts/` without being rewritten for Open Horizons.

> [!IMPORTANT]
> The validator ignores `.github/docs/`. A sibling change is hardening that exclusion so these samples are never mistaken for real primitives.

## What the examples demonstrate

| Example | Template contract demonstrated |
| --- | --- |
| [archaeologist.agent.md](archaeologist.agent.md) | Agent mission, scope, operating principles, prompts, and anti-patterns |
| [requirements-engineer.agent.md](requirements-engineer.agent.md) | Agent traceability, persona boundaries, and definition of done |
| [software-architect.agent.md](software-architect.agent.md) | Agent architectural judgment, handoff boundaries, and evidence rules |
| [frontend.instructions.md](frontend.instructions.md) | Passive frontend conventions for matching files |
| [modular-monolith.instructions.md](modular-monolith.instructions.md) | Passive architecture conventions and checklist structure |
| [terraform.instructions.md](terraform.instructions.md) | Passive Terraform hygiene conventions |
| [java-springboot.prompt.md](java-springboot.prompt.md) | VS Code prompt contract for a focused implementation workflow |
| [persona-enterprise-architect-architecture-review.prompt.md](persona-enterprise-architect-architecture-review.prompt.md) | VS Code prompt contract for a read-only review workflow |
| [postgresql-optimization.prompt.md](postgresql-optimization.prompt.md) | VS Code prompt contract with measurable validation evidence |
| [stage-archaeologist-archaeology-kickoff.prompt.md](stage-archaeologist-archaeology-kickoff.prompt.md) | VS Code prompt contract with file-output boundaries |
| [ears-validate/SKILL.md](ears-validate/SKILL.md) | Skill criteria and output template |
| [iac-review/SKILL.md](iac-review/SKILL.md) | Skill review checklist and quality gate |
| [postgresql-code-review/SKILL.md](postgresql-code-review/SKILL.md) | Skill review areas, examples, output template, and quality gate |

## Rewrite before use

These examples come from legacy archaeology, Java/Spring Boot, and PostgreSQL domains. Before promoting any example into an installed primitive, replace the domain, paths, commands, and linked references with Open Horizons-specific content and run:

```sh
python3 .github/skills/validation-scripts/scripts/validate-agents.py --strict
```
