---
name: database-management
description: "Database operations and health monitoring. USE FOR: PostgreSQL health check, database backup, database restore, connection string, database migration, database monitoring. DO NOT USE FOR: Azure infrastructure provisioning (use azure-cli), Terraform IaC (use terraform-cli), application code (use @devops)."
---

## When to Use
- Database health checks
- Connection verification
- Performance monitoring
- Backup status verification

## Prerequisites
- Azure CLI for Azure databases
- psql for PostgreSQL operations
- Appropriate database credentials

## Commands

### Azure PostgreSQL
```bash
# List PostgreSQL servers
az postgres flexible-server list -o table

# Show server details
az postgres flexible-server show --name <server> --resource-group <rg>

# Check firewall rules
az postgres flexible-server firewall-rule list --name <server> --resource-group <rg>

# Check backup retention
az postgres flexible-server show --name <server> --resource-group <rg> --query "backup"
```

### Connection Testing
```bash
# Test PostgreSQL connection
psql "host=<host> dbname=<db> user=<user> sslmode=require" -c "SELECT version();"

# Check active connections
psql -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"
```

### Health Monitoring
```bash
# Check database size
psql -c "SELECT pg_size_pretty(pg_database_size(current_database()));"

# Check table sizes
psql -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
         FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"
```

## Best Practices
1. Use private endpoints for database connectivity
2. Enable SSL/TLS for all connections
3. Configure automated backups
4. Monitor connection pool usage
5. Set up alerts for high CPU/memory

## Output Format
1. Command executed
2. Database status summary
3. Any issues detected
4. Recommendations

## Integration with Agents
Used by: @terraform, @sre, @test
