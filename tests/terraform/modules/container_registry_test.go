// =============================================================================
// OPEN HORIZONS PLATFORM - CONTAINER REGISTRY MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform container registry module.
//
// Run with: go test -v -run TestContainerRegistry ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestContainerRegistryModuleBasic tests basic ACR configuration
func TestContainerRegistryModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/container-registry",
		Vars: map[string]interface{}{
			"customer_name":                   "testacr",
			"environment":                     "dev",
			"location":                        "brazilsouth",
			"resource_group_name":             "rg-test-acr",
			"sku":                             "Premium",
			"subnet_id":                       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_id":             "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
			"aks_kubelet_identity_object_id":  "00000000-0000-0000-0000-000000000001",
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

	// Verify ACR is planned
	assert.Contains(t, planOutput, "azurerm_container_registry.main")
}

// TestContainerRegistryModuleSKUs tests different SKU configurations
func TestContainerRegistryModuleSKUs(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name string
		sku  string
	}{
		{"basic", "Basic"},
		{"standard", "Standard"},
		{"premium", "Premium"},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/container-registry",
				Vars: map[string]interface{}{
					"customer_name":                  "skutest",
					"environment":                    "dev",
					"location":                       "brazilsouth",
					"resource_group_name":            "rg-test-sku-" + tc.name,
					"sku":                            tc.sku,
					"subnet_id":                      "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"private_dns_zone_id":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
					"aks_kubelet_identity_object_id": "00000000-0000-0000-0000-000000000001",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, "azurerm_container_registry.main")
		})
	}
}

// TestContainerRegistryModuleNaming tests ACR naming convention
func TestContainerRegistryModuleNaming(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/container-registry",
		Vars: map[string]interface{}{
			"customer_name":                  "nametest",
			"environment":                    "dev",
			"location":                       "brazilsouth",
			"resource_group_name":            "rg-test-naming",
			"sku":                            "Premium",
			"subnet_id":                      "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_id":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
			"aks_kubelet_identity_object_id": "00000000-0000-0000-0000-000000000001",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// ACR names must be alphanumeric only (no hyphens)
	assert.Contains(t, planOutput, "crnametestdev")
}

// TestContainerRegistryModuleGeoReplication tests geo-replication
func TestContainerRegistryModuleGeoReplication(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/container-registry",
		Vars: map[string]interface{}{
			"customer_name":                  "georep",
			"environment":                    "prod",
			"location":                       "brazilsouth",
			"resource_group_name":            "rg-test-georep",
			"sku":                            "Premium",
			"subnet_id":                      "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_id":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
			"aks_kubelet_identity_object_id": "00000000-0000-0000-0000-000000000001",
			"geo_replication_locations":      []string{"eastus", "westeurope"},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify geo-replication is planned for Premium SKU
	assert.Contains(t, planOutput, "azurerm_container_registry_replication")
}

// TestContainerRegistryModulePrivateEndpoint tests private endpoint
func TestContainerRegistryModulePrivateEndpoint(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/container-registry",
		Vars: map[string]interface{}{
			"customer_name":                  "petest",
			"environment":                    "prod",
			"location":                       "brazilsouth",
			"resource_group_name":            "rg-test-pe",
			"sku":                            "Premium",
			"subnet_id":                      "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_id":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
			"aks_kubelet_identity_object_id": "00000000-0000-0000-0000-000000000001",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify private endpoint is planned
	assert.Contains(t, planOutput, "azurerm_private_endpoint.acr")
}

// TestContainerRegistryModuleRBAC tests RBAC role assignments
func TestContainerRegistryModuleRBAC(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/container-registry",
		Vars: map[string]interface{}{
			"customer_name":                  "rbactest",
			"environment":                    "dev",
			"location":                       "brazilsouth",
			"resource_group_name":            "rg-test-rbac",
			"sku":                            "Premium",
			"subnet_id":                      "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"private_dns_zone_id":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
			"aks_kubelet_identity_object_id": "00000000-0000-0000-0000-000000000001",
			"github_actions_identity_ids":    []string{"00000000-0000-0000-0000-000000000002"},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify role assignments are planned
	assert.Contains(t, planOutput, "azurerm_role_assignment.aks_acr_pull")
	assert.Contains(t, planOutput, "azurerm_role_assignment.github_actions_push")
}

// TestContainerRegistryModuleWebhook tests optional webhook configuration
func TestContainerRegistryModuleWebhook(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name          string
		enableWebhook bool
		webhookURI    string
		expectWebhook bool
	}{
		{"webhook_disabled", false, "", false},
		{"webhook_enabled", true, "https://example.com/webhook", true},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/container-registry",
				Vars: map[string]interface{}{
					"customer_name":                  "whtest",
					"environment":                    "dev",
					"location":                       "brazilsouth",
					"resource_group_name":            "rg-test-wh",
					"sku":                            "Premium",
					"subnet_id":                      "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"private_dns_zone_id":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
					"aks_kubelet_identity_object_id": "00000000-0000-0000-0000-000000000001",
					"enable_webhook":                 tc.enableWebhook,
					"webhook_service_uri":            tc.webhookURI,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			if tc.expectWebhook {
				assert.Contains(t, planOutput, "azurerm_container_registry_webhook")
			} else {
				assert.NotContains(t, planOutput, "azurerm_container_registry_webhook.image_push[0]")
			}
		})
	}
}

// TestContainerRegistryModuleEnvironments tests different environments
func TestContainerRegistryModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/container-registry",
				Vars: map[string]interface{}{
					"customer_name":                  "envtest",
					"environment":                    env,
					"location":                       "brazilsouth",
					"resource_group_name":            "rg-test-acr-" + env,
					"sku":                            "Premium",
					"subnet_id":                      "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"private_dns_zone_id":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/acr",
					"aks_kubelet_identity_object_id": "00000000-0000-0000-0000-000000000001",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
