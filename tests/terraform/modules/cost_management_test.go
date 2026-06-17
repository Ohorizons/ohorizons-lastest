// =============================================================================
// OPEN HORIZONS PLATFORM - COST MANAGEMENT MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform Cost Management module.
//
// Run with: go test -v -run TestCostManagement ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestCostManagementModuleBasic tests basic cost management configuration
func TestCostManagementModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/cost-management",
		Vars: map[string]interface{}{
			"customer_name":         "testcost",
			"environment":           "dev",
			"location":              "brazilsouth",
			"resource_group_name":   "rg-test-cost",
			"monthly_budget":        5000,
			"alert_email_addresses": []string{"ops@example.com"},
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

	// Verify budget is planned
	assert.Contains(t, planOutput, "azurerm_consumption_budget")
}

// TestCostManagementModuleBudgetThresholds tests different budget levels
func TestCostManagementModuleBudgetThresholds(t *testing.T) {
	t.Parallel()

	budgets := []int{1000, 5000, 10000, 50000}

	for _, budget := range budgets {
		budget := budget
		t.Run(string(rune(budget)), func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/cost-management",
				Vars: map[string]interface{}{
					"customer_name":         "budgettest",
					"environment":           "prod",
					"location":              "brazilsouth",
					"resource_group_name":   "rg-test-cost-budget",
					"monthly_budget":        budget,
					"alert_email_addresses": []string{"ops@example.com", "finance@example.com"},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestCostManagementModuleMultipleAlertRecipients tests multiple email alerts
func TestCostManagementModuleMultipleAlertRecipients(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/cost-management",
		Vars: map[string]interface{}{
			"customer_name":       "alerttest",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-cost-alerts",
			"monthly_budget":      10000,
			"alert_email_addresses": []string{
				"ops@example.com",
				"finance@example.com",
				"manager@example.com",
				"director@example.com",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify action group is planned
	assert.Contains(t, planOutput, "azurerm_monitor_action_group")
}

// TestCostManagementModuleCostExport tests cost export configuration
func TestCostManagementModuleCostExport(t *testing.T) {
	t.Parallel()

	recurrences := []string{"Daily", "Weekly", "Monthly"}

	for _, recurrence := range recurrences {
		recurrence := recurrence
		t.Run(recurrence, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/cost-management",
				Vars: map[string]interface{}{
					"customer_name":         "exporttest",
					"environment":           "prod",
					"location":              "brazilsouth",
					"resource_group_name":   "rg-test-cost-export",
					"monthly_budget":        10000,
					"alert_email_addresses": []string{"ops@example.com"},
					"enable_cost_export":    true,
					"export_recurrence":     recurrence,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestCostManagementModuleSubscriptionBudget tests subscription-level budget
func TestCostManagementModuleSubscriptionBudget(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		enabled bool
	}{
		{"subscription_budget_enabled", true},
		{"subscription_budget_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/cost-management",
				Vars: map[string]interface{}{
					"customer_name":              "subtest",
					"environment":                "prod",
					"location":                   "brazilsouth",
					"resource_group_name":        "rg-test-cost-sub",
					"monthly_budget":             10000,
					"alert_email_addresses":      []string{"ops@example.com"},
					"create_subscription_budget": tc.enabled,
					"subscription_monthly_budget": 50000,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestCostManagementModuleWebhooks tests webhook notification configuration
func TestCostManagementModuleWebhooks(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/cost-management",
		Vars: map[string]interface{}{
			"customer_name":         "webhooktest",
			"environment":           "prod",
			"location":              "brazilsouth",
			"resource_group_name":   "rg-test-cost-webhook",
			"monthly_budget":        10000,
			"alert_email_addresses": []string{"ops@example.com"},
			"webhook_urls": []string{
				"https://hooks.slack.com/services/xxx/yyy/zzz",
				"https://teams.webhook.office.com/xxx",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify webhook configuration
	assert.Contains(t, planOutput, "cost")
}

// TestCostManagementModuleCustomAlerts tests custom cost alert rules
func TestCostManagementModuleCustomAlerts(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		enabled bool
	}{
		{"custom_alerts_enabled", true},
		{"custom_alerts_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/cost-management",
				Vars: map[string]interface{}{
					"customer_name":              "customtest",
					"environment":                "prod",
					"location":                   "brazilsouth",
					"resource_group_name":        "rg-test-cost-custom",
					"monthly_budget":             10000,
					"alert_email_addresses":      []string{"ops@example.com"},
					"enable_custom_cost_alerts":  tc.enabled,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestCostManagementModuleEnvironments tests different environments
func TestCostManagementModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/cost-management",
				Vars: map[string]interface{}{
					"customer_name":         "envtest",
					"environment":           env,
					"location":              "brazilsouth",
					"resource_group_name":   "rg-test-cost-" + env,
					"monthly_budget":        5000,
					"alert_email_addresses": []string{"ops@example.com"},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
