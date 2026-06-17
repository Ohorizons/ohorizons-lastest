---
title: "install-wizard-and-component-selection — Constitution"
feature_id: "001-install-wizard-and-component-selection"
version: "1.0.0"
date: "2026-05-05"
author: "SDD Pipeline"
status: "Draft"
---
<!-- markdownlint-disable -->
# install-wizard-and-component-selection — Constitution

> The foundational charter for the **install-wizard-and-component-selection** project, establishing principles, constraints, and success criteria.

---

## Article 1: Project Identity

- **Name:** install-wizard-and-component-selection
- **Description:** Foundational charter for install-wizard-and-component-selection
- **Creator:** SDD Pipeline
- **License:** MIT

---

## Article 2: Principles


- Selection without forking - clients pick what to install via tfvars and a single wizard, never edit core files

- Backward compatible defaults - existing tfvars and deploy-full.sh keep working when no new flags are set

- Single source of truth per concern - tfvars drives Terraform, app-config catalog drives Backstage templates, no duplicate configs

- Reversible operations - every selection can be flipped without redeploy from scratch

- Validation gates - any selection must be validated before terraform apply or backstage rollout


---

## Article 3: Constraints


- Must keep current 16 Terraform modules and 34 Golden Paths intact

- Must not break the existing scripts/deploy-full.sh interface or its --horizon flag

- Must work with the already-shipped backstage/app-config.production.yaml structure (catalog.locations of type url)

- Wizard must be non-interactive friendly (CLI flags) so it works in CI/CD as well as locally

- All new tfvars flags default to current behavior (true if a feature was always on, false otherwise) so dev.tfvars stays compatible

- Cannot require new external services - everything runs with bash, terraform, gh, az already in use


---

## Article 4: Success Criteria

| ID | Criterion | Measure |
|----|-----------|---------|
| SC-001 | Project compiles without errors | `npm run build` exits 0 |
| SC-002 | All requirements traceable | Every REQ has design + task mapping |
| SC-003 | Quality gates pass | Analysis gate returns APPROVE |

---

## Article 5: Scope

### In Scope
- Core project features

### Out of Scope
- Future enhancements not in initial scope

---

## Amendment Log

| # | Date | Author | Rationale | Articles Affected |
|---|------|--------|-----------|-------------------|
| — | — | — | Initial version | All |
