# Defender for Cloud Module

Microsoft Defender for Cloud with comprehensive security posture management.

## Features

- Defender CSPM (Cloud Security Posture Management)
- Defender for Containers
- Defender for Servers (P1/P2)
- Defender for Databases (SQL, PostgreSQL, Cosmos DB)
- Defender for Key Vault, Storage, App Service, DNS, ARM
- Defender for AI (preview)
- Regulatory compliance (CIS, NIST, PCI DSS, ISO 27001, LGPD)
- Governance rules for auto-remediation
- Continuous export to Log Analytics
- Just-in-time VM access (xlarge profile)

## Sizing Profiles

| Profile | CSPM | Servers | Cost/Month |
|---------|------|---------|------------|
| small | Free | Free | ~$100 |
| medium | Standard | P1 | ~$500 |
| large | Standard | P2 | ~$2,000 |
| xlarge | Standard | P2 + JIT | ~$5,000 |

## Usage

```hcl
module "defender" {
  source = "./modules/defender"

  customer_name   = "threehorizons"
  environment     = "prod"
  sizing_profile  = "large"
  subscription_id = data.azurerm_subscription.current.subscription_id

  security_contact_email = "security@example.com"
  security_contact_phone = "+1234567890"

  log_analytics_workspace_id = module.observability.log_analytics_workspace_id

  # AKS cluster integration
  aks_cluster_ids = [module.aks.cluster_id]

  # Regulatory compliance
  regulatory_compliance_standards = [
    "Azure-CIS-1.4.0",
    "NIST-SP-800-53-Rev5",
    "PCI-DSS-4.0",
    "ISO-27001-2013",
    "LGPD"
  ]

  # Governance rules
  governance_rules = [
    {
      name             = "Critical-30days"
      description      = "Remediate critical findings within 30 days"
      severity         = "High"
      grace_period_days = 30
    }
  ]

  # Auto-provisioning
  auto_provisioning_settings = {
    log_analytics_agent = true
  }

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
| azapi | ~> 1.9 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| sizing_profile | Sizing profile (small, medium, large, xlarge) | `string` | `"medium"` | no |
| subscription_id | Azure subscription ID | `string` | n/a | yes |
| security_contact_email | Security contact email | `string` | n/a | yes |
| security_contact_phone | Security contact phone | `string` | `""` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | n/a | yes |
| aks_cluster_ids | AKS cluster IDs for Defender | `list(string)` | `[]` | no |
| regulatory_compliance_standards | Compliance standards to enable | `list(string)` | `[]` | no |
| governance_rules | Governance rules for remediation | `list(object)` | `[]` | no |
| auto_provisioning_settings | Auto-provisioning settings | `object` | n/a | no |
| enable_jit_access | Enable JIT VM access | `bool` | `false` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| security_contact_id | Security contact resource ID |
| cspm_tier | CSPM pricing tier |
| containers_tier | Containers pricing tier |
| servers_tier | Servers pricing tier |
| compliance_standards | Enabled compliance standards |

## Compliance Standards

Available compliance frameworks:
- Azure-CIS-1.4.0
- NIST-SP-800-53-Rev5
- PCI-DSS-4.0
- ISO-27001-2013
- SOC-2-Type-2
- LGPD (Brazil data protection)

## Continuous Export

Automatically exports to Log Analytics:
- High and Medium severity alerts
- Secure scores
- Secure score controls
- Regulatory compliance assessments
