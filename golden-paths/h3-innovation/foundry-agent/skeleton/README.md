# ${{values.name}}

${{values.description}}

## Overview

Autonomous AI Agent powered by Azure AI Foundry with tools, RAG, and orchestration.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Model | ${{values.model}} |

## Features

- Autonomous task execution
- Tool integration (Azure, APIs, databases)
- RAG with Azure AI Search
- Safety controls and content filtering
- Human-in-the-loop capabilities
- Conversation memory

## Architecture

![AI Foundry Agent](../../../../docs/assets/gp-foundry-agent.svg)

## Tools

| Tool | Description |
|------|-------------|
| `search_documents` | Search knowledge base |
| `query_database` | Query business data |
| `send_notification` | Send alerts/notifications |
| `create_ticket` | Create support tickets |

## Running the Agent

```bash
# Install dependencies
pip install -r requirements.txt

# Run agent locally
python -m src.agent --mode interactive

# Run as API server
python -m src.main
```

## Configuration

Environment variables:

- `AZURE_OPENAI_ENDPOINT`: Azure OpenAI endpoint
- `AZURE_OPENAI_DEPLOYMENT`: Model deployment name
- `AZURE_AI_SEARCH_ENDPOINT`: AI Search endpoint
- `CONTENT_SAFETY_ENDPOINT`: Content Safety endpoint

## Safety Controls

- Content filtering enabled
- Prompt injection detection
- Output validation
- Rate limiting
- Audit logging

## Monitoring

- Agent task completion rate
- Token usage and cost
- Error rates
- Safety filter triggers

## Links

- [Azure AI Foundry](https://docs.microsoft.com/azure/ai-services/)
- [Azure AI Agent Service](https://learn.microsoft.com/azure/ai-services/agents/)
