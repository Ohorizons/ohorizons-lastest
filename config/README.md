# Open Horizons Platform - Configuration Files

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** Platform Engineers, Administrators

## Overview

This directory contains platform-wide configuration files for APM, region availability, and resource sizing.

## Files

| File | Description |
|------|-------------|
| `apm.yml` | Application Performance Monitoring configuration |
| `region-availability.yaml` | Azure region availability matrix for services |
| `sizing-profiles.yaml` | T-shirt sizing profiles (small, medium, large) for compute resources |

## Usage

These configuration files are referenced by Terraform modules and deployment scripts to determine resource sizing and region placement.

```bash
# Validate configuration
./scripts/validate-config.sh --environment dev
```

## 📚 Related Documentation

| Document | Description |
|----------|-------------|
| [Performance Tuning Guide](../docs/guides/PERFORMANCE_TUNING_GUIDE.md) | Sizing recommendations and tuning |
| [Module Reference](../docs/guides/MODULE_REFERENCE.md) | Terraform module configuration details |
| [Administrator Guide](../docs/guides/ADMINISTRATOR_GUIDE.md) | Platform administration procedures |

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
