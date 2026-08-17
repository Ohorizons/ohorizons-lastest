#!/usr/bin/env python3
"""Validate Open Horizons Copilot customization primitives."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover - CI installs PyYAML; local fallback is limited.
    yaml = None


REPO_ROOT = Path(__file__).resolve().parents[4]
GITHUB_DIR = REPO_ROOT / ".github"
AGENTS_DIR = GITHUB_DIR / "agents"
PROMPTS_DIR = GITHUB_DIR / "prompts"
SKILLS_DIR = GITHUB_DIR / "skills"
INSTRUCTIONS_DIR = GITHUB_DIR / "instructions"
ISSUE_TEMPLATE_DIR = GITHUB_DIR / "ISSUE_TEMPLATE"

VALID_AGENT_FIELDS = {
    "description",
    "name",
    "argument-hint",
    "tools",
    "model",
    "target",
    "user-invocable",
    "disable-model-invocation",
    "handoffs",
    "agents",
    "mcp-servers",
    "metadata",
}
VALID_PROMPT_FIELDS = {"description", "mode", "agent", "model", "tools", "argument-hint"}
VALID_SKILL_FIELDS = {
    "name",
    "description",
    "license",
    "allowed-tools",
}
VALID_INSTRUCTION_FIELDS = {"name", "description", "applyTo", "excludeAgent"}
VALID_SKILL_NAME = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
AGENT_LABEL = re.compile(r"agent:([a-zA-Z0-9_.-]+)")
PROMPT_TEMPLATE_VAR = re.compile(r"\{\{[^}]+\}\}")
SKILL_NAME_TOKEN = re.compile(r"\b[a-z0-9]+(?:-[a-z0-9]+)+\b")
SKILL_PATH = re.compile(r"\.\./skills/([a-z0-9]+(?:-[a-z0-9]+)*)/SKILL\.md")
PORTABLE_TOOL_ALIASES = {"execute", "read", "edit", "search", "agent", "web", "todo"}
MCP_TOOL = re.compile(r"^[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*/(?:[A-Za-z0-9_.-]+|\*)$")
TOOLS_BLOAT_THRESHOLD = 25
MAX_AGENT_BODY_CHARS = 30_000


class ValidationReport:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, path: Path, message: str) -> None:
        self.errors.append(f"{display_path(path)}: {message}")

    def warn(self, path: Path, message: str) -> None:
        self.warnings.append(f"{display_path(path)}: {message}")

    def print(self) -> None:
        if self.errors:
            print("\nErrors")
            for error in self.errors:
                print(f"  - {error}")
        if self.warnings:
            print("\nWarnings")
            for warning in self.warnings:
                print(f"  - {warning}")


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def parse_frontmatter_fallback(frontmatter: str) -> dict[str, Any]:
    metadata: dict[str, Any] = {}
    for line in frontmatter.splitlines():
        if not line.strip() or line.lstrip().startswith("#") or line.startswith(" "):
            continue
        key, sep, value = line.partition(":")
        if sep:
            metadata[key.strip()] = value.strip().strip("\"'")
    return metadata


def split_frontmatter(path: Path, report: ValidationReport) -> tuple[dict[str, Any], str] | None:
    content = path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        report.error(path, "missing YAML frontmatter")
        return None

    parts = content.split("---", 2)
    if len(parts) < 3:
        report.error(path, "unterminated YAML frontmatter")
        return None

    try:
        if yaml is None:
            metadata = parse_frontmatter_fallback(parts[1])
        else:
            loaded = yaml.safe_load(parts[1]) or {}
            if not isinstance(loaded, dict):
                report.error(path, "frontmatter must be a YAML mapping")
                return None
            metadata = loaded
    except Exception as exc:  # noqa: BLE001 - include parser detail in validation output.
        report.error(path, f"invalid YAML frontmatter: {exc}")
        return None

    return metadata, parts[2].strip()


def require_string(path: Path, metadata: dict[str, Any], key: str, report: ValidationReport) -> None:
    value = metadata.get(key)
    if not isinstance(value, str) or not value.strip():
        report.error(path, f"missing or empty `{key}`")


def error_unknown_agent_fields(
    path: Path,
    metadata: dict[str, Any],
    report: ValidationReport,
) -> None:
    for field in sorted(set(metadata) - VALID_AGENT_FIELDS):
        if field == "infer":
            report.warn(path, "deprecated frontmatter field `infer`; remove it")
        elif field == "infer_tools":
            report.error(path, "invalid frontmatter field `infer_tools`; use `tools`")
        elif field == "user-invokable":
            report.error(
                path,
                "unsupported frontmatter field `user-invokable`; use `user-invocable`",
            )
        else:
            report.error(path, f"unknown frontmatter field `{field}`")


def warn_unknown_fields(
    path: Path,
    metadata: dict[str, Any],
    allowed_fields: set[str],
    report: ValidationReport,
) -> None:
    for field in sorted(set(metadata) - allowed_fields):
        if field in {"infer", "user-invokable", "mode"}:
            replacement = "user-invocable" if field == "user-invokable" else "a supported field"
            report.error(path, f"unsupported frontmatter field `{field}`; use `{replacement}`")
        else:
            report.warn(path, f"unknown frontmatter field `{field}`")


def git_tracked_files(report: ValidationReport) -> list[str]:
    try:
        result = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "ls-files"],
            check=True,
            capture_output=True,
            encoding="utf-8",
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        report.warn(REPO_ROOT, f"could not list tracked files for `applyTo` validation: {exc}")
        return []
    return [line for line in result.stdout.splitlines() if line]


def matches_apply_to(pattern: str, tracked_file: str) -> bool:
    """Match Copilot-style applyTo globs without letting `*` cross directories."""
    return PurePosixPath(tracked_file).match(pattern)


def collect_agent_names(report: ValidationReport) -> set[str]:
    agent_names = {"ask", "agent", "plan"}
    for path in sorted(AGENTS_DIR.glob("*.agent.md")):
        parsed = split_frontmatter(path, report)
        if not parsed:
            continue
        metadata, _ = parsed
        name = metadata.get("name")
        if isinstance(name, str) and name.strip():
            agent_names.add(name.strip())
        agent_names.add(path.name.removesuffix(".agent.md"))
    return agent_names


def collect_skill_names() -> set[str]:
    return {path.parent.name for path in SKILLS_DIR.glob("*/SKILL.md")}


def validate_agents(agent_names: set[str], skill_names: set[str], report: ValidationReport) -> None:
    for path in sorted(AGENTS_DIR.glob("*.agent.md")):
        parsed = split_frontmatter(path, report)
        if not parsed:
            continue
        metadata, body = parsed
        error_unknown_agent_fields(path, metadata, report)
        require_string(path, metadata, "name", report)
        require_string(path, metadata, "description", report)
        validate_agent_tools(path, metadata, report)
        validate_agent_handoffs(path, metadata, agent_names, report)
        validate_agent_skill_references(path, body, skill_names, report)

        if not body:
            report.error(path, "empty agent body")
        if len(body) > MAX_AGENT_BODY_CHARS:
            report.error(
                path,
                f"agent body is {len(body)} chars; maximum is {MAX_AGENT_BODY_CHARS}",
            )


def validate_agent_tools(path: Path, metadata: dict[str, Any], report: ValidationReport) -> None:
    tools = metadata.get("tools")
    if tools is not None and not isinstance(tools, (list, str)):
        report.error(path, "`tools` must be a list or comma-separated string")
        return
    if tools is None:
        return

    tool_names = [tools] if isinstance(tools, str) else tools
    if len(tool_names) > TOOLS_BLOAT_THRESHOLD:
        report.warn(
            path,
            f"`tools` has {len(tool_names)} entries; consider <= {TOOLS_BLOAT_THRESHOLD} "
            "portable aliases plus required MCP tools to avoid copy-paste bloat",
        )

    for tool in tool_names:
        if not isinstance(tool, str) or not tool.strip():
            report.error(path, "`tools` entries must be non-empty strings")
            continue
        tool = tool.strip()
        if tool == "vscode":
            report.error(
                path,
                "`tools` includes invalid bare `vscode`; use portable aliases or MCP tools",
            )
        elif tool not in PORTABLE_TOOL_ALIASES and not MCP_TOOL.match(tool):
            report.warn(
                path,
                f"`tools` entry `{tool}` is not a portable alias or MCP tool form "
                "`server/*`/`server/tool`",
            )


def validate_agent_handoffs(
    path: Path,
    metadata: dict[str, Any],
    agent_names: set[str],
    report: ValidationReport,
) -> None:
    handoffs = metadata.get("handoffs", [])
    if handoffs is not None and not isinstance(handoffs, list):
        report.error(path, "`handoffs` must be a list")
        return
    if not isinstance(handoffs, list):
        return
    if handoffs:
        report.warn(path, "`handoffs` is VS Code-only and may not be portable to GitHub Copilot")

    for index, handoff in enumerate(handoffs, start=1):
        if not isinstance(handoff, dict):
            report.error(path, f"handoff #{index} must be a mapping")
            continue
        target = handoff.get("agent")
        if target not in agent_names:
            report.error(path, f"handoff #{index} references unknown agent `{target}`")


def validate_agent_skill_references(
    path: Path,
    body: str,
    skill_names: set[str],
    report: ValidationReport,
) -> None:
    in_skill_section = False
    for line_number, line in enumerate(body.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("#"):
            in_skill_section = bool(re.search(r"\bskills?\b", stripped, re.IGNORECASE))

        candidates = set(SKILL_PATH.findall(line))
        if in_skill_section:
            candidates.update(SKILL_NAME_TOKEN.findall(line))

        for candidate in sorted(candidates):
            if candidate not in skill_names:
                report.error(
                    path,
                    f"line {line_number}: references unknown skill `{candidate}`; "
                    "create `.github/skills/<name>/SKILL.md` or fix the reference",
                )


def validate_prompts(agent_names: set[str], report: ValidationReport) -> None:
    for path in sorted(PROMPTS_DIR.glob("*.prompt.md")):
        parsed = split_frontmatter(path, report)
        if not parsed:
            continue
        metadata, body = parsed
        warn_unknown_fields(path, metadata, VALID_PROMPT_FIELDS, report)
        require_string(path, metadata, "description", report)
        target_agent = metadata.get("agent")
        if target_agent is not None and target_agent not in agent_names:
            report.error(path, f"references unknown agent `{target_agent}`")
        if ":latest" in body:
            report.error(path, "contains forbidden deployment tag `:latest`")
        if "@master" in body:
            report.error(path, "references mutable GitHub Action ref `@master`")
        for line_number, line in enumerate(body.splitlines(), start=1):
            if PROMPT_TEMPLATE_VAR.search(line):
                report.error(
                    path,
                    f"line {line_number}: uses unsupported `{{{{var}}}}` syntax; "
                    "use `${input:name}` instead",
                )


def validate_skills(report: ValidationReport) -> None:
    for path in sorted(SKILLS_DIR.glob("*/SKILL.md")):
        parsed = split_frontmatter(path, report)
        if not parsed:
            continue
        metadata, body = parsed
        warn_unknown_fields(path, metadata, VALID_SKILL_FIELDS, report)
        require_string(path, metadata, "name", report)
        require_string(path, metadata, "description", report)
        name = metadata.get("name")
        if isinstance(name, str):
            if name != path.parent.name:
                report.error(
                    path,
                    f"skill name `{name}` must match parent directory `{path.parent.name}`",
                )
            if not 1 <= len(name) <= 64:
                report.error(path, "skill name must be 1-64 characters long")
            if not VALID_SKILL_NAME.match(name):
                report.error(
                    path,
                    "skill name must use lowercase letters, numbers, and single hyphens "
                    "between alphanumeric groups",
                )
        description = metadata.get("description")
        if isinstance(description, str) and not 10 <= len(description) <= 1024:
            report.error(path, "`description` must be 10-1024 characters long")
        if not body:
            report.error(path, "empty skill body")


def validate_instructions(tracked_files: list[str], report: ValidationReport) -> None:
    for path in sorted(INSTRUCTIONS_DIR.glob("*.instructions.md")):
        parsed = split_frontmatter(path, report)
        if not parsed:
            continue
        metadata, _ = parsed
        warn_unknown_fields(path, metadata, VALID_INSTRUCTION_FIELDS, report)
        require_string(path, metadata, "description", report)
        apply_to = metadata.get("applyTo")
        if not isinstance(apply_to, str) or not apply_to.strip():
            report.error(path, "missing or empty `applyTo`")
        elif apply_to.strip() in {"**", "**/*"}:
            report.error(path, "`applyTo` is too broad")
        else:
            validate_apply_to_liveness(path, apply_to, tracked_files, report)


def validate_apply_to_liveness(
    path: Path,
    apply_to: str,
    tracked_files: list[str],
    report: ValidationReport,
) -> None:
    patterns = [pattern.strip() for pattern in apply_to.split(",")]
    for pattern in patterns:
        if not pattern:
            report.error(path, "`applyTo` contains an empty glob")
            continue
        if not any(matches_apply_to(pattern, tracked_file) for tracked_file in tracked_files):
            report.error(
                path,
                f"`applyTo` glob `{pattern}` matches zero tracked files; "
                "fix the glob or remove the dead instruction",
            )


def validate_issue_template_labels(agent_names: set[str], report: ValidationReport, strict: bool) -> None:
    for path in sorted(ISSUE_TEMPLATE_DIR.glob("*.yml")) + sorted(ISSUE_TEMPLATE_DIR.glob("*.yaml")):
        content = path.read_text(encoding="utf-8")
        for label in AGENT_LABEL.findall(content):
            if label == "executing":
                continue
            if label not in agent_names:
                message = f"issue template uses unknown agent label `agent:{label}`"
                if strict:
                    report.error(path, message)
                else:
                    report.warn(path, message)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Open Horizons Copilot primitives")
    parser.add_argument("--strict", action="store_true", help="fail on issue-template agent label drift")
    args = parser.parse_args()

    report = ValidationReport()
    agent_names = collect_agent_names(report)
    skill_names = collect_skill_names()
    tracked_files = git_tracked_files(report)
    validate_agents(agent_names, skill_names, report)
    validate_prompts(agent_names, report)
    validate_skills(report)
    validate_instructions(tracked_files, report)
    validate_issue_template_labels(agent_names, report, args.strict)

    print("Validated customization primitives:")
    print(f"  Agents: {len(list(AGENTS_DIR.glob('*.agent.md')))}")
    print(f"  Prompts: {len(list(PROMPTS_DIR.glob('*.prompt.md')))}")
    print(f"  Skills: {len(list(SKILLS_DIR.glob('*/SKILL.md')))}")
    print(f"  Instructions: {len(list(INSTRUCTIONS_DIR.glob('*.instructions.md')))}")
    report.print()

    if report.errors:
        return 1

    print("\nAll Copilot customization primitives passed validation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
