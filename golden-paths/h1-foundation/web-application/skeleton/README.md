# ${{values.name}}

${{values.description}}

## Overview

This web application was created using the Open Horizons Platform - H1 Foundation template.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Framework | ${{values.framework}} |

## Getting Started

### Prerequisites

- Node.js 20+
- npm or pnpm
- Docker

### Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm run build

# Preview production build
npm run preview
```

### Docker

```bash
# Build
docker build -t ${{values.name}}:local .

# Run
docker run -p 3000:3000 ${{values.name}}:local
```

## Project Structure

```
src/
├── components/       # Reusable UI components
├── pages/           # Page components/routes
├── hooks/           # Custom React hooks
├── utils/           # Utility functions
├── styles/          # Global styles
└── types/           # TypeScript types
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| VITE_API_URL | Backend API URL | http://localhost:8080 |
| VITE_AUTH_ENABLED | Enable authentication | false |

## Deployment

This application is deployed via ArgoCD. Changes to the `main` branch automatically trigger deployment.

## Available Scripts

| Script | Description |
|--------|-------------|
| `dev` | Start development server |
| `build` | Build for production |
| `test` | Run tests |
| `lint` | Run ESLint |
| `preview` | Preview production build |

## Links

- [Open Horizons Documentation](https://github.com/${{values.repoUrl | parseRepoUrl | pick('owner') }}/agentic-devops-platform)
- [Component Library](https://design.example.com)
