# ${{values.name}}

${{values.description}}

## Overview

Multi-Agent AI System with orchestration, collaboration, and human-in-the-loop capabilities.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Framework | ${{values.framework}} |

## Features

- Multiple specialized AI agents
- Agent orchestration and coordination
- Collaborative problem solving
- Human-in-the-loop approval flows
- Tool sharing between agents
- Conversation persistence

## Architecture

![Multi-Agent System](../../../../docs/assets/gp-multi-agent.svg)

## Agents

| Agent | Role | Tools |
|-------|------|-------|
| Orchestrator | Coordinates workflow | All |
| Researcher | Information gathering | search, web |
| Analyst | Data analysis | sql, python |
| Writer | Content generation | docs, email |

## Running the System

```bash
# Install dependencies
pip install -r requirements.txt

# Run multi-agent system
python -m src.main --task "analyze quarterly report"

# Interactive mode
python -m src.main --mode interactive
```

## Configuration

Environment variables:

- `AZURE_OPENAI_ENDPOINT`: Azure OpenAI endpoint
- `ORCHESTRATION_MODEL`: Model for orchestrator
- `AGENT_MODEL`: Model for worker agents
- `MAX_ITERATIONS`: Maximum agent iterations

## Human-in-the-Loop

Configure approval requirements:

```yaml
approvals:
  - action: external_api_call
    required: true
  - action: send_email
    required: true
```

## Monitoring

- Agent interaction logs
- Task completion metrics
- Token usage per agent
- Error and retry rates

## Links

- [AutoGen](https://microsoft.github.io/autogen/)
- [Semantic Kernel](https://learn.microsoft.com/semantic-kernel/)
