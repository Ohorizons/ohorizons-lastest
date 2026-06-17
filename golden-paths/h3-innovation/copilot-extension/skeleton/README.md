# ${{values.name}}

${{values.description}}

## Overview

GitHub Copilot Extension for enhanced AI-powered developer assistance.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Display Name | ${{values.displayName}} |

## Features

- Custom agent implementation
- Skillset configuration
- Azure integration for data retrieval
- OAuth authentication
- GitHub Marketplace deployment
- Context-aware responses

## Project Structure

```
src/
├── agent/
│   ├── handler.py        # Agent request handler
│   ├── skills.py         # Skill implementations
│   └── context.py        # Context management
├── auth/
│   └── oauth.py          # OAuth flow
└── api/
    └── endpoints.py      # API endpoints
```

## Skills

| Skill | Description |
|-------|-------------|
| `search-docs` | Search internal documentation |
| `query-api` | Query internal APIs |
| `analyze-code` | Code analysis and suggestions |

## Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Start development server
python -m src.main

# Test with ngrok for GitHub integration
ngrok http 8080
```

## Deployment

```bash
# Build container
docker build -t ${{values.name}} .

# Deploy to Azure Container Apps
az containerapp up --name ${{values.name}}
```

## Configuration

Environment variables:

- `GITHUB_CLIENT_ID`: GitHub OAuth App client ID
- `GITHUB_CLIENT_SECRET`: GitHub OAuth App secret
- `AZURE_OPENAI_ENDPOINT`: Azure OpenAI endpoint
- `EXTENSION_SECRET`: Extension verification secret

## GitHub Marketplace

1. Create GitHub App
2. Configure webhook URL
3. Set permissions and events
4. Submit for Marketplace review

## Links

- [GitHub Copilot Extensions](https://docs.github.com/copilot/building-copilot-extensions)
- [GitHub Apps](https://docs.github.com/apps)
