---
title: "GitHub Copilot Metrics Correlation Runbook"
description: "Operational runbook for collecting, correlating, and reporting GitHub Copilot usage and contribution metrics for enterprise engineering organizations."
author: "Open Horizons"
date: "2026-04-14"
version: "2.3.0"
status: "draft"
tags: ["github-copilot", "metrics", "analytics", "devops", "runbook", "usage-metrics-api", "agent-metrics", "engineering-effectiveness"]
---

# GitHub Copilot Metrics Correlation Runbook

> Operational guidance for collecting GitHub Copilot usage metrics, correlating them with GitHub contribution data, and presenting enterprise-ready adoption and engineering effectiveness insights.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.3.0 | 2026-04-14 | Open Horizons | English enterprise rewrite with clarified governance, correlation model, and references |
| 2.2.0 | 2026-04-14 | Open Horizons | Added pull request lifecycle correlation model |
| 2.1.0 | 2026-04-14 | Open Horizons | Added agent-initiated activity considerations |
| 2.0.0 | 2026-04-14 | Open Horizons | Migrated to Copilot Usage Metrics API model |
| 1.0.0 | 2026-04-09 | Open Horizons | Initial operational runbook |

## Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Governance Principles](#3-governance-principles)
- [4. Data Sources](#4-data-sources)
- [5. Correlation Model](#5-correlation-model)
- [6. Collection Workflow](#6-collection-workflow)
- [7. Reporting Model](#7-reporting-model)
- [8. Quality Gates](#8-quality-gates)
- [9. Troubleshooting](#9-troubleshooting)
- [10. References](#10-references)

## 1. Purpose

This runbook defines a repeatable operating model for measuring GitHub Copilot adoption and correlating it with engineering workflow signals. It is intended for enterprise engineering, platform engineering, and developer productivity teams.

The goal is not to rank individual developers. The goal is to understand adoption patterns, platform readiness, workflow bottlenecks, and opportunities for enablement.

## 2. Scope

### 2.1 In Scope

- GitHub Copilot usage metrics collection.
- GitHub pull request and contribution metadata correlation.
- Team-level and organization-level reporting.
- Quality context for interpreting activity metrics.
- Governance guidance for responsible metric usage.

### 2.2 Out of Scope

- Individual performance scoring.
- Compensation or promotion decisions.
- Surveillance workflows.
- Unverified ROI claims.
- Claims that do not have source data or credible references.

## 3. Governance Principles

| Principle | Requirement | Rationale |
|-----------|-------------|-----------|
| Privacy by design | Report at team or cohort level by default | Avoid misuse of developer-level telemetry |
| No single-metric decisions | Combine adoption, flow, and quality signals | Activity alone does not measure productivity |
| Source traceability | Link every metric to a source system | Keep reports auditable |
| Context first | Interpret changes with delivery context | Sprint scope, incidents, and refactoring affect metrics |
| Quality pairing | Pair volume metrics with quality indicators | Prevent false positives from raw output growth |

> [!IMPORTANT]
> Copilot metrics should support enablement and platform improvement. They should not be used as a standalone measure of individual developer performance.

## 4. Data Sources

| Source | Example Signals | Purpose |
|--------|-----------------|---------|
| GitHub Copilot usage metrics | Active users, suggestions, acceptances, chat usage | Adoption and feature usage |
| GitHub Pulls API | Pull request count, time to merge, review state | Delivery flow correlation |
| GitHub Checks API | Passing/failing checks, required checks, conclusions | Quality gate context |
| Code quality systems | Coverage, code smells, vulnerabilities | Quality pairing |
| Incident and deployment systems | Change failure, rollback, MTTR | Reliability context |

## 5. Correlation Model

The correlation model combines direct Copilot usage signals with delivery workflow metadata. Treat the output as directional evidence, not causality.

```text
Copilot usage metrics
        |
        v
Contribution and PR metadata
        |
        v
Quality and reliability signals
        |
        v
Team-level adoption and engineering effectiveness report
```

### 5.1 Metric Layers

| Layer | Metric Family | Example Questions |
|-------|---------------|-------------------|
| Layer 1 | Direct Copilot usage | Are licensed users actively using Copilot? |
| Layer 2 | Contribution flow | Did PR throughput or time to merge change? |
| Layer 3 | Pull request lifecycle | Are agent-assisted PRs reviewed and merged safely? |
| Layer 4 | Quality context | Did defect, coverage, or code health signals move? |

## 6. Collection Workflow

1. Confirm GitHub Enterprise Cloud access and required permissions.
2. Enable or verify Copilot metrics access at the organization level.
3. Collect Copilot usage metrics for the reporting period.
4. Collect pull request metadata for the same period.
5. Collect check run and review state metadata for the same repositories.
6. Normalize identities and repository names.
7. Aggregate by team, repository, business unit, or platform domain.
8. Pair activity metrics with quality and reliability signals.
9. Generate a report with assumptions, caveats, and source links.

### 6.1 Example Collection Inputs

| Input | Description |
|-------|-------------|
| `organization` | GitHub organization name |
| `start_date` | Reporting window start date |
| `end_date` | Reporting window end date |
| `repositories` | Repository allowlist or topic-filtered set |
| `teams` | GitHub team mapping for aggregation |
| `quality_sources` | Optional systems such as SonarQube or CodeQL |

## 7. Reporting Model

### 7.1 Executive Summary

The executive view should answer three questions:

1. Is Copilot adoption increasing in the right teams?
2. Are delivery flow metrics improving, stable, or degrading?
3. Are quality and reliability signals healthy enough to trust the productivity story?

### 7.2 Operating Dashboard

| Section | Audience | Content |
|---------|----------|---------|
| Adoption | Engineering leadership | Active usage, seats, feature mix |
| Flow | Platform and delivery leads | PR throughput, time to merge, review wait |
| Quality | Engineering managers and security | Check failures, coverage, vulnerabilities |
| Enablement | Platform team | Teams needing training, docs, or templates |

### 7.3 Narrative Requirements

Every report must include:

- Scope and reporting window.
- Data sources and known gaps.
- Aggregation level.
- Assumptions and caveats.
- Top opportunities for enablement.
- Risks or quality signals that require attention.

## 8. Quality Gates

Use this checklist before publishing a report.

- [ ] Data sources are documented.
- [ ] Reporting period is explicit.
- [ ] Metrics are aggregated appropriately.
- [ ] Individual performance language is avoided.
- [ ] Raw activity metrics are paired with quality indicators.
- [ ] Every external claim has a source link.
- [ ] Caveats are included.
- [ ] Recommendations are actionable.

## 9. Troubleshooting

| Symptom | Likely Cause | Remediation |
|---------|--------------|-------------|
| `403 Forbidden` from metrics endpoint | Missing permission or policy disabled | Verify Copilot metrics policy and token scopes |
| Empty usage data | Reporting window has no activity or API lag | Recheck dates and wait for metric availability |
| Repository mismatch | Renamed or archived repositories | Normalize repository IDs and names |
| User mismatch | Multiple identities across systems | Use GitHub user ID as the primary join key |
| Misleading growth | Large refactor or migration in reporting window | Annotate the period and compare against quality signals |

## 10. References

- [GitHub Docs - Copilot usage metrics](https://docs.github.com/en/copilot/rolling-out-github-copilot-at-scale/analyzing-usage-over-time-with-the-copilot-metrics-api)
- [GitHub REST API - Pull requests](https://docs.github.com/en/rest/pulls/pulls)
- [GitHub REST API - Checks](https://docs.github.com/en/rest/checks)
- [DORA research program](https://dora.dev/)
- [SPACE framework paper](https://queue.acm.org/detail.cfm?id=3454124)
