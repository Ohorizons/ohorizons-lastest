# Disaster Recovery Module

Azure Disaster Recovery configuration with backup policies and site recovery.

## Features

- Recovery Services Vault with geo-redundancy
- VM backup policies (daily, weekly)
- Azure Files backup policies
- Azure Site Recovery for regional failover
- Replication policies with RPO configuration
- Network mapping for DR
- Cross-region restore capability
- Immutable backups for compliance
- Monitoring and alerts

## Usage

```hcl
module "disaster_recovery" {
  source = "./modules/disaster-recovery"

  customer_name               = "threehorizons"
  environment                 = "prod"
  primary_resource_group_name = azurerm_resource_group.main.name
  primary_location            = "eastus2"
  primary_region_short        = "eus2"

  # DR region
  dr_location      = "brazilsouth"
  dr_region_short  = "brso"

  # Recovery objectives
  recovery_point_objective = "1h"
  recovery_time_objective  = "4h"

  # Storage redundancy
  storage_redundancy            = "GeoRedundant"
  enable_cross_region_restore   = true
  enable_immutability           = true

  # Retention settings
  retention_daily_count   = 30
  retention_weekly_count  = 12
  retention_monthly_count = 12
  retention_yearly_count  = 1
  instant_restore_days    = 5

  # Site Recovery
  enable_site_recovery = true
  primary_vnet_id      = module.networking.vnet_id
  dr_vnet_id           = module.networking_dr.vnet_id

  replication_recovery_point_retention_minutes = 1440  # 24 hours
  app_consistent_snapshot_frequency_minutes    = 60

  # Monitoring
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  enable_alerts              = true
  action_group_id            = module.observability.action_group_id

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| primary_resource_group_name | Primary region resource group | `string` | n/a | yes |
| primary_location | Primary Azure region | `string` | n/a | yes |
| primary_region_short | Primary region short name | `string` | n/a | yes |
| dr_location | DR Azure region | `string` | n/a | yes |
| dr_region_short | DR region short name | `string` | n/a | yes |
| recovery_point_objective | Target RPO | `string` | `"1h"` | no |
| recovery_time_objective | Target RTO | `string` | `"4h"` | no |
| storage_redundancy | Vault storage type | `string` | `"GeoRedundant"` | no |
| enable_cross_region_restore | Enable cross-region restore | `bool` | `true` | no |
| enable_immutability | Enable immutable backups | `bool` | `false` | no |
| retention_daily_count | Daily backup retention | `number` | `30` | no |
| retention_weekly_count | Weekly backup retention | `number` | `12` | no |
| retention_monthly_count | Monthly backup retention | `number` | `12` | no |
| retention_yearly_count | Yearly backup retention | `number` | `0` | no |
| instant_restore_days | Instant restore retention | `number` | `5` | no |
| enable_site_recovery | Enable Azure Site Recovery | `bool` | `false` | no |
| primary_vnet_id | Primary VNet ID | `string` | `null` | no |
| dr_vnet_id | DR VNet ID | `string` | `null` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |
| enable_alerts | Enable backup alerts | `bool` | `true` | no |
| action_group_id | Action group for alerts | `string` | `null` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vault_id | Recovery Services Vault ID |
| vault_name | Recovery Services Vault name |
| daily_policy_id | Daily backup policy ID |
| weekly_policy_id | Weekly backup policy ID |
| fileshare_policy_id | File share backup policy ID |
| dr_cache_storage_id | DR cache storage account ID |

## Backup Policies

**VM Daily Policy:**
- Backup: Daily at 23:00
- Retention: 30 daily, 12 weekly, 12 monthly, 1 yearly

**VM Weekly Policy:**
- Backup: Weekly on Sunday at 23:00
- Retention: 24 weekly, 12 monthly

**File Share Policy:**
- Backup: Daily at 23:00
- Retention: 30 daily, 12 weekly, 12 monthly

## Site Recovery

When enabled, configures:
- Fabrics for primary and DR regions
- Protection containers
- Replication policy with configured RPO
- Container mappings (bidirectional)
- Network mappings for failover
- Cache storage account for replication
