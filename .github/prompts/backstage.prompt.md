---
description: "Deploy and configure Backstage developer portal on AKS with GitHub OAuth or Microsoft Entra ID, Golden Paths, and TechDocs. USE FOR: deploy Backstage, configure Backstage auth, register Golden Paths, setup TechDocs, Backstage on AKS."
agent: "backstage-expert"
---

# Deploy Backstage Portal

Deploy the upstream open-source Backstage developer portal to Azure AKS.

## MCP Tools Available
Before configuring, consult official Backstage documentation via MCP ecosystem tools:
- `backstagedocs_search` — search Backstage docs by keyword
- `backstagedocs_get_page` — get specific doc page by slug
- `backstagedocs_get_catalog` — Software Catalog documentation
- `backstagedocs_get_software_templates` — Scaffolder/Templates documentation

## Input

- **Environment**: Target environment (dev, staging, prod)
- **Auth**: GitHub OAuth, Microsoft Entra ID, or Guest (dev only)
- **GitHub identity mode**: `standard`, `saml-sso`, or `enterprise-managed-users`
- **Components**: Portal + Golden Paths + TechDocs

## Expected Output

- Backstage running on AKS with ingress
- Selected auth provider configured
- GitHub App/token integration configured where GitHub-backed catalog, scaffolder, Actions, PRs, Codespaces, packages, or AI Impact features are enabled
- Golden Path templates registered in catalog
