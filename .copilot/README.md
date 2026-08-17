# `.copilot/` is intentionally not used

GitHub Copilot CLI and the Copilot cloud agent do not read repository-root
`.copilot/` configuration. Keep shared project configuration under `.github/`
instead:

- `.github/mcp.json` for project MCP servers
- `.github/hooks/*.json` for lifecycle hooks
- `.github/copilot/settings.json` for committed repo settings
- `.github/copilot/settings.local.json` for ignored personal overrides

For `.github/mcp.json`, developers may set these environment variables as
needed: `GITHUB_TOKEN`, `GH_TOKEN`, `AZURE_SUBSCRIPTION_ID`,
`ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, and `TF_VAR_environment`.
