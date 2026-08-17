# GitHub Copilot Instructions for Open Horizons

Start with the shared, tool-agnostic repository instructions in @../AGENTS.md

Do not duplicate project architecture, commands, layout, security, naming, or language standards here.

## Copilot Instruction Loading

- This file is always loaded by VS Code Copilot Chat, Copilot cloud agent, and Copilot CLI.
- `AGENTS.md` is also loaded by Copilot CLI and cloud agent. Nested `AGENTS.md` files are supported; the nearest applicable file wins or combines depending on the tool.
- Both files support `@filename` relative file references. Use references instead of copying shared guidance.
- `instructions/*.instructions.md` files are applyTo-scoped and should hold file-type or tool-specific standards.
- Instruction files and `GEMINI.md` do not support the same `@filename` file-reference behavior.

## Copilot Primitives

Deploy-managed Copilot chat agents live in @agents/:

- `@deploy`
- `@terraform`
- `@security`
- `@sre`
- `@backstage-expert`
- `@azure-portal-deploy`
- `@github-integration`
- `@ado-integration`
- `@hybrid-scenarios`

Prompt shortcuts live in @prompts/:

- `/deploy-platform`
- `/terraform`
- `/azure-infra`
- `/backstage`
- `/security-review`
- `/ado-setup`
- `/hybrid-setup`
- `/troubleshoot-incident`
- `/create-mcp-server`

The full skill catalog lives in @skills/README.md

Use skills progressively so their detailed bodies are loaded only when relevant.

## Scoped Standards

Do not inline language or tool standards in this always-loaded file. Use these scoped files instead:

- Terraform: @instructions/terraform.instructions.md
- Kubernetes: @instructions/kubernetes.instructions.md
- Python: @instructions/python.instructions.md
- Shell: @instructions/shell.instructions.md
- TypeScript: @instructions/typescript.instructions.md
- GitHub Actions: @instructions/github-actions.instructions.md
- Dockerfile: @instructions/dockerfile.instructions.md
- Docker Compose: @instructions/docker-compose.instructions.md
- Issue forms: @instructions/issue-forms.instructions.md
- Agents, prompts, skills, and instruction files: @instructions/agent-files.instructions.md

## Agent File Guidance

When generating Copilot agents, prompts, skills, or instructions:

- Follow @instructions/agent-files.instructions.md
- Include the required YAML frontmatter for that primitive.
- Define clear ALWAYS / ASK FIRST / NEVER boundaries for agents.
- Reference skills instead of copying skill content.
- Use handoffs only when workflow orchestration needs them.

## Model Routing

`model-routing.yaml` is a repository-internal convention and documentation aid. Copilot does not read or enforce it. For Copilot agents, use per-agent `model:` frontmatter in `agents/*.agent.md` when model pinning is required and supported by the current Copilot agent format.
