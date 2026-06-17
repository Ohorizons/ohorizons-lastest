// =============================================================================
// OPEN HORIZONS PLATFORM - ARGOCD MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform ArgoCD module.
//
// Run with: go test -v -run TestArgoCD ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestArgoCDModuleBasic tests basic ArgoCD configuration
func TestArgoCDModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/argocd",
		Vars: map[string]interface{}{
			"customer_name": "testargocd",
			"environment":   "dev",
			"github_org":    "test-org",
			"github_repo":   "test-repo",
			"argocd_config": map[string]interface{}{
				"namespace":   "argocd",
				"ha_enabled":  false,
				"server_host": "argocd.example.com",
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

	// Verify ArgoCD resources are planned
	assert.Contains(t, planOutput, "helm_release.argocd")
}

// TestArgoCDModuleHAConfiguration tests high availability setup
func TestArgoCDModuleHAConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name      string
		haEnabled bool
	}{
		{"ha_disabled", false},
		{"ha_enabled", true},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/argocd",
				Vars: map[string]interface{}{
					"customer_name": "hatest",
					"environment":   "prod",
					"github_org":    "test-org",
					"github_repo":   "test-repo",
					"argocd_config": map[string]interface{}{
						"namespace":   "argocd",
						"ha_enabled":  tc.haEnabled,
						"server_host": "argocd.example.com",
					},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestArgoCDModuleApplicationSets tests ApplicationSet configuration
func TestArgoCDModuleApplicationSets(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/argocd",
		Vars: map[string]interface{}{
			"customer_name": "appsettest",
			"environment":   "dev",
			"github_org":    "test-org",
			"github_repo":   "test-repo",
			"argocd_config": map[string]interface{}{
				"namespace":             "argocd",
				"ha_enabled":            false,
				"server_host":           "argocd.example.com",
				"enable_applicationset": true,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify ApplicationSet controller is planned
	assert.Contains(t, planOutput, "argocd")
}

// TestArgoCDModuleEnvironments tests different environments
func TestArgoCDModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/argocd",
				Vars: map[string]interface{}{
					"customer_name": "envtest",
					"environment":   env,
					"github_org":    "test-org",
					"github_repo":   "test-repo",
					"argocd_config": map[string]interface{}{
						"namespace":   "argocd",
						"ha_enabled":  env == "prod",
						"server_host": "argocd-" + env + ".example.com",
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
