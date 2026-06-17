---
title: "open-horizons-install-wizard-and-component-selection — Tasks"
feature_id: "001-open-horizons-install-wizard-and-component-selection"
version: "1.1.0"
date: "2026-05-05"
status: "Implemented"
---

# Tasks

All tasks below are marked `[x]` and were verified by `tests/wizard/run.sh` (21/21 PASS) and by the Wizard Tests GitHub Actions workflow.

## Phase 1 - Schema Extension

- [x] T001: Extend tfvars schema with 6 Backstage component flags (REQ-OUTPUT-002, REQ-VALIDATE-001).
- [x] T002: Wire flags through `terraform/variables.tf` (REQ-OUTPUT-002).

## Phase 2 - Wizard Core

- [x] T003: Create `scripts/install-wizard.sh` with CLI parser (REQ-WIZARD-001, REQ-WIZARD-003).
- [x] T004: Implement manifest loader with yq null-safety (REQ-DIFF-002, REQ-OUTPUT-001).
- [x] T005: Implement interactive prompts gated by horizon (REQ-WIZARD-002).
- [x] T006: Implement dependency validators RULE-001..RULE-004 (REQ-VALIDATE-001, REQ-VALIDATE-002).

## Phase 3 - Renderers

- [x] T007: Implement tfvars renderer with atomic writes and .bak (REQ-OUTPUT-002).
- [x] T008: Implement app-config regenerator preserving non-Golden-Path entries (REQ-OUTPUT-003).
- [x] T009: Implement diff/confirm helper honoring --auto and --dry-run (REQ-DIFF-001).

## Phase 4 - Validation and Audit

- [x] T010: Implement post-write validation chain (REQ-VALIDATE-003).
- [x] T011: Implement audit log writer with sha256 (REQ-AUDIT-001).
- [x] T012: Implement deploy handoff (REQ-HANDOFF-001).
- [x] T013: Implement OIDC handoff hint (REQ-HANDOFF-002).

## Phase 5 - Documentation

- [x] T014: Document Selection Matrix in MASTER_INSTALLATION.md (REQ-DOCS-001).
- [x] T015: Update CLIENT_INSTALLATION.md install path to start with the wizard (REQ-DOCS-001).

## Phase 6 - Tests and Validation

- [x] T016: Add tests/wizard/run.sh smoke tests (REQ-VALIDATE-001, REQ-DIFF-002, REQ-WIZARD-003).
- [x] T017: End-to-end validation and commit (REQ-VALIDATE-003, REQ-DOCS-001).

## Amendment 1 - Wire Selections (2026-05-05)

- [x] T018: Add `scripts/render-manifests.sh` to filter `backstage/k8s/` based on manifest (REQ-WIRING-001).
- [x] T019: Wire deploy-full.sh to load manifest, validate consistency, and apply rendered manifests in Phase 5b (REQ-WIRING-002).

## Amendment 2 - UX and Hardening (2026-05-05)

- [x] T020: Add `--profile minimal|standard|full` curated presets to install-wizard.
- [x] T021: Add `scripts/openhorizons-selection.schema.json` and pre-load schema validator (rejects unknown keys, secret-like keys, invalid enums).
- [x] T022: Add `.github/workflows/wizard-tests.yml` to run the wizard and render-manifests tests on every PR touching wizard code.
- [x] T023: Extend tests/wizard/run.sh with profile and schema tests (Tests 9-12).

Total: 23 tasks complete. Coverage 100%.
