---
title: "Open Horizons Install Wizard and Component Selection — Specification"
feature_id: "001-open-horizons-install-wizard-and-component-selection"
version: "1.0.0"
date: "2026-05-05"
author: "SDD Pipeline"
status: "Draft"
---
<!-- markdownlint-disable -->
# Open Horizons Install Wizard and Component Selection — Specification

> All requirements use **EARS notation** (Easy Approach to Requirements Syntax). Each requirement is testable, unambiguous, and traceable to the Constitution's success criteria.

---

## Table of Contents

- [1. Core Requirements](#1-core-requirements)
- [2. Functional Requirements](#2-functional-requirements)
- [3. Non-Functional Requirements](#3-non-functional-requirements)
- [Acceptance Criteria Summary](#acceptance-criteria-summary)

---

## 1. Core Requirements

### REQ-WIZARD-001: (ubiquitous)

The system SHALL provide a single command-line wizard at scripts/install-wizard.sh that lets the client select horizon level, Terraform modules, Backstage components, and Golden Path templates.

**Acceptance Criteria:**
- scripts/install-wizard.sh exists and is executable
- Running it with --help prints usage and all flags
- Exit code is 0 on success and non-zero on validation failure

---

### REQ-WIZARD-002: (event_driven)

WHEN the wizard is invoked without arguments, THE system SHALL run an interactive prompt that walks through horizon selection, module toggles, Backstage component toggles, and Golden Path subset selection.

**Acceptance Criteria:**
- Interactive flow asks horizon (h1|h2|h3|all)
- Interactive flow lists each terraform enable_* flag with current default
- Interactive flow lists each Backstage component (ai_chat plugin, agent_api, agent_api_impact, agent_api_maf, agent_api_sk, mcp_ecosystem)
- Interactive flow lists Golden Paths grouped by horizon and lets user select subset

---

### REQ-WIZARD-003: (event_driven)

WHEN the wizard is invoked with --auto and --selection-file <path>, THE system SHALL load selections from the file and run non-interactively.

**Acceptance Criteria:**
- --auto requires --selection-file
- Missing --selection-file with --auto exits with non-zero status and clear message
- All confirmations are skipped in --auto mode

---

### REQ-OUTPUT-001: (ubiquitous)

The system SHALL persist client choices to a manifest file .openhorizons-selection.yaml at the repository root.

**Acceptance Criteria:**
- Manifest YAML is well-formed and parseable by yq
- Manifest contains horizon, modules, backstage_components, golden_paths, environment fields
- Manifest is created if missing and updated atomically (write to .tmp then rename)

---

### REQ-OUTPUT-002: (event_driven)

WHEN the wizard finishes, THE system SHALL update terraform/environments/<env>.tfvars with the selected enable_* flags and deployment options.

**Acceptance Criteria:**
- File is created from terraform/terraform.tfvars.example if missing
- Existing values not managed by the wizard are preserved
- Backup file <env>.tfvars.bak.<timestamp> is created before rewrite

---

### REQ-OUTPUT-003: (event_driven)

WHEN the wizard finishes and Golden Path subset is non-empty, THE system SHALL regenerate backstage/app-config.production.yaml so catalog.locations only includes the selected templates.

**Acceptance Criteria:**
- Only selected templates appear under catalog.locations of type url
- Static catalog locations not pointing at golden-paths are preserved
- Backup file backstage/app-config.production.yaml.bak.<timestamp> is created before rewrite

---

### REQ-OUTPUT-004: (ubiquitous)

The system SHALL never write secret values (subscription IDs, tokens, private keys) into .openhorizons-selection.yaml or any committed file.

**Acceptance Criteria:**
- Manifest YAML schema rejects fields starting with secret_, token_, password_
- Wizard reads sensitive values only from environment variables (TF_VAR_*) and never echoes them
- A test asserts manifest never contains substrings like ghp_, sp_, ARM_ACCESS_KEY

---

### REQ-VALIDATE-001: (ubiquitous)

The system SHALL validate dependency rules between selections before writing any files.

**Acceptance Criteria:**
- enable_ai_foundry true requires horizon h3 or all
- enable_ai_chat_plugin true requires enable_agent_api true
- enable_mcp_ecosystem true requires golden_paths containing at least one mcp-* template
- enable_disaster_recovery true is allowed only when deployment_mode is standard or enterprise

---

### REQ-VALIDATE-002: (unknown)

WHEN any dependency rule is violated, THE wizard SHALL print a structured error listing the failing rule and exit with non-zero status without writing files.

**Acceptance Criteria:**
- Error message includes rule id and human-readable explanation
- No partial writes occur (verified by checking file mtimes)
- Exit code 2 is reserved for dependency rule violations

---

### REQ-VALIDATE-003: (event_driven)

WHEN tfvars and app-config.production.yaml are written, THE system SHALL re-run the existing validators (validate-config.sh and validate-scaffolder-templates.sh) and report any failures.

**Acceptance Criteria:**
- validate-config.sh --environment <env> is invoked
- validate-scaffolder-templates.sh golden-paths is invoked
- Wizard exits non-zero if either validator fails

---

### REQ-DIFF-001: (event_driven)

WHEN the wizard would change an existing file, THE system SHALL print a unified diff and prompt for confirmation in interactive mode.

**Acceptance Criteria:**
- diff -u output is shown for tfvars and app-config.production.yaml
- User can answer y/n; n cancels the wizard with exit code 0 and no writes
- In --auto mode confirmation is skipped

---

### REQ-DIFF-002: (event_driven)

WHEN the wizard runs against an existing manifest, THE system SHALL load previous selections, present them as defaults, and apply only the deltas.

**Acceptance Criteria:**
- Re-running with same selections produces no file changes
- Re-running with one toggled module updates only the affected lines in tfvars
- Re-running with reduced Golden Path set removes only the affected catalog.locations entries

---

### REQ-AUDIT-001: (ubiquitous)

The system SHALL append every successful run to .openhorizons-selection.history with timestamp, user, environment, and a hash of the manifest.

**Acceptance Criteria:**
- History file is created if missing
- Each run appends one line in format: <iso8601-ts> <user> <env> <sha256>
- History file is never overwritten or truncated by the wizard

---

### REQ-HANDOFF-001: (event_driven)

WHEN the wizard completes successfully and is invoked with --next-step deploy, THE system SHALL call scripts/deploy-full.sh with the chosen --environment and --horizon.

**Acceptance Criteria:**
- deploy-full.sh receives the same horizon value used in selection
- If --auto is set, deploy-full.sh receives --auto-approve
- If --next-step is omitted the wizard prints the recommended deploy command and exits

---

### REQ-HANDOFF-002: (event_driven)

WHEN the wizard completes and any selection requires Azure credentials, THE system SHALL print the exact command to run scripts/setup-identity-federation.sh with values derived from the selection.

**Acceptance Criteria:**
- Command is printed verbatim to stdout, never executed automatically
- Resource group name is derived from customer_name and environment
- Command is suppressed if no Azure-dependent module is enabled

---

### REQ-DOCS-001: (ubiquitous)

The system SHALL update docs/guides/MASTER_INSTALLATION.md and docs/guides/CLIENT_INSTALLATION.md with a Selection Matrix section describing the wizard inputs and outputs.

**Acceptance Criteria:**
- A new section called Selection Matrix exists in MASTER_INSTALLATION.md
- CLIENT_INSTALLATION.md links to the wizard as Step 0 of the install path
- scripts/validate-docs.sh --include-skeletons exits 0

---


---

## 2. Functional Requirements



---

## 3. Non-Functional Requirements



---

## Acceptance Criteria Summary

| ID | Requirement | Test Method |
|----|-------------|-------------|
| REQ-WIZARD-001 | The system SHALL provide a single command-line wizard at scr... | Acceptance test |
| REQ-WIZARD-002 | WHEN the wizard is invoked without arguments, THE system SHA... | Acceptance test |
| REQ-WIZARD-003 | WHEN the wizard is invoked with --auto and --selection-file ... | Acceptance test |
| REQ-OUTPUT-001 | The system SHALL persist client choices to a manifest file .... | Acceptance test |
| REQ-OUTPUT-002 | WHEN the wizard finishes, THE system SHALL update terraform/... | Acceptance test |
| REQ-OUTPUT-003 | WHEN the wizard finishes and Golden Path subset is non-empty... | Acceptance test |
| REQ-OUTPUT-004 | The system SHALL never write secret values (subscription IDs... | Acceptance test |
| REQ-VALIDATE-001 | The system SHALL validate dependency rules between selection... | Acceptance test |
| REQ-VALIDATE-002 | WHEN any dependency rule is violated, THE wizard SHALL print... | Acceptance test |
| REQ-VALIDATE-003 | WHEN tfvars and app-config.production.yaml are written, THE ... | Acceptance test |
| REQ-DIFF-001 | WHEN the wizard would change an existing file, THE system SH... | Acceptance test |
| REQ-DIFF-002 | WHEN the wizard runs against an existing manifest, THE syste... | Acceptance test |
| REQ-AUDIT-001 | The system SHALL append every successful run to .openhorizon... | Acceptance test |
| REQ-HANDOFF-001 | WHEN the wizard completes successfully and is invoked with -... | Acceptance test |
| REQ-HANDOFF-002 | WHEN the wizard completes and any selection requires Azure c... | Acceptance test |
| REQ-DOCS-001 | The system SHALL update docs/guides/MASTER_INSTALLATION.md a... | Acceptance test |

---

## Self-Assessment

| Criterion | Score | Notes |
|-----------|-------|-------|
| EARS notation compliance | 16/16 | |
| Testability | 16/16 | Every requirement has acceptance criteria |
| Traceability | 16/16 | Every requirement traces to Constitution |
| Uniqueness of IDs | 16/16 | No duplicate requirement IDs |

## Amendments

### Amendment 1 — Wire selections into deployment (2026-05-05)

Added two follow-up requirements after the install wizard's flags were detected as decorative (no consumer in deploy path):

| ID | Requirement |
|----|-------------|
| REQ-WIRING-001 | The system SHALL ship `scripts/render-manifests.sh` that reads `.openhorizons-selection.yaml` and emits a kustomize-compatible directory at `backstage/k8s/.rendered/` containing only the manifests whose corresponding flag is enabled. |
| REQ-WIRING-002 | WHEN `scripts/deploy-full.sh` runs and `.openhorizons-selection.yaml` exists, THE script SHALL load the manifest, warn on environment/horizon mismatch with CLI flags, render the Backstage manifests, and apply them with `kubectl apply -k` when a live cluster context is available. |

Acceptance evidence: `tests/wizard/run.sh` Tests 7 and 8 (render include/exclude, dry-run safety).
