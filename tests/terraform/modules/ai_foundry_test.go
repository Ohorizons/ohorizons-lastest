// =============================================================================
// OPEN HORIZONS PLATFORM - AI FOUNDRY MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform AI Foundry module.
//
// Run with: go test -v -run TestAIFoundry ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestAIFoundryModuleBasic tests basic AI Foundry configuration
func TestAIFoundryModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/ai-foundry",
		Vars: map[string]interface{}{
			"customer_name":               "testai",
			"environment":                 "dev",
			"location":                    "eastus",
			"resource_group_name":         "rg-test-ai",
			"subnet_id":                   "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":                "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"log_analytics_workspace_id":  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
			"private_dns_zone_ids": map[string]interface{}{
				"openai":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/openai",
				"cognitiveservices": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/cognitive",
				"search":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/search",
			},
			"openai_config": map[string]interface{}{
				"enabled":  true,
				"sku_name": "S0",
				"models": []map[string]interface{}{
					{
						"name":          "gpt-4o",
						"model_name":    "gpt-4o",
						"model_version": "2024-05-13",
						"capacity":      30,
						"rai_policy":    "DefaultRaiPolicy",
					},
				},
			},
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

	// Verify Azure OpenAI is planned
	assert.Contains(t, planOutput, "azurerm_cognitive_account.openai")
}

// TestAIFoundryModuleOpenAI tests Azure OpenAI configuration
func TestAIFoundryModuleOpenAI(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/ai-foundry",
		Vars: map[string]interface{}{
			"customer_name":              "oaitest",
			"environment":                "dev",
			"location":                   "eastus",
			"resource_group_name":        "rg-test-oai",
			"subnet_id":                  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":               "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"log_analytics_workspace_id": "",
			"private_dns_zone_ids": map[string]interface{}{
				"openai":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/openai",
				"cognitiveservices": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/cognitive",
				"search":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/search",
			},
			"openai_config": map[string]interface{}{
				"enabled":  true,
				"sku_name": "S0",
				"models":   []map[string]interface{}{},
			},
			"ai_search_config": map[string]interface{}{
				"enabled": false,
			},
			"content_safety_config": map[string]interface{}{
				"enabled": false,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify OpenAI naming convention
	assert.Contains(t, planOutput, "oai-")
}

// TestAIFoundryModuleAISearch tests AI Search configuration
func TestAIFoundryModuleAISearch(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/ai-foundry",
		Vars: map[string]interface{}{
			"customer_name":              "srchtest",
			"environment":                "dev",
			"location":                   "eastus",
			"resource_group_name":        "rg-test-search",
			"subnet_id":                  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":               "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"log_analytics_workspace_id": "",
			"private_dns_zone_ids": map[string]interface{}{
				"openai":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/openai",
				"cognitiveservices": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/cognitive",
				"search":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/search",
			},
			"openai_config": map[string]interface{}{
				"enabled": false,
			},
			"ai_search_config": map[string]interface{}{
				"enabled":                       true,
				"sku_name":                      "standard",
				"replica_count":                 1,
				"partition_count":               1,
				"public_network_access_enabled": false,
				"semantic_search_sku":           "standard",
			},
			"content_safety_config": map[string]interface{}{
				"enabled": false,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify AI Search is planned
	assert.Contains(t, planOutput, "azurerm_search_service.main")
}

// TestAIFoundryModuleContentSafety tests Content Safety configuration
func TestAIFoundryModuleContentSafety(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/ai-foundry",
		Vars: map[string]interface{}{
			"customer_name":              "cstest",
			"environment":                "dev",
			"location":                   "eastus",
			"resource_group_name":        "rg-test-cs",
			"subnet_id":                  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":               "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"log_analytics_workspace_id": "",
			"private_dns_zone_ids": map[string]interface{}{
				"openai":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/openai",
				"cognitiveservices": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/cognitive",
				"search":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/search",
			},
			"openai_config": map[string]interface{}{
				"enabled": false,
			},
			"ai_search_config": map[string]interface{}{
				"enabled": false,
			},
			"content_safety_config": map[string]interface{}{
				"enabled":  true,
				"sku_name": "S0",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify Content Safety is planned
	assert.Contains(t, planOutput, "azurerm_cognitive_account.content_safety")
}

// TestAIFoundryModulePrivateEndpoints tests private endpoint creation
func TestAIFoundryModulePrivateEndpoints(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/ai-foundry",
		Vars: map[string]interface{}{
			"customer_name":              "petest",
			"environment":                "prod",
			"location":                   "eastus",
			"resource_group_name":        "rg-test-ai-pe",
			"subnet_id":                  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"key_vault_id":               "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"log_analytics_workspace_id": "",
			"private_dns_zone_ids": map[string]interface{}{
				"openai":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/openai",
				"cognitiveservices": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/cognitive",
				"search":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/search",
			},
			"openai_config": map[string]interface{}{
				"enabled":  true,
				"sku_name": "S0",
				"models":   []map[string]interface{}{},
			},
			"ai_search_config": map[string]interface{}{
				"enabled": false,
			},
			"content_safety_config": map[string]interface{}{
				"enabled": false,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify private endpoints are planned
	assert.Contains(t, planOutput, "azurerm_private_endpoint.openai")
}

// TestAIFoundryModuleEnvironments tests different environments
func TestAIFoundryModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/ai-foundry",
				Vars: map[string]interface{}{
					"customer_name":              "aienv",
					"environment":                env,
					"location":                   "eastus",
					"resource_group_name":        "rg-test-ai-" + env,
					"subnet_id":                  "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"key_vault_id":               "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
					"log_analytics_workspace_id": "",
					"private_dns_zone_ids": map[string]interface{}{
						"openai":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/openai",
						"cognitiveservices": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/cognitive",
						"search":            "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/search",
					},
					"openai_config": map[string]interface{}{
						"enabled": false,
					},
					"ai_search_config": map[string]interface{}{
						"enabled": false,
					},
					"content_safety_config": map[string]interface{}{
						"enabled": false,
					},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
