#!/usr/bin/env python3
"""Suggest validation after edits to Copilot customization files."""

from __future__ import annotations

import json
import sys
from typing import Any


CUSTOMIZATION_PATH_MARKERS = (
    ".github/agents/",
    ".github/prompts/",
    ".github/skills/",
    ".github/instructions/",
    ".github/ISSUE_TEMPLATE/",
    ".github/workflows/agent-router.yml",
    ".github/workflows/issue-ops.yml",
    ".github/workflows/validate-agents.yml",
)


def flatten_strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        values: list[str] = []
        for child in value.values():
            values.extend(flatten_strings(child))
        return values
    if isinstance(value, list):
        values = []
        for child in value:
            values.extend(flatten_strings(child))
        return values
    return []


def main() -> None:
    payload = json.load(sys.stdin)
    tool_input = payload.get("tool_input", {})
    strings = flatten_strings(tool_input)

    if any(marker in text for text in strings for marker in CUSTOMIZATION_PATH_MARKERS):
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PostToolUse",
                        "additionalContext": "Open Horizons customization files changed. Run `.github/skills/validation-scripts/scripts/validate-agents.py --strict` before finishing.",
                    }
                }
            )
        )
        return

    print(json.dumps({"continue": True}))


if __name__ == "__main__":
    main()
