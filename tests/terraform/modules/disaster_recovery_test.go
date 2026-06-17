// =============================================================================
// OPEN HORIZONS PLATFORM - DISASTER RECOVERY MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform Disaster Recovery module.
//
// Run with: go test -v -run TestDisasterRecovery ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestDisasterRecoveryModuleBasic tests basic DR configuration
func TestDisasterRecoveryModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/disaster-recovery",
		Vars: map[string]interface{}{
			"customer_name":               "testdr",
			"environment":                 "dev",
			"primary_location":            "brazilsouth",
			"primary_region_short":        "brz",
			"primary_resource_group_name": "rg-test-dr-primary",
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

	// Verify Recovery Services Vault is planned
	assert.Contains(t, planOutput, "azurerm_recovery_services_vault")
}

// TestDisasterRecoveryModuleRPORTO tests RPO/RTO configuration
func TestDisasterRecoveryModuleRPORTO(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name string
		rpo  string
		rto  string
	}{
		{"aggressive", "15m", "1h"},
		{"standard", "1h", "4h"},
		{"relaxed", "24h", "48h"},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/disaster-recovery",
				Vars: map[string]interface{}{
					"customer_name":               "rpotest",
					"environment":                 "prod",
					"primary_location":            "brazilsouth",
					"primary_region_short":        "brz",
					"primary_resource_group_name": "rg-test-dr-rpo",
					"recovery_point_objective":    tc.rpo,
					"recovery_time_objective":     tc.rto,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestDisasterRecoveryModuleRetention tests backup retention configuration
func TestDisasterRecoveryModuleRetention(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/disaster-recovery",
		Vars: map[string]interface{}{
			"customer_name":               "rettest",
			"environment":                 "prod",
			"primary_location":            "brazilsouth",
			"primary_region_short":        "brz",
			"primary_resource_group_name": "rg-test-dr-retention",
			"retention_daily_count":       14,
			"retention_weekly_count":      8,
			"retention_monthly_count":     24,
			"retention_yearly_count":      5,
			"instant_restore_days":        3,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify backup policy is planned
	assert.Contains(t, planOutput, "azurerm_backup_policy")
}

// TestDisasterRecoveryModuleStorageRedundancy tests storage redundancy options
func TestDisasterRecoveryModuleStorageRedundancy(t *testing.T) {
	t.Parallel()

	redundancyOptions := []string{"GeoRedundant", "LocallyRedundant", "ZoneRedundant"}

	for _, redundancy := range redundancyOptions {
		redundancy := redundancy
		t.Run(redundancy, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/disaster-recovery",
				Vars: map[string]interface{}{
					"customer_name":               "redtest",
					"environment":                 "prod",
					"primary_location":            "brazilsouth",
					"primary_region_short":        "brz",
					"primary_resource_group_name": "rg-test-dr-redundancy",
					"storage_redundancy":          redundancy,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestDisasterRecoveryModuleSiteRecovery tests Azure Site Recovery configuration
func TestDisasterRecoveryModuleSiteRecovery(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		enabled bool
	}{
		{"asr_enabled", true},
		{"asr_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/disaster-recovery",
				Vars: map[string]interface{}{
					"customer_name":               "asrtest",
					"environment":                 "prod",
					"primary_location":            "brazilsouth",
					"primary_region_short":        "brz",
					"primary_resource_group_name": "rg-test-dr-asr",
					"enable_site_recovery":        tc.enabled,
					"dr_location":                 "eastus2",
					"dr_region_short":             "eu2",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestDisasterRecoveryModuleCrossRegion tests cross-region restore
func TestDisasterRecoveryModuleCrossRegion(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/disaster-recovery",
		Vars: map[string]interface{}{
			"customer_name":               "crosstest",
			"environment":                 "prod",
			"primary_location":            "brazilsouth",
			"primary_region_short":        "brz",
			"primary_resource_group_name": "rg-test-dr-cross",
			"dr_location":                 "eastus2",
			"dr_region_short":             "eu2",
			"enable_cross_region_restore": true,
			"storage_redundancy":          "GeoRedundant",
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify cross-region configuration
	assert.Contains(t, planOutput, "recovery")
}

// TestDisasterRecoveryModuleImmutability tests immutability configuration
func TestDisasterRecoveryModuleImmutability(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		enabled bool
	}{
		{"immutable_enabled", true},
		{"immutable_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/disaster-recovery",
				Vars: map[string]interface{}{
					"customer_name":               "immtest",
					"environment":                 "prod",
					"primary_location":            "brazilsouth",
					"primary_region_short":        "brz",
					"primary_resource_group_name": "rg-test-dr-immutable",
					"enable_immutability":         tc.enabled,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestDisasterRecoveryModuleEnvironments tests different environments
func TestDisasterRecoveryModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/disaster-recovery",
				Vars: map[string]interface{}{
					"customer_name":               "envtest",
					"environment":                 env,
					"primary_location":            "brazilsouth",
					"primary_region_short":        "brz",
					"primary_resource_group_name": "rg-test-dr-" + env,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
