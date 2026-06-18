"""
Base Agent — Abstract base class for all Open Horizons agents.

Each agent has a name, system prompt, tools, and guardrails.
The router selects the right agent per message, and the agent
drives an agentic loop with Azure OpenAI (tool calls until done).
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from typing import Any, AsyncGenerator

from openai import AzureOpenAI, APIError

try:
    from middleware.hooks import tool_hooks
except ImportError:  # pragma: no cover - fallback if middleware not on path
    tool_hooks = None

logger = logging.getLogger("agents")


@dataclass
class AgentConfig:
    """Configuration for a specialized agent."""
    name: str
    display_name: str
    description: str
    system_prompt: str
    tools: list[dict] = field(default_factory=list)
    keywords: list[str] = field(default_factory=list)
    temperature: float = 0.3
    max_tokens: int = 4096
    guardrails_green: list[str] = field(default_factory=list)
    guardrails_yellow: list[str] = field(default_factory=list)
    guardrails_red: list[str] = field(default_factory=list)
    handoff_targets: list[str] = field(default_factory=list)


def _anthropic_tool_to_openai(tool: dict) -> dict:
    """Convert Anthropic tool format to OpenAI function calling format."""
    return {
        "type": "function",
        "function": {
            "name": tool["name"],
            "description": tool.get("description", ""),
            "parameters": tool.get("input_schema", {"type": "object", "properties": {}}),
        },
    }


class BaseAgent:
    """Base class that all Open Horizons agents inherit from."""

    def __init__(self, config: AgentConfig, tool_executor=None):
        self.config = config
        self.tool_executor = tool_executor
        self.name = config.name
        self.display_name = config.display_name

    async def handle(
        self,
        message: str,
        conversation: list[dict],
        client: AzureOpenAI,
        model: str,
    ) -> AsyncGenerator[dict, None]:
        """Process a message through the agentic loop.

        Yields SSE-compatible chunks:
          {"type": "agent", "agent": "pipeline", "display_name": "Pipeline"}
          {"type": "text", "content": "..."}
          {"type": "tool_use", "tool_name": "...", "tool_input": {...}}
          {"type": "tool_result", "tool_name": "...", "content": "..."}
          {"type": "done"}
        """
        # Announce which agent is handling
        yield {
            "type": "agent",
            "agent": self.config.name,
            "display_name": self.config.display_name,
        }

        messages = conversation.copy()
        # Prepend system message
        if not messages or messages[0].get("role") != "system":
            messages.insert(0, {"role": "system", "content": self.config.system_prompt})
        messages.append({"role": "user", "content": message})

        # Convert tools to OpenAI format
        openai_tools = [_anthropic_tool_to_openai(t) for t in self.config.tools] if self.config.tools else None

        try:
            while True:
                create_kwargs: dict[str, Any] = {
                    "model": model,
                    "max_completion_tokens": self.config.max_tokens,
                    "messages": messages,
                    "temperature": self.config.temperature,
                }
                if openai_tools:
                    create_kwargs["tools"] = openai_tools

                response = client.chat.completions.create(**create_kwargs)
                choice = response.choices[0]
                assistant_message = choice.message

                # Emit text content
                if assistant_message.content:
                    yield {"type": "text", "content": assistant_message.content}

                # Check for tool calls
                if assistant_message.tool_calls:
                    # Add assistant message with tool calls to history
                    messages.append(assistant_message.model_dump())

                    for tool_call in assistant_message.tool_calls:
                        func = tool_call.function
                        tool_input = json.loads(func.arguments) if func.arguments else {}

                        yield {
                            "type": "tool_use",
                            "tool_name": func.name,
                            "tool_input": tool_input,
                            "content": f"Calling {func.name}...",
                        }

                        result = await self._execute_tool(func.name, tool_input)

                        messages.append({
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "content": result,
                        })

                        yield {
                            "type": "tool_result",
                            "tool_name": func.name,
                            "content": result[:500],
                        }
                else:
                    # No tool calls — add assistant response and break
                    messages.append({"role": "assistant", "content": assistant_message.content or ""})
                    break

            yield {"type": "done", "messages": messages}

        except APIError as e:
            logger.error("Azure OpenAI API error in %s: %s", self.name, e)
            yield {"type": "error", "content": f"API error: {e}"}
        except Exception as e:
            logger.error("Error in %s: %s", self.name, e, exc_info=True)
            yield {"type": "error", "content": "Internal agent error"}

    async def _execute_tool(self, name: str, input_data: dict) -> str:
        """Execute a tool via the injected executor, wrapped in governance hooks.

        Every tool call from every agent passes through here, so the pre/post
        hooks give the whole fleet uniform validation: mutating actions (deploy,
        integration config, infrastructure) are audited, dangerous arguments are
        blocked, and secrets are redacted from results before they reach the model.
        """
        input_data = input_data or {}

        # Pre-tool-use: validate and authorize before execution.
        if tool_hooks is not None:
            pre = tool_hooks.pre_tool_use(self.name, name, input_data)
            if not pre.allowed:
                return json.dumps({
                    "error": "blocked_by_hook",
                    "tool": name,
                    "reason": pre.reason,
                })
            input_data = pre.args

        if not self.tool_executor:
            return json.dumps({"error": f"No tool executor configured for {name}"})

        raw = await self.tool_executor(name, input_data)

        # Post-tool-use: sanitize the result before it returns to the model.
        if tool_hooks is not None:
            return tool_hooks.post_tool_use(self.name, name, raw).result
        return raw
