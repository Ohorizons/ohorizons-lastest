# =============================================================================
# Terraform settings, provider requirements, and backend
# =============================================================================
# The Terraform settings block is declared here and only here. A module may
# hold at most one `required_providers` block and one default (non-aliased)
# provider configuration, so splitting them across files makes `terraform init`
# fail before it can install anything.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }

  # Remote state is intentionally left commented out. The backend cannot be
  # initialised until the state storage account exists and the pipeline is
  # authenticated, so an active block here would break the first
  # `terraform init` in the generated repository. Uncomment it after running
  # `scripts/setup-azure-oidc.sh`.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "${{ values.projectName }}.tfstate"
  # }
}

provider "azurerm" {
  features {}
}
