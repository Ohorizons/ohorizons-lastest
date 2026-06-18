---
title: "Backstage Demo Manifests"
description: "Non-production Backstage demo manifests separated from the enterprise deployment path."
author: "Open Horizons"
date: "2026-06-18"
version: "1.0.0"
status: "approved"
tags: ["backstage", "demo", "helm", "enterprise-readiness"]
---

# Backstage Demo Manifests

> These files are retained as demo references only. They are intentionally outside `deploy/helm/` so enterprise deployment validation does not treat them as production manifests.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-18 | Open Horizons | Moved demo manifests out of the deployment path |

## Table of Contents

- [1. Purpose](#1-purpose)
- [2. Files](#2-files)
- [3. Enterprise Deployment Path](#3-enterprise-deployment-path)
- [References](#references)

## 1. Purpose

These examples show an ad hoc Backstage proof-of-concept shape that can be useful for local demos, workshops, or troubleshooting. They are not hardened for enterprise production and should not be used by automation.

## 2. Files

| File | Purpose | Production Status |
|------|---------|-------------------|
| `backstage-v1.48.0-clean-values.yaml` | Minimal Backstage Helm values for a demo endpoint | Demo only |
| `ingress-all.yaml` | Demo ingress resources for Prometheus and Alertmanager | Demo only |
| `argocd-apps.yaml` | Demo ArgoCD Application bundle | Demo only |

## 3. Enterprise Deployment Path

Enterprise deployments use the install wizard, rendered Kubernetes templates, Terraform modules, OIDC-based GitHub Actions workflows, and external TechDocs publishing. The canonical workflow is documented in [Client Installation](../../guides/CLIENT_INSTALLATION.md) and [Enterprise Readiness](../../guides/ENTERPRISE_READINESS.md).

## References

- [Backstage deployment documentation](https://backstage.io/docs/deployment/)
- [Backstage TechDocs configuration](https://backstage.io/docs/features/techdocs/configuration/)
- [GitHub Actions OIDC with Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)