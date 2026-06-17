// =============================================================================
// OPEN HORIZONS PLATFORM - NAMING MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform naming module.
//
// Run with: go test -v -run TestNaming ./modules/
//
// =============================================================================

package modules

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestNamingModuleBasic tests basic naming conventions
func TestNamingModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/naming",
		Vars: map[string]interface{}{
			"customer_name": "contoso",
			"environment":   "dev",
			"region":        "brazilsouth",
			"project":       "platform",
		},
		NoColor: true,
	})

	// Initialize and plan only (no resources created)
	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)

	// Apply to get outputs
	terraform.Apply(t, terraformOptions)
	defer terraform.Destroy(t, terraformOptions)

	// Test resource group naming
	rgName := terraform.Output(t, terraformOptions, "resource_group_name")
	assert.Contains(t, rgName, "contoso")
	assert.Contains(t, rgName, "dev")
	assert.Contains(t, rgName, "rg")

	// Test AKS cluster naming
	aksName := terraform.Output(t, terraformOptions, "aks_cluster_name")
	assert.Contains(t, aksName, "aks")
	assert.NotContains(t, aksName, "_") // AKS names cannot contain underscores

	// Test Storage Account naming (no hyphens, max 24 chars)
	storageName := terraform.Output(t, terraformOptions, "storage_account_name")
	assert.NotContains(t, storageName, "-")
	assert.LessOrEqual(t, len(storageName), 24)

	// Test ACR naming (no hyphens)
	acrName := terraform.Output(t, terraformOptions, "container_registry_name")
	assert.NotContains(t, acrName, "-")

	// Test Key Vault naming (max 24 chars)
	kvName := terraform.Output(t, terraformOptions, "key_vault_name")
	assert.LessOrEqual(t, len(kvName), 24)
}

// TestNamingModuleRegionCodes tests region short codes
func TestNamingModuleRegionCodes(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		region       string
		expectedCode string
	}{
		{"brazilsouth", "brz"},
		{"eastus", "eus"},
		{"eastus2", "eu2"},
		{"westus", "wus"},
		{"westus2", "wu2"},
		{"westeurope", "weu"},
		{"northeurope", "neu"},
	}

	for _, tc := range testCases {
		tc := tc // capture range variable
		t.Run(tc.region, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/naming",
				Vars: map[string]interface{}{
					"customer_name": "test",
					"environment":   "dev",
					"region":        tc.region,
					"project":       "test",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Apply(t, terraformOptions)
			defer terraform.Destroy(t, terraformOptions)

			regionCode := terraform.Output(t, terraformOptions, "region_short")
			assert.Equal(t, tc.expectedCode, regionCode)
		})
	}
}

// TestNamingModuleEnvironments tests different environment configurations
func TestNamingModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/naming",
				Vars: map[string]interface{}{
					"customer_name": "test",
					"environment":   env,
					"region":        "brazilsouth",
					"project":       "test",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Apply(t, terraformOptions)
			defer terraform.Destroy(t, terraformOptions)

			rgName := terraform.Output(t, terraformOptions, "resource_group_name")
			assert.Contains(t, rgName, env)
		})
	}
}

// TestNamingModuleValidation tests input validation
func TestNamingModuleValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		shouldError bool
	}{
		{
			name: "valid_inputs",
			vars: map[string]interface{}{
				"customer_name": "contoso",
				"environment":   "dev",
				"region":        "brazilsouth",
				"project":       "platform",
			},
			shouldError: false,
		},
		{
			name: "invalid_environment",
			vars: map[string]interface{}{
				"customer_name": "contoso",
				"environment":   "invalid",
				"region":        "brazilsouth",
				"project":       "platform",
			},
			shouldError: true,
		},
		{
			name: "customer_name_too_long",
			vars: map[string]interface{}{
				"customer_name": "this-is-a-very-long-customer-name-that-exceeds-limits",
				"environment":   "dev",
				"region":        "brazilsouth",
				"project":       "platform",
			},
			shouldError: true,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/naming",
				Vars:         tc.vars,
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			if tc.shouldError {
				_, err := terraform.PlanE(t, terraformOptions)
				require.Error(t, err, "Expected validation error but got none")
			} else {
				terraform.Plan(t, terraformOptions)
			}
		})
	}
}

// TestNamingModuleOutputConsistency tests that outputs are consistent across runs
func TestNamingModuleOutputConsistency(t *testing.T) {
	t.Parallel()

	vars := map[string]interface{}{
		"customer_name": "consistency",
		"environment":   "dev",
		"region":        "brazilsouth",
		"project":       "test",
	}

	// First run
	terraformOptions1 := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/naming",
		Vars:         vars,
		NoColor:      true,
	})

	terraform.Init(t, terraformOptions1)
	terraform.Apply(t, terraformOptions1)
	outputs1 := terraform.OutputAll(t, terraformOptions1)
	terraform.Destroy(t, terraformOptions1)

	// Second run with same inputs
	terraformOptions2 := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/naming",
		Vars:         vars,
		NoColor:      true,
	})

	terraform.Init(t, terraformOptions2)
	terraform.Apply(t, terraformOptions2)
	outputs2 := terraform.OutputAll(t, terraformOptions2)
	defer terraform.Destroy(t, terraformOptions2)

	// Compare outputs
	for key, value1 := range outputs1 {
		value2, exists := outputs2[key]
		require.True(t, exists, "Output %s missing in second run", key)
		assert.Equal(t, value1, value2, "Output %s differs between runs", key)
	}
}

// TestNamingModuleAzureCompliance tests Azure naming rules compliance
func TestNamingModuleAzureCompliance(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/naming",
		Vars: map[string]interface{}{
			"customer_name": "azure",
			"environment":   "prod",
			"region":        "brazilsouth",
			"project":       "compliance",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	terraform.Apply(t, terraformOptions)
	defer terraform.Destroy(t, terraformOptions)

	// Test various Azure naming constraints
	outputs := terraform.OutputAll(t, terraformOptions)

	// Storage account: lowercase alphanumeric, 3-24 chars
	storageName := fmt.Sprintf("%v", outputs["storage_account_name"])
	assert.Regexp(t, "^[a-z0-9]{3,24}$", storageName)

	// Container registry: alphanumeric, 5-50 chars
	acrName := fmt.Sprintf("%v", outputs["container_registry_name"])
	assert.Regexp(t, "^[a-zA-Z0-9]{5,50}$", acrName)

	// Key vault: alphanumeric and hyphens, 3-24 chars, start with letter
	kvName := fmt.Sprintf("%v", outputs["key_vault_name"])
	assert.Regexp(t, "^[a-zA-Z][a-zA-Z0-9-]{2,23}$", kvName)

	// Resource group: alphanumeric, periods, underscores, hyphens, parentheses
	rgName := fmt.Sprintf("%v", outputs["resource_group_name"])
	assert.LessOrEqual(t, len(rgName), 90)
	assert.False(t, strings.HasSuffix(rgName, "."))
}
