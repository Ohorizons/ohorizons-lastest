// =============================================================================
// OPEN HORIZONS PLATFORM - PURVIEW MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform Microsoft Purview module.
//
// Run with: go test -v -run TestPurview ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestPurviewModuleBasic tests basic Purview configuration
func TestPurviewModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/purview",
		Vars: map[string]interface{}{
			"customer_name":       "testpurv",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-purview",
			"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_ids": map[string]interface{}{
				"purview":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purview",
				"purview_studio": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purviewstudio",
				"storage_blob":   "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/blob",
				"storage_queue":  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/queue",
				"servicebus":     "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/servicebus",
				"eventhub":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/eventhub",
			},
			"admin_group_id": "00000000-0000-0000-0000-000000000000",
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

	// Verify Purview account is planned
	assert.Contains(t, planOutput, "azurerm_purview_account")
}

// TestPurviewModuleSizingProfiles tests different sizing profiles
func TestPurviewModuleSizingProfiles(t *testing.T) {
	t.Parallel()

	profiles := []string{"small", "medium", "large", "xlarge"}

	for _, profile := range profiles {
		profile := profile
		t.Run(profile, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/purview",
				Vars: map[string]interface{}{
					"customer_name":       "sizetest",
					"environment":         "prod",
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-purview-" + profile,
					"sizing_profile":      profile,
					"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"private_dns_zone_ids": map[string]interface{}{
						"purview":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purview",
						"purview_studio": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purviewstudio",
						"storage_blob":   "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/blob",
						"storage_queue":  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/queue",
						"servicebus":     "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/servicebus",
						"eventhub":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/eventhub",
					},
					"admin_group_id": "00000000-0000-0000-0000-000000000000",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestPurviewModuleDataSources tests data source registration
func TestPurviewModuleDataSources(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/purview",
		Vars: map[string]interface{}{
			"customer_name":       "dstest",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-purview-ds",
			"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_ids": map[string]interface{}{
				"purview":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purview",
				"purview_studio": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purviewstudio",
				"storage_blob":   "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/blob",
				"storage_queue":  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/queue",
				"servicebus":     "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/servicebus",
				"eventhub":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/eventhub",
			},
			"admin_group_id": "00000000-0000-0000-0000-000000000000",
			"data_sources": []map[string]interface{}{
				{
					"name":           "storage-account-1",
					"type":           "AzureBlobStorage",
					"resource_id":    "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/st1",
					"scan_frequency": "Weekly",
				},
				{
					"name":           "sql-database-1",
					"type":           "AzureSqlDatabase",
					"resource_id":    "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Sql/servers/sql1/databases/db1",
					"scan_frequency": "Daily",
				},
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify data sources are configured
	assert.Contains(t, planOutput, "purview")
}

// TestPurviewModuleLATAMClassifications tests LATAM-specific classifications
func TestPurviewModuleLATAMClassifications(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		enabled bool
	}{
		{"latam_enabled", true},
		{"latam_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/purview",
				Vars: map[string]interface{}{
					"customer_name":       "latamtest",
					"environment":         "prod",
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-purview-latam",
					"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"private_dns_zone_ids": map[string]interface{}{
						"purview":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purview",
						"purview_studio": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purviewstudio",
						"storage_blob":   "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/blob",
						"storage_queue":  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/queue",
						"servicebus":     "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/servicebus",
						"eventhub":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/eventhub",
					},
					"admin_group_id":                "00000000-0000-0000-0000-000000000000",
					"enable_latam_classifications": tc.enabled,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestPurviewModuleCollectionHierarchy tests collection structure
func TestPurviewModuleCollectionHierarchy(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/purview",
		Vars: map[string]interface{}{
			"customer_name":       "colltest",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-purview-coll",
			"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_ids": map[string]interface{}{
				"purview":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purview",
				"purview_studio": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purviewstudio",
				"storage_blob":   "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/blob",
				"storage_queue":  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/queue",
				"servicebus":     "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/servicebus",
				"eventhub":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/eventhub",
			},
			"admin_group_id": "00000000-0000-0000-0000-000000000000",
			"collection_hierarchy": []map[string]interface{}{
				{"name": "H1-Foundation", "parent": "", "description": "Foundation infrastructure assets"},
				{"name": "H2-Enhancement", "parent": "", "description": "Enhanced platform assets"},
				{"name": "H3-Innovation", "parent": "", "description": "AI/ML innovation assets"},
				{"name": "Databases", "parent": "H1-Foundation", "description": "Database assets"},
				{"name": "Storage", "parent": "H1-Foundation", "description": "Storage assets"},
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify collection hierarchy is planned
	assert.Contains(t, planOutput, "purview")
}

// TestPurviewModuleEnvironments tests different environments
func TestPurviewModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/purview",
				Vars: map[string]interface{}{
					"customer_name":       "envtest",
					"environment":         env,
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-purview-" + env,
					"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"private_dns_zone_ids": map[string]interface{}{
						"purview":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purview",
						"purview_studio": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/purviewstudio",
						"storage_blob":   "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/blob",
						"storage_queue":  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/queue",
						"servicebus":     "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/servicebus",
						"eventhub":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/eventhub",
					},
					"admin_group_id": "00000000-0000-0000-0000-000000000000",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
