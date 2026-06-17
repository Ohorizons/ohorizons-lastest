# Open Horizons Platform - Terraform Environments

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** Platform Engineers, Infrastructure Engineers

## Overview

This directory contains environment-specific Terraform variable files (`.tfvars`) for each deployment stage.

## Environments

| File | Environment | Description |
|------|-------------|-------------|
| `dev.tfvars` | Development | Lower-cost SKUs, relaxed security for rapid iteration |
| `staging.tfvars` | Staging | Production-like configuration for validation |
| `prod.tfvars` | Production | Full HA, private endpoints, strict security |

## Usage

```bash
cd terraform

# Plan for a specific environment
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars
```

## 📚 Related Documentation

| Document | Description |
|----------|-------------|
| [Terraform README](../README.md) | Module structure and backend configuration |
| [Module Reference](../../docs/guides/MODULE_REFERENCE.md) | Detailed module input/output documentation |
| [Deployment Guide](../../docs/guides/DEPLOYMENT_GUIDE.md) | End-to-end deployment instructions |

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
