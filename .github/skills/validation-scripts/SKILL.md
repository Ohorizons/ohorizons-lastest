---
name: validation-scripts
description: "Validation scripts for deployment and configuration verification. USE FOR: validate deployment, validate configuration, validate prerequisites, run validation scripts, post-deploy checks. DO NOT USE FOR: Terraform validation (use terraform-cli), Kubernetes checks (use kubectl-cli), CI/CD pipelines (use @devops)."
---

## When to Use
- Pre-deployment validation
- Post-deployment verification
- Configuration compliance checks
- Naming convention validation

## Prerequisites
- Bash shell
- Required CLI tools (az, kubectl, terraform, gh)
- Appropriate permissions for target resources

## Available Scripts

### validate-prerequisites.sh
```bash
# Validates all required CLI tools are installed
./scripts/validate-prerequisites.sh
```

### validate-config.sh
```bash
# Validates configuration files
./scripts/validate-config.sh --environment <env>
```

### validate-deployment.sh
```bash
# Validates deployment status
./scripts/validate-deployment.sh --environment <env>
```

### validate-agents.sh
```bash
# Validates agent configuration files
./scripts/validate-agents.sh
```

### validate-docs.sh
```bash
# Validates documentation files
./scripts/validate-docs.sh
```

## Best Practices
1. Run validation before any deployment
2. Include validation in CI/CD pipelines
3. Document validation failures clearly
4. Exit with non-zero code on failure
5. Provide remediation steps

## Output Format
1. Script executed
2. Validation results (pass/fail)
3. Details of any failures
4. Remediation recommendations

## Integration with Agents
Used by: @test, @devops, @sre
