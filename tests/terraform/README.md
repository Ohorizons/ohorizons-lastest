# Terraform Tests

This directory contains automated tests for Terraform modules using [Terratest](https://terratest.gruntwork.io/).

## Prerequisites

- Go 1.21+
- Terraform 1.5+
- Azure CLI (authenticated)

## Directory Structure

```
tests/terraform/
├── README.md           # This file
├── go.mod              # Go module definition
├── go.sum              # Go dependencies
├── helpers/            # Test helper functions
│   └── terraform.go
└── modules/            # Module tests
    ├── naming_test.go
    ├── networking_test.go
    └── aks_test.go
```

## Running Tests

### Run All Tests

```bash
cd tests/terraform
go test -v -timeout 30m ./...
```

### Run Specific Module Tests

```bash
# Test naming module only
go test -v -run TestNamingModule ./modules/

# Test networking module only
go test -v -run TestNetworkingModule ./modules/

# Test with specific tags
go test -v -tags=unit ./...
```

### Run Tests with Parallelism

```bash
go test -v -parallel 4 -timeout 60m ./...
```

## Test Types

### Unit Tests

Unit tests validate Terraform configurations without creating real resources.

```bash
go test -v -tags=unit ./...
```

### Integration Tests

Integration tests create real Azure resources (requires Azure credentials).

```bash
# Set required environment variables
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"

go test -v -tags=integration -timeout 60m ./...
```

## Writing New Tests

### Basic Test Structure

```go
package modules

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestMyModule(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../../terraform/modules/my-module",
        Vars: map[string]interface{}{
            "customer_name": "test",
            "environment":   "dev",
        },
    })

    // Clean up resources when the test completes
    defer terraform.Destroy(t, terraformOptions)

    // Deploy the infrastructure
    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    output := terraform.Output(t, terraformOptions, "some_output")
    assert.NotEmpty(t, output)
}
```

### Plan-Only Tests (No Resources Created)

```go
func TestMyModulePlanOnly(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../../terraform/modules/my-module",
        Vars: map[string]interface{}{
            "customer_name": "test",
        },
        PlanFilePath: "/tmp/plan.out",
    }

    terraform.Init(t, terraformOptions)
    terraform.Plan(t, terraformOptions)
}
```

## CI Integration

Tests are automatically run in the CI pipeline via `.github/workflows/terraform-test.yml`:

- **On Pull Request**: Unit tests only (fast)
- **On Merge to Main**: Full integration tests
- **Scheduled**: Weekly full test suite

## Troubleshooting

### Common Issues

1. **Timeout errors**: Increase `-timeout` parameter
2. **Azure auth errors**: Verify `az login` or environment variables
3. **Resource conflicts**: Use unique names with `random` module

### Cleanup Failed Resources

If tests fail and leave resources behind:

```bash
# Find test resource groups
az group list --query "[?contains(name, 'terratest')].name" -o tsv

# Delete specific resource group
az group delete --name "rg-terratest-xxx" --yes --no-wait
```

## Best Practices

1. **Use `t.Parallel()`** for independent tests
2. **Always use `defer terraform.Destroy()`** for integration tests
3. **Use unique names** with random suffixes
4. **Keep tests focused** - one behavior per test
5. **Use table-driven tests** for multiple scenarios
6. **Tag tests** appropriately (unit, integration)
