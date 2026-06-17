// =============================================================================
// OPEN HORIZONS PLATFORM - DEFENDER MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform Microsoft Defender module.
//
// Run with: go test -v -run TestDefender ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestDefenderModuleBasic tests basic Defender configuration
func TestDefenderModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/defender",
		Vars: map[string]interface{}{
			"subscription_id":            "00000000-0000-0000-0000-000000000000",
			"customer_name":              "testdef",
			"environment":                "dev",
			"log_analytics_workspace_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
			"security_contact_email":     "security@example.com",
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

	// Verify Defender for Cloud is planned
	assert.Contains(t, planOutput, "azurerm_security_center")
}

// TestDefenderModuleSizingProfiles tests different sizing profiles
func TestDefenderModuleSizingProfiles(t *testing.T) {
	t.Parallel()

	profiles := []string{"small", "medium", "large", "xlarge"}

	for _, profile := range profiles {
		profile := profile
		t.Run(profile, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/defender",
				Vars: map[string]interface{}{
					"subscription_id":            "00000000-0000-0000-0000-000000000000",
					"customer_name":              "sizetest",
					"environment":                "prod",
					"sizing_profile":             profile,
					"log_analytics_workspace_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
					"security_contact_email":     "security@example.com",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestDefenderModuleComplianceStandards tests regulatory compliance configuration
func TestDefenderModuleComplianceStandards(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/defender",
		Vars: map[string]interface{}{
			"subscription_id":                  "00000000-0000-0000-0000-000000000000",
			"customer_name":                    "comptest",
			"environment":                      "prod",
			"log_analytics_workspace_id":       "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
			"security_contact_email":           "security@example.com",
			"regulatory_compliance_standards":  []string{"Azure-CIS-1.4.0", "SOC-2", "ISO-27001"},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify compliance standards are configured
	assert.Contains(t, planOutput, "security")
}

// TestDefenderModuleAKSIntegration tests Defender for Containers with AKS
func TestDefenderModuleAKSIntegration(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/defender",
		Vars: map[string]interface{}{
			"subscription_id":            "00000000-0000-0000-0000-000000000000",
			"customer_name":              "aksdeftest",
			"environment":                "prod",
			"log_analytics_workspace_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
			"security_contact_email":     "security@example.com",
			"aks_cluster_ids": []string{
				"/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.ContainerService/managedClusters/aks1",
				"/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.ContainerService/managedClusters/aks2",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify AKS integration is planned
	assert.Contains(t, planOutput, "defender")
}

// TestDefenderModuleJITAccess tests Just-In-Time access configuration
func TestDefenderModuleJITAccess(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name       string
		jitEnabled bool
	}{
		{"jit_enabled", true},
		{"jit_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/defender",
				Vars: map[string]interface{}{
					"subscription_id":            "00000000-0000-0000-0000-000000000000",
					"customer_name":              "jittest",
					"environment":                "prod",
					"log_analytics_workspace_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
					"security_contact_email":     "security@example.com",
					"enable_jit_access":          tc.jitEnabled,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestDefenderModuleAutoProvisioning tests auto-provisioning settings
func TestDefenderModuleAutoProvisioning(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/defender",
		Vars: map[string]interface{}{
			"subscription_id":            "00000000-0000-0000-0000-000000000000",
			"customer_name":              "autoprovtest",
			"environment":                "prod",
			"log_analytics_workspace_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
			"security_contact_email":     "security@example.com",
			"auto_provisioning_settings": map[string]interface{}{
				"log_analytics_agent":      true,
				"vulnerability_assessment": true,
				"defender_for_containers":  true,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify auto-provisioning is configured
	assert.Contains(t, planOutput, "security")
}

// TestDefenderModuleEnvironments tests different environments
func TestDefenderModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/defender",
				Vars: map[string]interface{}{
					"subscription_id":            "00000000-0000-0000-0000-000000000000",
					"customer_name":              "envtest",
					"environment":                env,
					"log_analytics_workspace_id": "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law",
					"security_contact_email":     "security@example.com",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
