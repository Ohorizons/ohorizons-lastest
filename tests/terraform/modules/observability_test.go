// =============================================================================
// OPEN HORIZONS PLATFORM - OBSERVABILITY MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform observability module.
//
// Run with: go test -v -run TestObservability ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestObservabilityModuleBasic tests basic observability configuration
func TestObservabilityModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/observability",
		Vars: map[string]interface{}{
			"customer_name":       "testobs",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-obs",
			"enable_prometheus":   true,
			"enable_grafana":      true,
			"enable_loki":         true,
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

	// Verify observability stack is planned
	assert.Contains(t, planOutput, "azurerm_log_analytics_workspace")
}

// TestObservabilityModuleLogAnalytics tests Log Analytics workspace
func TestObservabilityModuleLogAnalytics(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/observability",
		Vars: map[string]interface{}{
			"customer_name":       "latest",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-la",
			"log_analytics_config": map[string]interface{}{
				"sku":               "PerGB2018",
				"retention_in_days": 30,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify Log Analytics workspace naming
	assert.Contains(t, planOutput, "log-")
}

// TestObservabilityModuleGrafana tests Azure Managed Grafana
func TestObservabilityModuleGrafana(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/observability",
		Vars: map[string]interface{}{
			"customer_name":       "graftest",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-grafana",
			"enable_grafana":      true,
			"grafana_config": map[string]interface{}{
				"sku":                    "Standard",
				"api_key_enabled":        true,
				"public_network_enabled": false,
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify Grafana is planned
	assert.Contains(t, planOutput, "azurerm_dashboard_grafana")
}

// TestObservabilityModuleAlerts tests alert configuration
func TestObservabilityModuleAlerts(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/observability",
		Vars: map[string]interface{}{
			"customer_name":       "alerttest",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-alerts",
			"enable_alerts":       true,
			"alert_config": map[string]interface{}{
				"action_group_email": "ops@example.com",
				"severity_levels":    []int{0, 1, 2},
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify action group is planned
	assert.Contains(t, planOutput, "azurerm_monitor_action_group")
}

// TestObservabilityModuleEnvironments tests different environments
func TestObservabilityModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/observability",
				Vars: map[string]interface{}{
					"customer_name":       "obsenv",
					"environment":         env,
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-obs-" + env,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
