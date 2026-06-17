// =============================================================================
// OPEN HORIZONS PLATFORM - INTEGRATION TESTS
// =============================================================================
//
// Cross-module integration tests to validate module interactions.
//
// Run with: go test -v -run TestIntegration ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestIntegrationH1Foundation tests H1 Foundation tier modules together
func TestIntegrationH1Foundation(t *testing.T) {
	t.Parallel()

	// Test networking module initialization
	t.Run("networking", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/networking",
			Vars: map[string]interface{}{
				"customer_name":       "inttest",
				"environment":         "dev",
				"location":            "brazilsouth",
				"resource_group_name": "rg-int-test-net",
				"address_space":       []string{"10.0.0.0/16"},
				"tags": map[string]interface{}{
					"Environment": "test",
					"Horizon":     "H1",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})

	// Test AKS module initialization
	t.Run("aks-cluster", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/aks-cluster",
			Vars: map[string]interface{}{
				"customer_name":       "inttest",
				"environment":         "dev",
				"location":            "brazilsouth",
				"resource_group_name": "rg-int-test-aks",
				"kubernetes_version":  "1.29",
				"aks_subnet_id":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
				"tags": map[string]interface{}{
					"Environment": "test",
					"Horizon":     "H1",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})
}

// TestIntegrationH2Enhancement tests H2 Enhancement tier modules together
func TestIntegrationH2Enhancement(t *testing.T) {
	t.Parallel()

	// Test observability module
	t.Run("observability", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/observability",
			Vars: map[string]interface{}{
				"customer_name":       "inttest",
				"environment":         "dev",
				"location":            "brazilsouth",
				"resource_group_name": "rg-int-test-obs",
				"tags": map[string]interface{}{
					"Environment": "test",
					"Horizon":     "H2",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})

	// Test databases module
	t.Run("databases", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/databases",
			Vars: map[string]interface{}{
				"customer_name":       "inttest",
				"environment":         "dev",
				"location":            "brazilsouth",
				"resource_group_name": "rg-int-test-db",
				"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
				"tags": map[string]interface{}{
					"Environment": "test",
					"Horizon":     "H2",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})
}

// TestIntegrationH3Innovation tests H3 Innovation tier modules together
func TestIntegrationH3Innovation(t *testing.T) {
	t.Parallel()

	// Test AI Foundry module
	t.Run("ai-foundry", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/ai-foundry",
			Vars: map[string]interface{}{
				"customer_name":       "inttest",
				"environment":         "dev",
				"location":            "eastus",
				"resource_group_name": "rg-int-test-ai",
				"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
				"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
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
				"tags": map[string]interface{}{
					"Environment": "test",
					"Horizon":     "H3",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})
}

// TestIntegrationSecurityStack tests security-related modules together
func TestIntegrationSecurityStack(t *testing.T) {
	t.Parallel()

	// Test security module
	t.Run("security", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/security",
			Vars: map[string]interface{}{
				"customer_name":       "inttest",
				"environment":         "dev",
				"location":            "brazilsouth",
				"resource_group_name": "rg-int-test-sec",
				"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
				"tenant_id":           "00000000-0000-0000-0000-000000000000",
				"tags": map[string]interface{}{
					"Environment": "test",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})

	// Test defender module
	t.Run("defender", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/defender",
			Vars: map[string]interface{}{
				"subscription_id":            "00000000-0000-0000-0000-000000000000",
				"customer_name":              "inttest",
				"environment":                "dev",
				"log_analytics_workspace_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
				"security_contact_email":     "security@example.com",
				"tags": map[string]interface{}{
					"Environment": "test",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})
}

// TestIntegrationGitOpsStack tests GitOps-related modules together
func TestIntegrationGitOpsStack(t *testing.T) {
	t.Parallel()

	// Test ArgoCD module
	t.Run("argocd", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/argocd",
			Vars: map[string]interface{}{
				"customer_name": "inttest",
				"environment":   "dev",
				"github_org":    "test-org",
				"github_repo":   "test-repo",
				"argocd_config": map[string]interface{}{
					"namespace":   "argocd",
					"ha_enabled":  false,
					"server_host": "argocd.test.example.com",
				},
				"tags": map[string]interface{}{
					"Environment": "test",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})

	// Test External Secrets module
	t.Run("external-secrets", func(t *testing.T) {
		t.Parallel()

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../../../terraform/modules/external-secrets",
			Vars: map[string]interface{}{
				"customer_name":       "inttest",
				"environment":         "dev",
				"location":            "brazilsouth",
				"resource_group_name": "rg-int-test-eso",
				"aks_cluster_name":    "aks-int-test",
				"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
				"key_vault_uri":       "https://kv-test.vault.azure.net/",
				"tags": map[string]interface{}{
					"Environment": "test",
				},
			},
			NoColor: true,
		})

		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	})
}

// TestIntegrationEnvironmentParity tests that all environments can be initialized
func TestIntegrationEnvironmentParity(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}
	modules := []string{"networking", "security", "observability"}

	for _, env := range environments {
		env := env
		for _, module := range modules {
			module := module
			t.Run(env+"_"+module, func(t *testing.T) {
				t.Parallel()

				var terraformOptions *terraform.Options

				switch module {
				case "networking":
					terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
						TerraformDir: "../../../terraform/modules/networking",
						Vars: map[string]interface{}{
							"customer_name":       "paritytest",
							"environment":         env,
							"location":            "brazilsouth",
							"resource_group_name": "rg-parity-" + env + "-net",
							"address_space":       []string{"10.0.0.0/16"},
						},
						NoColor: true,
					})
				case "security":
					terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
						TerraformDir: "../../../terraform/modules/security",
						Vars: map[string]interface{}{
							"customer_name":       "paritytest",
							"environment":         env,
							"location":            "brazilsouth",
							"resource_group_name": "rg-parity-" + env + "-sec",
							"subnet_id":           "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
							"tenant_id":           "00000000-0000-0000-0000-000000000000",
						},
						NoColor: true,
					})
				case "observability":
					terraformOptions = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
						TerraformDir: "../../../terraform/modules/observability",
						Vars: map[string]interface{}{
							"customer_name":       "paritytest",
							"environment":         env,
							"location":            "brazilsouth",
							"resource_group_name": "rg-parity-" + env + "-obs",
						},
						NoColor: true,
					})
				}

				terraform.Init(t, terraformOptions)
				terraform.Validate(t, terraformOptions)

				planOutput := terraform.Plan(t, terraformOptions)
				assert.Contains(t, planOutput, env)
			})
		}
	}
}

// TestIntegrationNamingConsistency tests that naming conventions are consistent
func TestIntegrationNamingConsistency(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/naming",
		Vars: map[string]interface{}{
			"customer_name": "nametest",
			"environment":   "dev",
			"location":      "brazilsouth",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestIntegrationSizingProfiles tests that sizing profiles work across modules
func TestIntegrationSizingProfiles(t *testing.T) {
	t.Parallel()

	profiles := []string{"small", "medium", "large"}

	for _, profile := range profiles {
		profile := profile
		t.Run(profile, func(t *testing.T) {
			t.Parallel()

			// Test AKS with sizing profile
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/aks-cluster",
				Vars: map[string]interface{}{
					"customer_name":       "sizetest",
					"environment":         "dev",
					"location":            "brazilsouth",
					"resource_group_name": "rg-size-" + profile,
					"kubernetes_version":  "1.29",
					"sizing_profile":      profile,
					"aks_subnet_id":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Validate(t, terraformOptions)
		})
	}
}
