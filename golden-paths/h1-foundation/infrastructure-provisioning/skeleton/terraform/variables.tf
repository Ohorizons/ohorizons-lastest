variable "environment" {
  description = "Deployment environment for this workload."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region the resources are created in."
  type        = string
  default     = "centralus"

  validation {
    condition     = contains(["centralus", "eastus", "brazilsouth"], var.location)
    error_message = "Location must be centralus, eastus, or brazilsouth."
  }
}

variable "tags" {
  description = "Tags applied to every resource in this configuration."
  type        = map(string)
  default = {
    project     = "${{ values.projectName }}"
    environment = "${{ values.environment }}"
    managed-by  = "terraform"
    owner       = "${{ values.owner }}"
  }
}
