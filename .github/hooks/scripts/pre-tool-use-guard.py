#!/usr/bin/env python3
"""Block destructive agent tool commands before execution."""

from __future__ import annotations

import json
import re
import sys
from typing import Any


BLOCKED_PATTERNS = [
    re.compile(r"\brm\s+-rf\s+(/|~|\$HOME)"),
    re.compile(r"\bgit\s+reset\s+--hard\b"),
    re.compile(r"\bgit\s+checkout\s+--\b"),
    re.compile(r"\bterraform\s+destroy\b"),
    re.compile(r"\bkubectl\s+delete\s+(namespace|ns)\b"),
    re.compile(r"\baz\s+group\s+delete\b"),
]


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


def deny(reason: str) -> None:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )


def main() -> None:
    payload = json.load(sys.stdin)
    tool_input = payload.get("tool_input", {})
    strings = flatten_strings(tool_input)

    for text in strings:
        for pattern in BLOCKED_PATTERNS:
            if pattern.search(text):
                deny(f"Blocked destructive command by Open Horizons policy: {pattern.pattern}")
                return

    print(json.dumps({"continue": True}))


if __name__ == "__main__":
    main()
