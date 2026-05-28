variable "sandbox_subscription_id" {
  description = "Sandbox subscription ID"
  type        = string
}

variable "primary_region" {
  description = "Primary Azure region"
  type        = string
  default     = "southcentralus"
}

variable "primary_region_code" {
  description = "Primary region code"
  type        = string
  default     = "scus"
}

variable "sandbox_address_space" {
  description = "Address space for sandbox VNet"
  type        = string
  default     = "10.99.0.0/16"
}

variable "default_tags" {
  description = "Default tags (environment and expiry_date will be auto-set)"
  type        = map(string)
  default = {
    owner       = "Sandbox Users"
    application = "Sandbox Experimentation"
    cost_center = "IT-Platform"
    managed_by  = "Terraform"
  }
}
