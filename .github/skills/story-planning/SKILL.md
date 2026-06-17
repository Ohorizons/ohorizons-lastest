---
name: story-planning
description: "INVEST user story decomposition and GitHub Issues creation — epic analysis, persona identification, acceptance criteria, and sprint-ready stories. USE FOR: decompose epic, create user stories, INVEST criteria, acceptance criteria, sprint planning, create GitHub issues, story mapping, backlog grooming. DO NOT USE FOR: test analysis (use test-coverage), pipeline diagnostics (use pipeline-diagnostics), architecture design (use @architect)."
---

# Story Planning Skill

Domain knowledge for the **@compass** agent — planning and user story decomposition via GitHub Issues API.

## INVEST Criteria

Every user story MUST satisfy all six INVEST criteria:

| Criterion | Question | Bad Example | Good Example |
|-----------|----------|-------------|--------------|
| **I**ndependent | Can it be developed without other stories? | "Create API (needs DB first)" | "Create API with in-memory store" |
| **N**egotiable | Are the details flexible? | "Use Redis cache with TTL=300s" | "Add caching layer for performance" |
| **V**aluable | Does it deliver user/business value? | "Refactor database module" | "Users can search orders by date" |
| **E**stimable | Can the team estimate effort? | "Make the system fast" | "Add pagination to order list API" |
| **S**mall | Does it fit in one sprint? | "Build entire checkout flow" | "Add payment method selection step" |
| **T**estable | Can we verify it's done? | "Improve UX" | "User sees confirmation within 2s" |

## Story Template

```markdown
## Story: {Title}

As a **{persona}**, I want **{functionality}**, so that **{benefit}**.

### Acceptance Criteria
- [ ] {criterion_1}
- [ ] {criterion_2}
- [ ] {criterion_3}

### Technical Notes
- {implementation_hint}

### Labels
`user-story`, `epic:{epic-name}`, `priority:{high|medium|low}`
```

## Epic Decomposition Process

### Step 1 — Understand the Epic
- What problem does it solve?
- Who are the target users/personas?
- What's the expected outcome?
- What's out of scope?

### Step 2 — Identify Personas
Common personas in this platform:
- **Developer** — Builds and ships code
- **SRE** — Monitors and maintains reliability
- **Platform Engineer** — Manages the IDP and Golden Paths
- **Tech Lead** — Makes architecture decisions
- **Product Owner** — Defines requirements and priorities

### Step 3 — Story Mapping
Organize stories by user journey:

```
Epic: {name}
├── Story 1: Setup/Foundation (must do first)
├── Story 2: Core Feature A
├── Story 3: Core Feature B
├── Story 4: Integration
├── Story 5: Edge Cases
└── Story 6: Polish/Documentation
```

### Step 4 — Write Acceptance Criteria
Good acceptance criteria are:
- **Specific** — No ambiguity
- **Measurable** — Can be verified
- **Checklist format** — Using `- [ ]` markdown
- **3-5 per story** — Not too few, not too many

## GitHub Issues API Reference

### Creating Issues

```bash
# Create an issue
gh issue create --repo {owner}/{repo} \
  --title "Story: {title}" \
  --body "{markdown_body}" \
  --label "user-story,epic:{epic}"

# Create with assignee
gh issue create --repo {owner}/{repo} \
  --title "Story: {title}" \
  --body "{markdown_body}" \
  --label "user-story" \
  --assignee "{username}"
```

### Querying Issues

```bash
# List issues by label
gh issue list --repo {owner}/{repo} --label "epic:{name}" --state open

# Search for duplicates
gh issue list --repo {owner}/{repo} --search "{keywords}"

# Get issue details
gh issue view {number} --repo {owner}/{repo}
```

### REST API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/repos/{owner}/{repo}/issues` | POST | Create issue |
| `/repos/{owner}/{repo}/issues` | GET | List issues |
| `/repos/{owner}/{repo}/issues/{number}` | GET | Get issue details |
| `/repos/{owner}/{repo}/issues/{number}` | PATCH | Update issue |

## Rules

- Maximum **8 stories per epic** — if more are needed, the epic should be split
- Never estimate **story points** — that's the team's responsibility
- Always **check for duplicates** before creating issues
- Every story must have **acceptance criteria**
- Stories should be **independent** — avoid sequential dependencies when possible
- Label convention: `user-story`, `epic:{name}`, `priority:{level}`

## Output Template — Epic Decomposition Report

```markdown
## 🧭 Epic Decomposition

**Epic:** {epic_name}
**Personas:** {persona_list}
**Total Stories:** {count}

### Stories

| # | Title | Persona | Labels |
|---|-------|---------|--------|
| 1 | {title} | {persona} | `user-story`, `epic:{name}` |

### Dependencies
- Story {n} should be completed before Story {m} because {reason}

### Next Steps
1. Review stories with the team
2. Estimate in sprint planning
3. Prioritize with PO
```

## Quality Checklist

- [ ] All stories satisfy INVEST criteria
- [ ] Each story has 3-5 acceptance criteria
- [ ] Checked for duplicate issues before creating
- [ ] Maximum 8 stories per epic
- [ ] No story point estimates included
- [ ] Labels applied consistently
- [ ] Used story template format
- [ ] Provided epic decomposition summary
