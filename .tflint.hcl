# =============================================================================
# TFLINT CONFIGURATION
# =============================================================================
#
# TFLint is a Terraform linter focused on possible errors, best practices, etc.
#
# Documentation: https://github.com/terraform-linters/tflint
#
# =============================================================================

config {
  format = "compact"
  plugin_dir = "~/.tflint.d/plugins"

  module = true
  force = false
  disabled_by_default = false
}

# =============================================================================
# PLUGINS
# =============================================================================

plugin "terraform" {
  enabled = true
  version = "0.5.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.26.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# =============================================================================
# TERRAFORM RULES
# =============================================================================

# Disallow terraform declarations without required_version
rule "terraform_required_version" {
  enabled = true
}

# Disallow terraform declarations without require_providers
rule "terraform_required_providers" {
  enabled = true
}

# Disallow legacy dot index syntax
rule "terraform_deprecated_index" {
  enabled = true
}

# Disallow variables, data sources, and locals that are declared but never used
rule "terraform_unused_declarations" {
  enabled = true
}

# Disallow // comments in favor of #
rule "terraform_comment_syntax" {
  enabled = true
}

# Disallow output declarations without description
rule "terraform_documented_outputs" {
  enabled = true
}

# Disallow variable declarations without description
rule "terraform_documented_variables" {
  enabled = true
}

# Disallow variable declarations without type
rule "terraform_typed_variables" {
  enabled = true
}

# Enforce naming conventions
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"

  custom_formats = {
    extended_snake_case = {
      description = "Extended snake case with hyphens allowed"
      regex       = "^[a-z][a-z0-9_-]*$"
    }
  }

  module {
    format = "snake_case"
  }

  variable {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  data {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }
}

# Ensure that a module complies with the Terraform Standard Module Structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Disallow specifying a git or mercurial repository as a module source without pinning to a version
rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}

# Ensure that a provider version constraint is specified in the required_providers block
rule "terraform_module_version" {
  enabled = true
  exact   = false
}

# =============================================================================
# AZURE RULES
# =============================================================================

# Ensure AKS cluster has network policy enabled
rule "azurerm_kubernetes_cluster_network_policy" {
  enabled = true
}

# Ensure AKS cluster has Azure Policy enabled
rule "azurerm_kubernetes_cluster_azure_policy" {
  enabled = true
}

# Disallow deprecated VM sizes
rule "azurerm_virtual_machine_invalid_vm_size" {
  enabled = true
}

# =============================================================================
# CUSTOM RULES - DISABLED BY DEFAULT
# =============================================================================

# These rules may be too strict for some projects

# Disallow empty blocks
rule "terraform_empty_list_equality" {
  enabled = false
}

# Enforce workspace usage
rule "terraform_workspace_remote" {
  enabled = false
}
