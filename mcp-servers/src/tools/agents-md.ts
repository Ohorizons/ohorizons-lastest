import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { fetchRaw } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "agentsmd";
const REPO = "agents.md";

export function registerAgentsMdTools(server: McpServer): void {
  server.tool(
    "agentsmd_get_format_spec",
    "Get the AGENTS.md format specification — the open standard for guiding coding agents",
    {},
    async () => {
      const agentsmd = await fetchRaw(OWNER, REPO, "AGENTS.md");
      return textResult(agentsmd);
    }
  );

  server.tool(
    "agentsmd_get_readme",
    "Get the agents.md project README with explanation and examples",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      return textResult(readme);
    }
  );

  server.tool(
    "agentsmd_get_section_templates",
    "Get recommended section templates for writing AGENTS.md files",
    {},
    async () => {
      const template = `# AGENTS.md Section Templates

## Recommended Sections

### Project Overview
Brief description of the project, its purpose, and key architecture decisions.

### Setup Commands
\`\`\`bash
# Install dependencies
<package-manager> install

# Start development server
<package-manager> dev

# Run tests
<package-manager> test
\`\`\`

### Code Style
- Language and framework conventions
- Formatting rules (tabs vs spaces, quotes, semicolons)
- Naming conventions

### Testing Instructions
- How to run the test suite
- How to run individual tests
- What to do when tests fail
- Always add or update tests for changed code

### PR Instructions
- Title format convention
- Required checks before committing
- Review guidelines

### Security Considerations
- Authentication patterns
- Data handling rules
- Secrets management

## Notes
- Place AGENTS.md at the repository root
- For monorepos, use nested AGENTS.md files per package
- The closest AGENTS.md to the edited file takes precedence
- Keep instructions actionable and specific`;

      return textResult(template);
    }
  );
}
