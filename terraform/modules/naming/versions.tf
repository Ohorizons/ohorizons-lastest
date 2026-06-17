# =============================================================================
# TERRAFORM VERSION AND PROVIDER REQUIREMENTS
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # No providers required - this is a pure naming module
    # It only uses locals and outputs
  }
}
