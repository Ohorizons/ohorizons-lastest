// =============================================================================
// OPEN HORIZONS PLATFORM - SECURITY MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform security module.
//
// Run with: go test -v -run TestSecurity ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestSecurityModuleBasic tests basic security module configuration
func TestSecurityModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/security",
		Vars: map[string]interface{}{
			"customer_name":       "testsec",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-security",
			"tenant_id":           "00000000-0000-0000-0000-000000000000",
			"admin_group_id":      "00000000-0000-0000-0000-000000000001",
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

	// Verify Key Vault is planned
	assert.Contains(t, planOutput, "azurerm_key_vault.main")
}

// TestSecurityModuleKeyVaultNaming tests Key Vault naming convention
func TestSecurityModuleKeyVaultNaming(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/security",
		Vars: map[string]interface{}{
			"customer_name":       "kvtest",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-kv",
			"tenant_id":           "00000000-0000-0000-0000-000000000000",
			"admin_group_id":      "00000000-0000-0000-0000-000000000001",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Key Vault name must follow CAF naming convention
	assert.Contains(t, planOutput, "kv-")
}

// TestSecurityModuleManagedIdentities tests managed identity creation
func TestSecurityModuleManagedIdentities(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/security",
		Vars: map[string]interface{}{
			"customer_name":        "idtest",
			"environment":          "dev",
			"location":             "brazilsouth",
			"resource_group_name":  "rg-test-identity",
			"tenant_id":            "00000000-0000-0000-0000-000000000000",
			"admin_group_id":       "00000000-0000-0000-0000-000000000001",
			"create_aks_identity":  true,
			"create_app_identities": []string{"app1", "app2"},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify managed identities are planned
	assert.Contains(t, planOutput, "azurerm_user_assigned_identity")
}

// TestSecurityModuleRBACAssignments tests RBAC role assignments
func TestSecurityModuleRBACAssignments(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/security",
		Vars: map[string]interface{}{
			"customer_name":       "rbactest",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-rbac",
			"tenant_id":           "00000000-0000-0000-0000-000000000000",
			"admin_group_id":      "00000000-0000-0000-0000-000000000001",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify RBAC assignments are planned
	assert.Contains(t, planOutput, "azurerm_role_assignment")
}

// TestSecurityModuleKeyVaultAccessPolicies tests Key Vault access policies
func TestSecurityModuleKeyVaultAccessPolicies(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/security",
		Vars: map[string]interface{}{
			"customer_name":       "kvaccess",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-kvaccess",
			"tenant_id":           "00000000-0000-0000-0000-000000000000",
			"admin_group_id":      "00000000-0000-0000-0000-000000000001",
			"enable_rbac_authorization": true,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// With RBAC, access policies should not be used
	assert.Contains(t, planOutput, "enable_rbac_authorization")
}

// TestSecurityModuleEnvironments tests different environment configurations
func TestSecurityModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/security",
				Vars: map[string]interface{}{
					"customer_name":       "secenv",
					"environment":         env,
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-sec-" + env,
					"tenant_id":           "00000000-0000-0000-0000-000000000000",
					"admin_group_id":      "00000000-0000-0000-0000-000000000001",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			// Verify environment is reflected
			assert.Contains(t, planOutput, env)
		})
	}
}
