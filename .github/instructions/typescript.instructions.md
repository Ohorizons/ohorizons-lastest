---
applyTo: "**/*.ts"
description: "TypeScript coding standards for MCP server code and any TypeScript files in this repository."
---

# TypeScript Standards

## Module System

- Use ES modules (`import`/`export`), never CommonJS (`require`)
- Add `.js` extension to all relative imports — required for Node16 module resolution
- Export named exports, not default exports — better for tree-shaking and refactoring

### DO

```typescript
import { createServer } from './server-factory.js';
import { ToolDefinition } from './types.js';

export function registerTools(server: McpServer): void {
  // ...
}
```

### DON'T

```typescript
const { createServer } = require('./server-factory');  // CommonJS
import createServer from './server-factory';           // Default export
import { createServer } from './server-factory';       // Missing .js extension
```

## Type Safety

- Strict mode enabled — `"strict": true` in tsconfig.json
- No `any` types unless absolutely necessary — prefer `unknown` and narrow with type guards
- Use `interface` for object shapes, `type` for unions and intersections
- Use `readonly` for properties that should not be mutated
- Define return types explicitly on exported functions

### DO

```typescript
interface ToolResult {
  readonly content: string;
  readonly isError: boolean;
}

export async function executeTool(name: string, args: unknown): Promise<ToolResult> {
  // ...
}
```

### DON'T

```typescript
export async function executeTool(name: any, args: any) {  // any types, no return type
  return { content: result, isError: false };
}
```

## Async Patterns

- Use `async`/`await` over `.then()` chains
- Handle errors with `try/catch` at system boundaries only — let errors propagate internally
- Never use `async` on a function that doesn't `await` anything
- Use `Promise.all()` for concurrent operations, not sequential `await` in loops

### DO

```typescript
const [users, config] = await Promise.all([
  fetchUsers(),
  fetchConfig(),
]);
```

### DON'T

```typescript
const users = await fetchUsers();
const config = await fetchConfig();  // Sequential when they could be parallel
```

## Variables & Naming

- Prefer `const` over `let`; never use `var`
- Use template literals for string interpolation: `` `Hello ${name}` ``
- Name files with kebab-case: `my-module.ts`, `server-factory.ts`
- Name interfaces with PascalCase: `ToolDefinition`, `ServerConfig`
- Name functions and variables with camelCase: `registerTools`, `toolCount`
- Name constants with UPPER_SNAKE_CASE only for true constants: `MAX_RETRIES`, `DEFAULT_PORT`

## Error Handling

- `try/catch` at boundaries only (API endpoints, tool handlers) — let errors propagate internally
- Use custom error classes for domain-specific errors
- Never swallow errors silently — at minimum log them
- Prefer early returns over deeply nested conditionals

### DO

```typescript
export async function handleToolCall(name: string, args: unknown): Promise<ToolResult> {
  try {
    const result = await executeTool(name, args);
    return { content: result, isError: false };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return { content: message, isError: true };
  }
}
```

## Project Configuration

- Target: `ES2022` or later
- Module: `Node16` or `NodeNext`
- `"type": "module"` in package.json
- Enable `sourceMap` for debugging
- Use `paths` aliases only if necessary — prefer relative imports
