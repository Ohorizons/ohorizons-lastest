---
description: "Decompose an epic into INVEST user stories and optionally create GitHub Issues."
agent: "compass"
---

# Decompose Epic into Stories

Break down an epic or feature request into well-structured INVEST user stories.

## Input
- **Epic description:** ${input:epic_description:Epic or feature description}
- **Repository (for issues):** ${input:repo_name:Repository name}
- **Create GitHub Issues?:** ${input:create_issues:yes or no}

## Instructions

1. Read the [Story Planning Skill](../skills/story-planning/SKILL.md)
2. Analyze the epic scope and identify personas
3. Check for existing issues: `gh issue list --repo Ohorizons/${input:repo_name} --search "${input:epic_description}" --state open`
4. Decompose into maximum 8 INVEST user stories
5. Write each story with the template: "As a [persona], I want [X], so that [Y]"
6. Include 3-5 acceptance criteria per story
7. If `${input:create_issues}` is yes, create GitHub Issues after user review

## Output Format

Provide results using the Epic Decomposition Report template from the Story Planning skill:
- Stories table → Dependencies → Next steps
- Show stories for review BEFORE creating issues
