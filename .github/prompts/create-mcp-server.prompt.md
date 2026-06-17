---
description: "Scaffold a complete MCP (Model Context Protocol) server project with tools, resources, and configuration. Supports TypeScript, Python, and C#. USE FOR: create MCP server, scaffold MCP, new MCP project, build MCP tools, generate MCP server, MCP server TypeScript, MCP server Python, MCP server C#, create model context protocol server."
---

# Create MCP Server

Scaffold a complete, production-ready Model Context Protocol (MCP) server project.

## Input

**Server name:** {{server_name}}
**Language:** {{language}} (TypeScript, Python, or C#)
**Transport:** {{transport}} (stdio or HTTP — default: stdio)
**Tools to create:** {{tools_description}} (describe each tool's purpose)

## Instructions

1. **Load the matching skill** based on `{{language}}`:
   - TypeScript → read `typescript-mcp-server-generator` skill
   - Python → read `python-mcp-server-generator` skill
   - C# → read `csharp-mcp-server-generator` skill

2. **Scaffold the project** following the skill's structure:
   - Project config (package.json / pyproject.toml / .csproj)
   - Server entrypoint with transport setup
   - One file per tool with schema validation
   - README with setup and usage instructions
   - .gitignore appropriate for the language

3. **Implement all requested tools** from `{{tools_description}}`:
   - Each tool gets a descriptive name, clear description, and input schema
   - Use zod (TS), Pydantic (Python), or DataAnnotations (C#) for validation
   - Include error handling and structured responses
   - Return both content and structured output where supported

4. **Add client configuration** snippets in the README:
   - VS Code (`.vscode/settings.json` MCP entry)

## Rules

- Follow the loaded skill's patterns exactly — do not deviate
- Use the latest MCP SDK version for the chosen language
- Every tool must have a clear, descriptive name and description (3-4 sentences)
- Input schemas must validate all parameters — no untyped inputs
- Include a health check or list-tools test command
- Server name in kebab-case: `my-mcp-server`

## Output

A complete project directory with all files ready to run. After scaffolding, show:

1. **Project tree** — all created files
2. **Quick start** — commands to install, build, and run
3. **Test command** — how to verify the server works
4. **Registration** — config snippet for at least one AI client
