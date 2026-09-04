# =============================================================================
# ${{ values.projectName }} - Infrastructure
# =============================================================================
# Terraform settings, provider requirements, and the backend live in
# providers.tf. Declaring them again here would be a duplicate configuration
# and `terraform init` would refuse to run.
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-${{ values.projectName }}-${var.environment}"
  location = var.location

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Add your resources here
# -----------------------------------------------------------------------------
