#!/usr/bin/env python3
"""Validate the Copilot primitives shipped with this repository.

A primitive that is present but malformed is worse than an absent one: it looks
like governance while contributing nothing. This checks the properties that
decide whether Copilot actually loads each file.

Exit code 0 means every discovered primitive is loadable.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GITHUB = ROOT / ".github"

FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.DOTALL)


def frontmatter(path: Path) -> dict[str, str] | None:
    match = FRONTMATTER.match(path.read_text(encoding="utf-8"))
    if not match:
        return None
    fields: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" in line and not line.startswith((" ", "\t", "-")):
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip().strip("\"'")
    return fields


def main() -> int:
    findings: list[str] = []
    counts: dict[str, int] = {}

    def record(kind: str) -> None:
        counts[kind] = counts.get(kind, 0) + 1

    for path in sorted(GITHUB.glob("agents/*.agent.md")):
        record("agents")
        fields = frontmatter(path)
        if fields is None:
            findings.append(f"{path.relative_to(ROOT)}: missing YAML frontmatter")
        elif not fields.get("description"):
            findings.append(f"{path.relative_to(ROOT)}: frontmatter needs a description")

    for path in sorted(GITHUB.glob("skills/*/SKILL.md")):
        record("skills")
        fields = frontmatter(path)
        if fields is None:
            findings.append(f"{path.relative_to(ROOT)}: missing YAML frontmatter")
        elif not fields.get("description"):
            findings.append(f"{path.relative_to(ROOT)}: frontmatter needs a description")
        elif fields.get("name") and fields["name"] != path.parent.name:
            findings.append(
                f"{path.relative_to(ROOT)}: name {fields['name']!r} does not match "
                f"directory {path.parent.name!r}, so discovery is ambiguous"
            )

    for path in sorted(GITHUB.glob("instructions/*.instructions.md")):
        record("instructions")
        fields = frontmatter(path)
        if fields is None:
            findings.append(f"{path.relative_to(ROOT)}: missing YAML frontmatter")
        elif not fields.get("applyTo"):
            findings.append(
                f"{path.relative_to(ROOT)}: without applyTo the file is never applied"
            )

    for path in sorted(GITHUB.glob("prompts/*.prompt.md")):
        record("prompts")
        if frontmatter(path) is None:
            findings.append(f"{path.relative_to(ROOT)}: missing YAML frontmatter")

    import json

    for path in sorted(GITHUB.glob("hooks/*.json")):
        record("hooks")
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            findings.append(f"{path.relative_to(ROOT)}: invalid JSON: {error}")
            continue
        if not isinstance(document.get("hooks"), dict) or not document["hooks"]:
            findings.append(f"{path.relative_to(ROOT)}: declares no hook event")
            continue
        for event, entries in document["hooks"].items():
            for entry in entries or []:
                script = entry.get("bash")
                if script and not (ROOT / script).exists():
                    findings.append(
                        f"{path.relative_to(ROOT)}: {event} runs {script!r}, "
                        "which is not present in this repository"
                    )

    for required in (GITHUB / "copilot-instructions.md", ROOT / "AGENTS.md"):
        if required.is_file():
            record("guidance")
        else:
            findings.append(f"missing required primitive: {required.relative_to(ROOT)}")

    summary = ", ".join(f"{kind} {count}" for kind, count in sorted(counts.items()))
    print(f"copilot primitives: {summary or 'none discovered'}, findings {len(findings)}")

    if not counts:
        print("no primitive was discovered; the harness is not installed", file=sys.stderr)
        return 1
    if findings:
        print("", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
