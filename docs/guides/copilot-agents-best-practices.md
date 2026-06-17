# Copilot Agents Best Practices

This guide describes practical conventions for using the Open Horizons Copilot Chat agents.

## Agent Selection

- Use the most specific agent for the task.
- Use `@platform` for Backstage catalog, TechDocs, and Golden Path work.
- Use `@terraform` for infrastructure code and module validation.
- Use `@security` for security review and policy validation.
- Use `@deploy` for coordinated deployment workflows.

## Working Pattern

1. State the goal, environment, and relevant files.
2. Ask the agent to inspect the repository before changing files.
3. Run validation scripts after changes.
4. Keep generated changes scoped to the requested component.

## Safety

- Do not paste secrets into chat.
- Prefer Key Vault, Workload Identity, and approved environment variables for sensitive configuration.
- Review generated code and infrastructure before merging.

## References

- [GitHub Copilot documentation](https://docs.github.com/copilot)
- [GitHub Copilot Chat documentation](https://docs.github.com/copilot/using-github-copilot/using-github-copilot-chat-in-your-ide)
- [Backstage documentation](https://backstage.io/docs/)