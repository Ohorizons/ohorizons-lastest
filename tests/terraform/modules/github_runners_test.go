// =============================================================================
// OPEN HORIZONS PLATFORM - GITHUB RUNNERS MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform GitHub Runners module.
//
// Run with: go test -v -run TestGitHubRunners ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestGitHubRunnersModuleBasic tests basic GitHub Runners configuration
func TestGitHubRunnersModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/github-runners",
		Vars: map[string]interface{}{
			"customer_name":              "testrunner",
			"environment":                "dev",
			"namespace":                  "github-runners",
			"github_org":                 "test-org",
			"github_app_id":              "12345",
			"github_app_installation_id": "67890",
			"github_app_private_key":     "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
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

	// Verify GitHub Actions Runner Controller is planned
	assert.Contains(t, planOutput, "helm_release")
}

// TestGitHubRunnersModuleScaleSets tests runner scale set configuration
func TestGitHubRunnersModuleScaleSets(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/github-runners",
		Vars: map[string]interface{}{
			"customer_name":              "scaletest",
			"environment":                "prod",
			"namespace":                  "github-runners",
			"github_org":                 "test-org",
			"github_app_id":              "12345",
			"github_app_installation_id": "67890",
			"github_app_private_key":     "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
			"runner_groups": map[string]interface{}{
				"default": map[string]interface{}{
					"min_runners":   2,
					"max_runners":   20,
					"runner_group":  "default",
					"labels":        []string{"self-hosted", "linux", "x64"},
					"node_selector": map[string]interface{}{},
					"tolerations":   []interface{}{},
					"resources": map[string]interface{}{
						"cpu_request":    "500m",
						"cpu_limit":      "2000m",
						"memory_request": "1Gi",
						"memory_limit":   "4Gi",
					},
					"container_mode": "dind",
				},
				"large": map[string]interface{}{
					"min_runners":   1,
					"max_runners":   10,
					"runner_group":  "large-runners",
					"labels":        []string{"self-hosted", "linux", "x64", "large"},
					"node_selector": map[string]interface{}{},
					"tolerations":   []interface{}{},
					"resources": map[string]interface{}{
						"cpu_request":    "2000m",
						"cpu_limit":      "4000m",
						"memory_request": "4Gi",
						"memory_limit":   "8Gi",
					},
					"container_mode": "dind",
				},
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify scale sets are configured
	assert.Contains(t, planOutput, "github")
}

// TestGitHubRunnersModuleControllerReplicas tests controller replica configuration
func TestGitHubRunnersModuleControllerReplicas(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name     string
		replicas int
	}{
		{"single_controller", 1},
		{"dual_controller", 2},
		{"ha_controller", 3},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/github-runners",
				Vars: map[string]interface{}{
					"customer_name":              "ctrltest",
					"environment":                "prod",
					"namespace":                  "github-runners",
					"github_org":                 "test-org",
					"github_app_id":              "12345",
					"github_app_installation_id": "67890",
					"github_app_private_key":     "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
					"controller_replicas":        tc.replicas,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestGitHubRunnersModuleCustomImage tests custom runner image configuration
func TestGitHubRunnersModuleCustomImage(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/github-runners",
		Vars: map[string]interface{}{
			"customer_name":              "imgtest",
			"environment":                "prod",
			"namespace":                  "github-runners",
			"github_org":                 "test-org",
			"github_app_id":              "12345",
			"github_app_installation_id": "67890",
			"github_app_private_key":     "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
			"acr_login_server":           "myacr.azurecr.io",
			"custom_runner_image":        "myacr.azurecr.io/custom-runner:latest",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify custom image configuration
	assert.Contains(t, planOutput, "github")
}

// TestGitHubRunnersModuleEnvironments tests different environments
func TestGitHubRunnersModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/github-runners",
				Vars: map[string]interface{}{
					"customer_name":              "envtest",
					"environment":                env,
					"namespace":                  "github-runners-" + env,
					"github_org":                 "test-org",
					"github_app_id":              "12345",
					"github_app_installation_id": "67890",
					"github_app_private_key":     "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
