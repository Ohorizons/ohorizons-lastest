// =============================================================================
// OPEN HORIZONS PLATFORM - DATABASES MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform databases module.
//
// Run with: go test -v -run TestDatabases ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestDatabasesModuleBasic tests basic databases module configuration
func TestDatabasesModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/databases",
		Vars: map[string]interface{}{
			"customer_name":       "testdb",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-databases",
			"subnet_id":           "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-db",
			"key_vault_id":        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test",
			"private_dns_zone_ids": map[string]interface{}{
				"postgres": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com",
				"redis":    "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/privatelink.redis.cache.windows.net",
			},
			"enable_postgresql": true,
			"enable_redis":      true,
			"enable_cosmosdb":   false,
			"tags": map[string]interface{}{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)

	planOutput := terraform.Plan(t, terraformOptions)

	// Verify PostgreSQL and Redis are planned
	assert.Contains(t, planOutput, "azurerm_postgresql_flexible_server")
	assert.Contains(t, planOutput, "azurerm_redis_cache")
}

// TestDatabasesModulePostgreSQLConfig tests PostgreSQL configuration
func TestDatabasesModulePostgreSQLConfig(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/databases",
		Vars: map[string]interface{}{
			"customer_name":       "psqltest",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-psql",
			"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"private_dns_zone_ids": map[string]interface{}{
				"postgres": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/postgres",
			},
			"enable_postgresql": true,
			"enable_redis":      false,
			"postgresql_config": map[string]interface{}{
				"sku_name":         "GP_Standard_D2s_v3",
				"version":          "15",
				"storage_mb":       32768,
				"backup_retention": 7,
				"geo_redundant":    false,
				"high_availability": false,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify PostgreSQL configuration
	assert.Contains(t, planOutput, "azurerm_postgresql_flexible_server")
	assert.Contains(t, planOutput, "psql-")
}

// TestDatabasesModuleRedisConfig tests Redis configuration
func TestDatabasesModuleRedisConfig(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name     string
		sku      string
		family   string
		capacity int
	}{
		{"basic", "Basic", "C", 0},
		{"standard", "Standard", "C", 1},
		{"premium", "Premium", "P", 1},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/databases",
				Vars: map[string]interface{}{
					"customer_name":       "redistest",
					"environment":         "dev",
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-redis",
					"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
					"private_dns_zone_ids": map[string]interface{}{
						"redis": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/redis",
					},
					"enable_postgresql": false,
					"enable_redis":      true,
					"redis_config": map[string]interface{}{
						"sku_name": tc.sku,
						"family":   tc.family,
						"capacity": tc.capacity,
					},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, "azurerm_redis_cache")
		})
	}
}

// TestDatabasesModuleCosmosDB tests Cosmos DB configuration
func TestDatabasesModuleCosmosDB(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/databases",
		Vars: map[string]interface{}{
			"customer_name":       "cosmostest",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-cosmos",
			"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"private_dns_zone_ids": map[string]interface{}{
				"cosmosdb": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/cosmos",
			},
			"enable_postgresql": false,
			"enable_redis":      false,
			"enable_cosmosdb":   true,
			"cosmosdb_config": map[string]interface{}{
				"offer_type":  "Standard",
				"kind":        "MongoDB",
				"consistency": "Session",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify Cosmos DB is planned when enabled
	assert.Contains(t, planOutput, "azurerm_cosmosdb_account")
}

// TestDatabasesModulePrivateEndpoints tests private endpoint creation
func TestDatabasesModulePrivateEndpoints(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/databases",
		Vars: map[string]interface{}{
			"customer_name":       "petest",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-pe",
			"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"private_dns_zone_ids": map[string]interface{}{
				"postgres": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/postgres",
			},
			"enable_postgresql": true,
			"enable_redis":      false,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify private endpoints are planned
	assert.Contains(t, planOutput, "azurerm_private_endpoint")
}

// TestDatabasesModuleEnvironments tests different environment configurations
func TestDatabasesModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/databases",
				Vars: map[string]interface{}{
					"customer_name":       "dbenv",
					"environment":         env,
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-db-" + env,
					"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
					"private_dns_zone_ids": map[string]interface{}{
						"postgres": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/postgres",
					},
					"enable_postgresql": true,
					"enable_redis":      false,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
