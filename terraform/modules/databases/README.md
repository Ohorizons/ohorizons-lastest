# Databases Module

Managed database services including PostgreSQL Flexible Server and Azure Cache for Redis.

## Features

- Azure Database for PostgreSQL Flexible Server
- Azure Cache for Redis
- Private endpoint connectivity
- High availability configuration
- Automated backups with geo-redundancy
- Azure AD authentication
- Key Vault secrets integration
- Performance tuning configurations

## Usage

```hcl
module "databases" {
  source = "./modules/databases"

  customer_name       = "threehorizons"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  subnet_id    = module.networking.postgresql_subnet_id
  key_vault_id = module.security.key_vault_id

  private_dns_zone_ids = {
    postgres = module.networking.private_dns_zone_ids["privatelink.postgres.database.azure.com"]
    redis    = module.networking.private_dns_zone_ids["privatelink.redis.cache.windows.net"]
  }

  postgresql_config = {
    enabled                = true
    version                = "15"
    sku_name               = "GP_Standard_D4s_v3"
    storage_mb             = 131072
    admin_username         = "pgadmin"
    backup_retention_days  = 35
    geo_redundant_backup   = true
    high_availability      = true
    databases              = ["backstage", "argocd", "app"]
  }

  redis_config = {
    enabled             = true
    sku_name            = "Premium"
    family              = "P"
    capacity            = 1
    enable_non_ssl_port = false
    minimum_tls_version = "1.2"
    maxmemory_policy    = "volatile-lru"
  }

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
| random | ~> 3.5 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| subnet_id | Subnet ID for PostgreSQL | `string` | n/a | yes |
| key_vault_id | Key Vault ID for secrets | `string` | n/a | yes |
| private_dns_zone_ids | Map of private DNS zone IDs | `map(string)` | n/a | yes |
| postgresql_config | PostgreSQL configuration | `object` | n/a | yes |
| redis_config | Redis configuration | `object` | n/a | yes |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| postgresql_fqdn | PostgreSQL server FQDN |
| postgresql_id | PostgreSQL server ID |
| redis_hostname | Redis hostname |
| redis_ssl_port | Redis SSL port |
| redis_id | Redis cache ID |

## PostgreSQL Configuration

The module applies performance-tuned settings:
- `shared_preload_libraries`: pg_stat_statements
- `work_mem`: 32MB
- `maintenance_work_mem`: 512MB
- `effective_cache_size`: 1.5GB
- Query logging for slow queries (>1s)

## High Availability

When `high_availability = true`:
- Zone-redundant standby replica
- Automatic failover
- Maintenance window on Sundays at 3 AM

## Secrets

Credentials stored in Key Vault:
- `postgresql-connection-string`
- `postgresql-admin-password`
- `redis-connection-string`
- `redis-primary-key`
