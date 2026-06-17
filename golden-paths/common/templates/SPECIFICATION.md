# SPECIFICATION.md — Template

> Machine-parseable requirements using EARS notation.
> Version: 0.1.0 | Owner: [TEAM_NAME] | Date: [DATE]
>
> EARS = Easy Approach to Requirements Syntax
> Ref: SDD (2026) arXiv:2601.03878, arXiv:2602.00180

## Overview

<!-- 2-3 sentences: what does this system/feature do? -->

**System:** [SYSTEM_NAME]
**Objective:** [ONE_SENTENCE_OBJECTIVE]
**Constitution:** See [CONSTITUTION.md](./CONSTITUTION.md) for non-negotiable principles.

## Functional Requirements

### Ubiquitous (always true)

<!-- Format: The [system] shall [action]. -->

- REQ-U01: The system shall [always do X].
- REQ-U02: The system shall log every [action] with timestamp, actor, and outcome.

### Event-Driven (when something happens)

<!-- Format: When [trigger], the [system] shall [action]. -->

- REQ-E01: When [event occurs], the system shall [respond with action].
- REQ-E02: When an API call fails with 5xx, the system shall retry with exponential backoff (max 3 attempts).

### State-Driven (while in a state)

<!-- Format: While [state], the [system] shall [action]. -->

- REQ-S01: While [condition is true], the system shall [maintain behavior].
- REQ-S02: While the system is in maintenance mode, it shall reject new requests with HTTP 503.

### Conditional (if a condition holds)

<!-- Format: If [condition], then the [system] shall [action]. -->

- REQ-C01: If [condition], then the system shall [take action].
- REQ-C02: If the user's language is detected as Portuguese, then the system shall respond in Portuguese.

### Optional Features

<!-- Format: Where [feature is enabled], the [system] shall [action]. -->

- REQ-O01: Where [feature flag] is enabled, the system shall [provide capability].

## Non-Functional Requirements

| ID | Category | Requirement | Target |
|---|---|---|---|
| NFR-01 | Performance | Response latency P95 | < [X] ms |
| NFR-02 | Availability | Uptime SLA | [X]% |
| NFR-03 | Security | Authentication method | [method] |
| NFR-04 | Cost | Monthly token budget | < $[X] |
| NFR-05 | Observability | Trajectory logging | Every tool call logged |

## Failure Modes

<!-- What happens when things go wrong? Be explicit. -->

| Failure | Expected Behavior | Recovery |
|---|---|---|
| [External API down] | [Graceful degradation behavior] | [Retry then fallback] |
| [Token budget exceeded] | [Stop processing, notify user] | [Reset at next billing cycle] |
| [Intent drift detected] | [Alert owner, pause agent] | [Review CONSTITUTION.md] |

## Acceptance Criteria

<!-- These become test cases. Each must be independently verifiable. -->

- [ ] AC-01: Given [context], when [action], then [expected outcome].
- [ ] AC-02: Given [context], when [action], then [expected outcome].
- [ ] AC-03: Given [error condition], the system [handles gracefully].

## Out of Scope

<!-- Explicitly state what this spec does NOT cover. -->

- [Feature/behavior explicitly excluded]
- [Another exclusion]

## Dependencies

| Dependency | Type | Owner | SLA |
|---|---|---|---|
| [API/Service name] | Runtime | [team] | [uptime %] |
| [Database] | Data | [team] | [RPO/RTO] |

## Glossary

| Term | Definition |
|---|---|
| [Term] | [Definition in context of this spec] |
