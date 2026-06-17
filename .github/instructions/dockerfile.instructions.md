---
applyTo: "**/Dockerfile"
description: "Dockerfile best practices for multi-stage builds, security, and optimization."
---

# Dockerfile Standards

## Multi-Stage Builds

- Always use multi-stage builds: `builder` stage for compilation, `runtime` stage for execution
- Copy only the build output from builder to runtime — never the source code
- Name stages explicitly: `FROM node:20-alpine AS builder`

### DO

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY src/ ./src/
COPY tsconfig.json ./
RUN npm run build

# Runtime stage
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder --chown=node:node /app/dist ./dist
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/package.json ./
USER node
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3100/health || exit 1
EXPOSE 3100
CMD ["node", "dist/index.js"]
```

### DON'T

```dockerfile
FROM node:latest           # Unpinned tag
COPY . .                   # Copies everything including .git, node_modules
RUN npm install            # Uses npm install instead of npm ci, installs devDeps
CMD npm start              # Shell form instead of exec form
# No USER, no HEALTHCHECK, no multi-stage
```

## Base Images

- Pin exact base image versions: `node:20-alpine`, not `node:latest`
- Prefer Alpine-based images for smaller size and fewer CVEs
- Use the same base image version in both stages for consistency

## Security

- Run as non-root user in production: `USER node` or create a custom user
- Never run `apt-get` or `apk add` without `--no-cache` in the runtime stage
- Use `COPY --chown=node:node` to set file permissions in one step
- Never store secrets in the image — use environment variables or mounted secrets
- Use `npm ci --ignore-scripts` in build to prevent supply chain attacks

## Layer Optimization

- Order layers from least to most frequently changing:
  1. Base image
  2. System dependencies
  3. `package.json` + `package-lock.json` (dependency layer)
  4. `npm ci` (cached if lockfile unchanged)
  5. Source code (changes most often)
- Combine related `RUN` commands with `&&` to reduce layer count
- Add `.dockerignore` to exclude: `node_modules`, `src/`, `.git`, `*.md`, test files

## Runtime Configuration

- Set `NODE_ENV=production` in the runtime stage via `ENV`
- Use exec form for `CMD`: `CMD ["node", "dist/index.js"]`, not `CMD node dist/index.js`
- Include `HEALTHCHECK` instruction with explicit interval, timeout, and retries
- Use `EXPOSE` to document which ports the container listens on
