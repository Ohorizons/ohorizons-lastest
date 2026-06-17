// =============================================================================
// OPEN HORIZONS PLATFORM - EXTERNAL SECRETS MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform External Secrets Operator module.
//
// Run with: go test -v -run TestExternalSecrets ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestExternalSecretsModuleBasic tests basic ESO configuration
func TestExternalSecretsModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/external-secrets",
		Vars: map[string]interface{}{
			"customer_name":       "testeso",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-eso",
			"aks_cluster_name":    "aks-test-eso",
			"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"key_vault_uri":       "https://kv-test.vault.azure.net/",
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

	// Verify ESO Helm release is planned
	assert.Contains(t, planOutput, "helm_release")
}

// TestExternalSecretsModuleRBAC tests RBAC vs Access Policy configuration
func TestExternalSecretsModuleRBAC(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name     string
		useRBAC  bool
	}{
		{"rbac_enabled", true},
		{"access_policy", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/external-secrets",
				Vars: map[string]interface{}{
					"customer_name":       "rbactest",
					"environment":         "prod",
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-eso-rbac",
					"aks_cluster_name":    "aks-test-eso-rbac",
					"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
					"key_vault_uri":       "https://kv-test.vault.azure.net/",
					"use_key_vault_rbac":  tc.useRBAC,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestExternalSecretsModuleMetrics tests Prometheus metrics configuration
func TestExternalSecretsModuleMetrics(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		enabled bool
	}{
		{"metrics_enabled", true},
		{"metrics_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/external-secrets",
				Vars: map[string]interface{}{
					"customer_name":              "metricstest",
					"environment":                "prod",
					"location":                   "brazilsouth",
					"resource_group_name":        "rg-test-eso-metrics",
					"aks_cluster_name":           "aks-test-eso-metrics",
					"key_vault_id":               "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
					"key_vault_uri":              "https://kv-test.vault.azure.net/",
					"enable_prometheus_metrics":  tc.enabled,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestExternalSecretsModulePushSecrets tests PushSecret configuration
func TestExternalSecretsModulePushSecrets(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		enabled bool
	}{
		{"push_enabled", true},
		{"push_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/external-secrets",
				Vars: map[string]interface{}{
					"customer_name":        "pushtest",
					"environment":          "prod",
					"location":             "brazilsouth",
					"resource_group_name":  "rg-test-eso-push",
					"aks_cluster_name":     "aks-test-eso-push",
					"key_vault_id":         "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
					"key_vault_uri":        "https://kv-test.vault.azure.net/",
					"enable_push_secrets":  tc.enabled,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestExternalSecretsModuleExampleSecret tests example secret creation
func TestExternalSecretsModuleExampleSecret(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/external-secrets",
		Vars: map[string]interface{}{
			"customer_name":         "exampletest",
			"environment":           "dev",
			"location":              "brazilsouth",
			"resource_group_name":   "rg-test-eso-example",
			"aks_cluster_name":      "aks-test-eso-example",
			"key_vault_id":          "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"key_vault_uri":         "https://kv-test.vault.azure.net/",
			"create_example_secret": true,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify example secret is planned
	assert.Contains(t, planOutput, "external")
}

// TestExternalSecretsModuleNodeSelector tests node selector configuration
func TestExternalSecretsModuleNodeSelector(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/external-secrets",
		Vars: map[string]interface{}{
			"customer_name":       "nodetest",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-eso-node",
			"aks_cluster_name":    "aks-test-eso-node",
			"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
			"key_vault_uri":       "https://kv-test.vault.azure.net/",
			"node_selector": map[string]interface{}{
				"workload-type": "platform",
			},
			"tolerations": []map[string]interface{}{
				{
					"key":      "platform",
					"operator": "Equal",
					"value":    "true",
					"effect":   "NoSchedule",
				},
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify node configuration
	assert.Contains(t, planOutput, "external")
}

// TestExternalSecretsModuleEnvironments tests different environments
func TestExternalSecretsModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/external-secrets",
				Vars: map[string]interface{}{
					"customer_name":       "envtest",
					"environment":         env,
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-eso-" + env,
					"aks_cluster_name":    "aks-test-eso-" + env,
					"key_vault_id":        "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv",
					"key_vault_uri":       "https://kv-test.vault.azure.net/",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
