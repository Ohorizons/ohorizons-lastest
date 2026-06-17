// =============================================================================
// OPEN HORIZONS PLATFORM - NETWORKING MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform networking module.
//
// Run with: go test -v -run TestNetworking ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestNetworkingModuleBasic tests basic networking configuration
func TestNetworkingModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/networking",
		Vars: map[string]interface{}{
			"customer_name":       "testcustomer",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-networking",
			"vnet_cidr":           "10.0.0.0/16",
			"dns_zone_name":       "test.example.com",
			"subnet_config": map[string]interface{}{
				"aks_nodes_cidr":         "10.0.0.0/22",
				"aks_pods_cidr":          "10.0.16.0/20",
				"private_endpoints_cidr": "10.0.4.0/24",
				"bastion_cidr":           "10.0.5.0/26",
				"app_gateway_cidr":       "10.0.6.0/24",
			},
			"enable_bastion":     false,
			"enable_app_gateway": false,
			"create_dns_zone":    false,
			"tags": map[string]interface{}{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		NoColor: true,
	})

	// Initialize and validate
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)

	// Plan only (no actual resources created in unit test)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify plan contains expected resources
	assert.Contains(t, planOutput, "azurerm_virtual_network.main")
	assert.Contains(t, planOutput, "azurerm_subnet.aks_nodes")
	assert.Contains(t, planOutput, "azurerm_subnet.aks_pods")
	assert.Contains(t, planOutput, "azurerm_subnet.private_endpoints")
	assert.Contains(t, planOutput, "azurerm_network_security_group.aks_nodes")
	assert.Contains(t, planOutput, "azurerm_network_security_group.private_endpoints")
}

// TestNetworkingModuleVNetCIDRValidation tests VNet CIDR validation
func TestNetworkingModuleVNetCIDRValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name      string
		vnetCIDR  string
		shouldErr bool
	}{
		{"valid_16", "10.0.0.0/16", false},
		{"valid_8", "10.0.0.0/8", false},
		{"valid_24", "10.0.0.0/24", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/networking",
				Vars: map[string]interface{}{
					"customer_name":       "test",
					"environment":         "dev",
					"location":            "brazilsouth",
					"resource_group_name": "rg-test",
					"vnet_cidr":           tc.vnetCIDR,
					"dns_zone_name":       "test.example.com",
					"create_dns_zone":     false,
				},
				NoColor: true,
			}

			terraform.Init(t, terraformOptions)

			if tc.shouldErr {
				_, err := terraform.PlanE(t, terraformOptions)
				require.Error(t, err)
			} else {
				terraform.Plan(t, terraformOptions)
			}
		})
	}
}

// TestNetworkingModuleSubnetConfiguration tests subnet configurations
func TestNetworkingModuleSubnetConfiguration(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/networking",
		Vars: map[string]interface{}{
			"customer_name":       "subnet",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-subnet",
			"vnet_cidr":           "10.0.0.0/16",
			"dns_zone_name":       "test.example.com",
			"subnet_config": map[string]interface{}{
				"aks_nodes_cidr":         "10.0.0.0/22",
				"aks_pods_cidr":          "10.0.16.0/20",
				"private_endpoints_cidr": "10.0.4.0/24",
				"bastion_cidr":           "10.0.5.0/26",
				"app_gateway_cidr":       "10.0.6.0/24",
			},
			"enable_bastion":     true,
			"enable_app_gateway": true,
			"create_dns_zone":    false,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify all subnets are planned when enabled
	assert.Contains(t, planOutput, "azurerm_subnet.aks_nodes")
	assert.Contains(t, planOutput, "azurerm_subnet.aks_pods")
	assert.Contains(t, planOutput, "azurerm_subnet.private_endpoints")
	assert.Contains(t, planOutput, "azurerm_subnet.bastion")
	assert.Contains(t, planOutput, "azurerm_subnet.app_gateway")
}

// TestNetworkingModulePrivateDNSZones tests private DNS zone creation
func TestNetworkingModulePrivateDNSZones(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/networking",
		Vars: map[string]interface{}{
			"customer_name":       "dns",
			"environment":         "dev",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-dns",
			"vnet_cidr":           "10.0.0.0/16",
			"dns_zone_name":       "test.example.com",
			"create_dns_zone":     false,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify private DNS zones are created
	assert.Contains(t, planOutput, "azurerm_private_dns_zone.zones")
	assert.Contains(t, planOutput, "azurerm_private_dns_zone_virtual_network_link.links")
}

// TestNetworkingModuleNSGRules tests NSG rule configurations
func TestNetworkingModuleNSGRules(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/networking",
		Vars: map[string]interface{}{
			"customer_name":       "nsg",
			"environment":         "prod",
			"location":            "brazilsouth",
			"resource_group_name": "rg-test-nsg",
			"vnet_cidr":           "10.0.0.0/16",
			"dns_zone_name":       "test.example.com",
			"create_dns_zone":     false,
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify NSGs are created with proper naming
	assert.Contains(t, planOutput, "nsg-aks-nodes")
	assert.Contains(t, planOutput, "nsg-private-endpoints")
}

// TestNetworkingModuleBastionConfiguration tests Azure Bastion configuration
func TestNetworkingModuleBastionConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name          string
		enableBastion bool
		expectBastion bool
	}{
		{"bastion_enabled", true, true},
		{"bastion_disabled", false, false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/networking",
				Vars: map[string]interface{}{
					"customer_name":       "bastion",
					"environment":         "dev",
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-bastion",
					"vnet_cidr":           "10.0.0.0/16",
					"dns_zone_name":       "test.example.com",
					"enable_bastion":      tc.enableBastion,
					"create_dns_zone":     false,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			if tc.expectBastion {
				assert.Contains(t, planOutput, "azurerm_bastion_host.main")
				assert.Contains(t, planOutput, "azurerm_public_ip.bastion")
				assert.Contains(t, planOutput, "AzureBastionSubnet")
			} else {
				assert.NotContains(t, planOutput, "azurerm_bastion_host.main")
			}
		})
	}
}

// TestNetworkingModuleEnvironments tests different environment configurations
func TestNetworkingModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/networking",
				Vars: map[string]interface{}{
					"customer_name":       "envtest",
					"environment":         env,
					"location":            "brazilsouth",
					"resource_group_name": "rg-test-" + env,
					"vnet_cidr":           "10.0.0.0/16",
					"dns_zone_name":       "test.example.com",
					"create_dns_zone":     false,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			// Verify environment is reflected in naming
			assert.Contains(t, planOutput, env)
		})
	}
}
