---
title: "Enterprise Validation Hardening Test Matrix"
description: "Traceability matrix from acceptance criteria to tests and evidence."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["test-matrix", "TDD", "evidence"]
---

# Enterprise Validation Hardening Test Matrix

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial matrix |

## Matrix

| AC | Requirement | Validation Method | Command Or Evidence | Status |
|----|-------------|-------------------|---------------------|--------|
| AC-01 | SDD package exists | Manual + file existence | `docs/sdd/enterprise-validation-hardening/*` | Passed |
| AC-02 | Entra plus EMU valid path | Automated | `/opt/homebrew/bin/bash tests/wizard/run.sh` | Passed |
| AC-03 | GitHub plus EMU invalid | Automated | `/opt/homebrew/bin/bash tests/wizard/run.sh` | Passed |
| AC-04 | Guest plus EMU invalid | Automated | `/opt/homebrew/bin/bash tests/wizard/run.sh` | Passed |
| AC-05 | Entra render auth block | Automated | `bash tests/validation/render-entra-emu.sh` | Passed |
| AC-06 | Terraform output redaction | Automated | `bash tests/validation/redaction.sh` | Passed |
| AC-07 | Terraform plan redaction | Automated | `bash tests/validation/redaction.sh` | Passed |
| AC-08 | Ready nodes pass | Automated | `bash tests/validation/validate-h1-node-check.sh` | Passed |
| AC-09 | No Ready nodes fail | Automated | `bash tests/validation/validate-h1-node-check.sh` | Passed |
| AC-10 | Missing enabled H2/H3 fails | Automated | `bash tests/validation/scope-aware-components.sh` | Planned |
| AC-11 | Resume mismatch fails | Automated | `bash tests/deploy/resume.sh` | Passed |
| AC-12 | ArgoCD URLs fork-ready | Automated | `bash tests/validation/fork-ready-argocd.sh` | Passed |
| AC-13 | Live validate-all/inventory/docs | Live evidence | `runs/azure-validation/contoso-prod-nogithub-finalcheck` sanitized evidence | Passed |

## Required Local Gate

```bash
bash -n scripts/*.sh
/opt/homebrew/bin/bash tests/wizard/run.sh
bash tests/validation/redaction.sh
bash tests/validation/render-entra-emu.sh
bash tests/validation/write-validation-tfvars-scope.sh
bash tests/validation/validate-h1-node-check.sh
bash tests/validation/fork-ready-argocd.sh
bash tests/deploy/resume.sh
bash tests/terraform/security-callback.sh
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```

Latest local gate result on 2026-06-19: all listed shell and wizard tests passed; Terraform validation passed with existing AzureRM provider deprecation warnings for AKS managed Entra integration.

Latest live gate result on 2026-06-19: `validate-all`, `inventory`, and `docs` passed for `contoso-prod-nogithub-finalcheck`; H1 reported 3/3 nodes Ready, `errors.json` was empty, and sanitized inventory artifacts passed the sensitive-pattern scan.

## Required Live Gate

```bash
scripts/azure-validation-run.sh --phase validate-all --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
scripts/azure-validation-run.sh --phase inventory --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
scripts/azure-validation-run.sh --phase docs --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
```
