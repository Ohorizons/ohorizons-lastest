"""
Base Agent — Semantic Kernel agentic loop with manual function calling for SSE streaming.
"""

from __future__ import annotations

import json
import logging
from typing import Any, AsyncGenerator

from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.chat_completion_client_base import ChatCompletionClientBase
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.contents import ChatHistory
from semantic_kernel.contents.chat_message_content import ChatMessageContent
from semantic_kernel.contents.function_call_content import FunctionCallContent
from semantic_kernel.contents.function_result_content import FunctionResultContent
from semantic_kernel.contents.text_content import TextContent
from semantic_kernel.contents.utils.author_role import AuthorRole

from . import AgentConfig

logger = logging.getLogger("agents.base")


class BaseAgent:
    """Semantic Kernel agent with manual tool-calling loop for SSE streaming."""

    def __init__(self, config: AgentConfig, kernel: Kernel):
        self.config = config
        self.kernel = kernel

    async def handle(
        self,
        message: str,
        conversation: list[dict],
        model: str,
    ) -> AsyncGenerator[dict, None]:
        """Process a message through the SK agentic loop. Yields SSE chunks."""
        yield {
            "type": "agent",
            "agent": self.config.name,
            "display_name": self.config.display_name,
        }

        chat_history = ChatHistory(system_message=self.config.system_prompt)
        for msg in conversation:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if isinstance(content, str):
                if role == "user":
                    chat_history.add_user_message(content)
                elif role == "assistant":
                    chat_history.add_assistant_message(content)

        chat_history.add_user_message(message)

        service = self.kernel.get_service(type=ChatCompletionClientBase)
        settings = self.kernel.get_prompt_execution_settings_from_service_id(
            service.service_id
        )
        settings.max_tokens = self.config.max_tokens
        settings.temperature = self.config.temperature
        settings.function_choice_behavior = FunctionChoiceBehavior.Auto(
            auto_invoke=False
        )

        try:
            max_iterations = 10
            for _ in range(max_iterations):
                results = await service.get_chat_message_contents(
                    chat_history=chat_history,
                    settings=settings,
                    kernel=self.kernel,
                )

                if not results:
                    break

                has_function_calls = False
                function_calls: list[FunctionCallContent] = []

                for result_msg in results:
                    for item in result_msg.items:
                        if isinstance(item, TextContent) and item.text:
                            yield {"type": "text", "content": item.text}
                        elif isinstance(item, FunctionCallContent):
                            has_function_calls = True
                            function_calls.append(item)
                            yield {
                                "type": "tool_use",
                                "tool_name": item.function_name,
                                "tool_input": (
                                    item.arguments if isinstance(item.arguments, dict) else {}
                                ),
                                "content": f"Calling {item.function_name}...",
                            }
                    chat_history.add_message(result_msg)

                if has_function_calls:
                    tool_result_items: list[FunctionResultContent] = []
                    for fc in function_calls:
                        try:
                            result_content = await fc.invoke(self.kernel)
                            result_str = str(result_content.result) if result_content else "{}"
                        except Exception as e:
                            logger.error("Tool %s failed: %s", fc.function_name, e)
                            result_str = json.dumps({"error": str(e)})
                            result_content = FunctionResultContent(
                                id=fc.id,
                                name=fc.name,
                                function_name=fc.function_name,
                                result=result_str,
                            )

                        yield {
                            "type": "tool_result",
                            "tool_name": fc.function_name,
                            "content": result_str[:500],
                        }
                        if result_content:
                            tool_result_items.append(result_content)

                    if tool_result_items:
                        chat_history.add_message(
                            ChatMessageContent(
                                role=AuthorRole.TOOL,
                                items=tool_result_items,  # type: ignore[arg-type]
                            )
                        )
                else:
                    break

            yield {"type": "done"}

        except Exception as e:
            logger.error("Agent %s error: %s", self.config.name, e, exc_info=True)
            yield {"type": "error", "content": f"Agent error: {e}"}
