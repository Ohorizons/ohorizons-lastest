---
description: "Decompose an epic into INVEST user stories and optionally create GitHub Issues."
mode: "agent"
agent: "compass"
---

# Decompose Epic into Stories

Break down an epic or feature request into well-structured INVEST user stories.

## Input
- **Epic description:** {{epic_description}}
- **Repository (for issues):** {{repo_name}}
- **Create GitHub Issues?:** {{create_issues}}

## Instructions

1. Read the [Story Planning Skill](../skills/story-planning/SKILL.md)
2. Analyze the epic scope and identify personas
3. Check for existing issues: `gh issue list --repo Ohorizons/{{repo_name}} --search "{{epic_description}}" --state open`
4. Decompose into maximum 8 INVEST user stories
5. Write each story with the template: "As a [persona], I want [X], so that [Y]"
6. Include 3-5 acceptance criteria per story
7. If `{{create_issues}}` is yes, create GitHub Issues after user review

## Output Format

Provide results using the Epic Decomposition Report template from the Story Planning skill:
- Stories table → Dependencies → Next steps
- Show stories for review BEFORE creating issues
