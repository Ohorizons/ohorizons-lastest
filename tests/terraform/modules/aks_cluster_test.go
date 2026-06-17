// =============================================================================
// OPEN HORIZONS PLATFORM - AKS CLUSTER MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform AKS cluster module.
//
// Run with: go test -v -run TestAKS ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestAKSClusterModuleBasic tests basic AKS cluster configuration
func TestAKSClusterModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/aks-cluster",
		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-aks",
			"location":            "brazilsouth",
			"customer_name":       "testaks",
			"environment":         "dev",
			"kubernetes_version":  "1.29",
			"sku_tier":            "Standard",
			"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
			"system_node_pool": map[string]interface{}{
				"name":       "system",
				"vm_size":    "Standard_D4s_v5",
				"node_count": 3,
				"zones":      []string{"1", "2", "3"},
			},
			"workload_identity": true,
			"addons": map[string]interface{}{
				"azure_policy":           true,
				"azure_keyvault_secrets": true,
				"oms_agent":              false,
			},
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
	assert.Contains(t, planOutput, "azurerm_kubernetes_cluster.main")
	assert.Contains(t, planOutput, "aks-testaks-dev")
}

// TestAKSClusterModuleKubernetesVersions tests different K8s versions
func TestAKSClusterModuleKubernetesVersions(t *testing.T) {
	t.Parallel()

	versions := []string{"1.28", "1.29", "1.30"}

	for _, version := range versions {
		version := version
		t.Run("k8s_"+version, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/aks-cluster",
				Vars: map[string]interface{}{
					"resource_group_name": "rg-test-aks",
					"location":            "brazilsouth",
					"customer_name":       "vertest",
					"environment":         "dev",
					"kubernetes_version":  version,
					"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
					"system_node_pool": map[string]interface{}{
						"name":       "system",
						"vm_size":    "Standard_D2s_v5",
						"node_count": 1,
						"zones":      []string{"1"},
					},
				},
				NoColor: true,
			}

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, version)
		})
	}
}

// TestAKSClusterModuleSKUTiers tests different SKU tiers
func TestAKSClusterModuleSKUTiers(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name    string
		skuTier string
	}{
		{"free_tier", "Free"},
		{"standard_tier", "Standard"},
		{"premium_tier", "Premium"},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/aks-cluster",
				Vars: map[string]interface{}{
					"resource_group_name": "rg-test-aks",
					"location":            "brazilsouth",
					"customer_name":       "skutest",
					"environment":         "dev",
					"sku_tier":            tc.skuTier,
					"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
					"system_node_pool": map[string]interface{}{
						"name":       "system",
						"vm_size":    "Standard_D2s_v5",
						"node_count": 1,
						"zones":      []string{"1"},
					},
				},
				NoColor: true,
			}

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, tc.skuTier)
		})
	}
}

// TestAKSClusterModuleNodePools tests node pool configurations
func TestAKSClusterModuleNodePools(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/aks-cluster",
		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-aks",
			"location":            "brazilsouth",
			"customer_name":       "nptest",
			"environment":         "dev",
			"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
			"system_node_pool": map[string]interface{}{
				"name":       "system",
				"vm_size":    "Standard_D4s_v5",
				"node_count": 3,
				"zones":      []string{"1", "2", "3"},
			},
			"user_node_pools": []map[string]interface{}{
				{
					"name":      "user1",
					"vm_size":   "Standard_D8s_v5",
					"min_count": 1,
					"max_count": 10,
					"zones":     []string{"1", "2", "3"},
					"labels": map[string]string{
						"workload": "general",
					},
					"taints": []string{},
				},
				{
					"name":      "gpu",
					"vm_size":   "Standard_NC6s_v3",
					"min_count": 0,
					"max_count": 5,
					"zones":     []string{"1"},
					"labels": map[string]string{
						"workload":       "gpu",
						"accelerator":   "nvidia",
					},
					"taints": []string{"gpu=true:NoSchedule"},
				},
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify node pools are planned
	assert.Contains(t, planOutput, "azurerm_kubernetes_cluster.main")
	assert.Contains(t, planOutput, "azurerm_kubernetes_cluster_node_pool.user")
}

// TestAKSClusterModuleAddons tests AKS addon configurations
func TestAKSClusterModuleAddons(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name   string
		addons map[string]interface{}
	}{
		{
			"all_addons_enabled",
			map[string]interface{}{
				"azure_policy":           true,
				"azure_keyvault_secrets": true,
				"oms_agent":              true,
			},
		},
		{
			"minimal_addons",
			map[string]interface{}{
				"azure_policy":           false,
				"azure_keyvault_secrets": false,
				"oms_agent":              false,
			},
		},
		{
			"security_addons_only",
			map[string]interface{}{
				"azure_policy":           true,
				"azure_keyvault_secrets": true,
				"oms_agent":              false,
			},
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/aks-cluster",
				Vars: map[string]interface{}{
					"resource_group_name": "rg-test-aks",
					"location":            "brazilsouth",
					"customer_name":       "addontest",
					"environment":         "dev",
					"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
					"system_node_pool": map[string]interface{}{
						"name":       "system",
						"vm_size":    "Standard_D2s_v5",
						"node_count": 1,
						"zones":      []string{"1"},
					},
					"addons": tc.addons,
				},
				NoColor: true,
			}

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestAKSClusterModuleWorkloadIdentity tests workload identity configuration
func TestAKSClusterModuleWorkloadIdentity(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name             string
		workloadIdentity bool
	}{
		{"workload_identity_enabled", true},
		{"workload_identity_disabled", false},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/aks-cluster",
				Vars: map[string]interface{}{
					"resource_group_name": "rg-test-aks",
					"location":            "brazilsouth",
					"customer_name":       "witest",
					"environment":         "dev",
					"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
					"system_node_pool": map[string]interface{}{
						"name":       "system",
						"vm_size":    "Standard_D2s_v5",
						"node_count": 1,
						"zones":      []string{"1"},
					},
					"workload_identity": tc.workloadIdentity,
				},
				NoColor: true,
			}

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			if tc.workloadIdentity {
				assert.Contains(t, planOutput, "workload_identity_enabled")
				assert.Contains(t, planOutput, "oidc_issuer_enabled")
			}
		})
	}
}

// TestAKSClusterModuleEnvironments tests different environment configurations
func TestAKSClusterModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/aks-cluster",
				Vars: map[string]interface{}{
					"resource_group_name": "rg-test-aks-" + env,
					"location":            "brazilsouth",
					"customer_name":       "envtest",
					"environment":         env,
					"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
					"system_node_pool": map[string]interface{}{
						"name":       "system",
						"vm_size":    "Standard_D2s_v5",
						"node_count": 1,
						"zones":      []string{"1"},
					},
				},
				NoColor: true,
			}

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			// Verify environment is reflected in naming
			assert.Contains(t, planOutput, "aks-envtest-"+env)
		})
	}
}

// TestAKSClusterModuleValidation tests input validation
func TestAKSClusterModuleValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		shouldError bool
	}{
		{
			name: "valid_inputs",
			vars: map[string]interface{}{
				"resource_group_name": "rg-test-aks",
				"location":            "brazilsouth",
				"customer_name":       "valid",
				"environment":         "dev",
				"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aks",
				"system_node_pool": map[string]interface{}{
					"name":       "system",
					"vm_size":    "Standard_D2s_v5",
					"node_count": 1,
					"zones":      []string{"1"},
				},
			},
			shouldError: false,
		},
		{
			name: "missing_required_var",
			vars: map[string]interface{}{
				"location":      "brazilsouth",
				"customer_name": "test",
				"environment":   "dev",
			},
			shouldError: true,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../../../terraform/modules/aks-cluster",
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
