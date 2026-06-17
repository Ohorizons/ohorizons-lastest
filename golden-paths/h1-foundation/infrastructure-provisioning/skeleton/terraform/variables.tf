variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "centralus"

  validation {
    condition     = contains(["centralus", "eastus"], var.location)
    error_message = "Only Central US and East US."
  }
}

variable "project_name" {
  type = string
}
