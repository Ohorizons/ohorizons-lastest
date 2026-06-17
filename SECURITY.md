# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 4.x     | :white_check_mark: |
| 3.x     | :x:                |
| < 3.0   | :x:                |

## Security Standards

The Open Horizons Platform follows enterprise security best practices:

### Authentication & Authorization
- **Workload Identity**: All AKS workloads use Azure Workload Identity
- **Managed Identity**: All Azure services use Managed Identity
- **No Service Principal Secrets**: Service principal keys are prohibited
- **RBAC**: Role-Based Access Control with least privilege principle
- **MFA**: Multi-factor authentication required for all human accounts

### Network Security
- **Private Endpoints**: All PaaS services use private endpoints
- **NSG**: Network Security Groups with deny-by-default rules
- **Azure Firewall**: Egress filtering for production environments
- **DDoS Protection**: Enabled for production workloads
- **TLS 1.3**: Minimum TLS version for all communications

### Data Protection
- **Encryption at Rest**: All data encrypted using Azure managed keys
- **Encryption in Transit**: TLS 1.3 for all network traffic
- **Key Vault**: All secrets stored in Azure Key Vault
- **Data Classification**: Support for LGPD, SOC 2, PCI-DSS compliance

### Container Security
- **Minimal Base Images**: Use distroless or minimal base images
- **Non-Root**: All containers run as non-root user
- **Read-Only Filesystem**: Root filesystem is read-only
- **Pod Security Standards**: Restricted policy enforced
- **Image Scanning**: All images scanned before deployment

### CI/CD Security
- **Secret Scanning**: Gitleaks runs on every push
- **Dependency Scanning**: Dependabot and Trivy for vulnerability detection
- **SAST**: Static analysis on all code changes
- **Infrastructure Scanning**: tfsec for Terraform code
- **Signed Commits**: GPG-signed commits recommended

## Reporting a Vulnerability

### How to Report

If you discover a security vulnerability, please report it responsibly:

1. **DO NOT** create a public GitHub issue
2. Email security concerns to: security@your-organization.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested remediation (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Resolution Timeline**: Based on severity
  - Critical: 24-48 hours
  - High: 7 days
  - Medium: 30 days
  - Low: 90 days

### Severity Classification

| Severity | Description | Examples |
|----------|-------------|----------|
| Critical | Immediate exploitation risk | RCE, credential exposure, data breach |
| High | Significant risk | Privilege escalation, authentication bypass |
| Medium | Moderate risk | Information disclosure, SSRF |
| Low | Minor risk | Verbose errors, minor misconfigurations |

## Security Contacts

- **Security Team**: @security-team
- **Platform Team**: @platform-team
- **Emergency Contact**: security-emergency@your-organization.com

## Security Tools

The following security tools are integrated:

| Tool | Purpose | Integration |
|------|---------|-------------|
| Gitleaks | Secret detection | CI pipeline |
| Trivy | Container scanning | CI pipeline |
| tfsec | Terraform scanning | CI pipeline |
| Kubesec | Kubernetes scanning | CI pipeline |
| Defender for Cloud | Runtime protection | Azure |
| Azure Policy | Governance | Azure |

## Compliance

This accelerator supports compliance with:

- **LGPD** (Lei Geral de Proteção de Dados)
- **SOC 2** Type II
- **PCI-DSS** (when applicable)
- **CIS Benchmarks** for Azure and Kubernetes
- **Azure Security Baseline**

## Security Checklist for Contributors

Before submitting code:

- [ ] No secrets or credentials in code
- [ ] Input validation implemented
- [ ] Error messages don't expose sensitive info
- [ ] Logging doesn't include PII or secrets
- [ ] Dependencies are up to date
- [ ] Security scanning passes
- [ ] RBAC follows least privilege
- [ ] Network access is restricted

## Acknowledgments

We appreciate the security research community's efforts in responsibly disclosing vulnerabilities. Contributors who report valid security issues will be acknowledged (with permission) in our security hall of fame.

---

## Security Findings in This Template — What Customers Should Do

Open Horizons is published as a **forkable template**. After forking, the GitHub Security tab on your fork will show alerts inherited from this repository. Below is the policy and the actions you should take.

### What you will see

| Source | Typical count | Why it appears |
|---|---|---|
| **Dependabot** (transitive npm/pip deps) | 50–150 | Backstage and FastAPI bring large dependency trees; many findings are in dev/test deps that never reach production runtime. |
| **CodeQL / Trivy IaC** (Checkov rules) | 80–120 | The default Terraform modules optimize for "wizard works out of the box". Hardening (private cluster, CMK encryption, geo-redundancy) is gated behind size profiles. |
| **Container scan (Trivy)** | 5–30 per image | Base images receive new CVE disclosures continuously. Re-tagging triggers rebuilds with patched bases. |
| **Secret scanning** | 0 | The repo passes secret scanning + push protection. |

### Actions on fork

1. **Update the platform** as soon as you fork:
   ```bash
   # NPM transitive deps (auto-merged Dependabot PRs)
   yarn install && yarn upgrade-interactive
   # Python deps (in agent APIs)
   cd backstage/server/agent-api && pip install -U -r requirements.txt
   ```
2. **Enable Dependabot version updates** (already configured in `.github/dependabot.yml`) so PRs land continuously.
3. **Enable GitHub Advanced Security** on your fork to use code scanning and secret scanning at scale.
4. **Re-build & re-tag** the platform images on a schedule (daily or weekly) using the `release-images` workflow — Trivy base-image findings disappear when patched bases are pulled.
5. **Review IaC suppressions** in [`.checkov.yaml`](.checkov.yaml). Each suppressed rule includes rationale; promote a suppression to "enforced" in your fork when you adopt the corresponding hardening (e.g. `private_cluster=true`).
6. **Adopt size profile** matching your environment (see [`config/sizing-profiles.yaml`](config/sizing-profiles.yaml)) — Large/XLarge automatically enable many controls that are off by default in Small/Medium.

### Suppressions in this template

We deliberately suppress IaC rules where the platform leaves a hardening decision to the customer. The full list with per-rule rationale is in [`.checkov.yaml`](.checkov.yaml) and [`.trivyignore`](.trivyignore). Examples:

- AKS API server is **public by default** so the install wizard can complete without VPN/Bastion. Customers should set `private_cluster: true` for production.
- ACR public network access is **on by default** for initial image pulls. Toggle to private endpoint via the install wizard.
- Storage accounts use **Microsoft-managed keys** by default; switch to CMK in production via the wizard's "BYOK" flag.

### Reporting issues with a customer fork

If you discover a vulnerability that affects every fork (i.e. in this upstream template), please report through the [GitHub Security Advisory](https://github.com/Ohorizons/open-horizons-platform/security/advisories) workflow. Do not open a public issue.
