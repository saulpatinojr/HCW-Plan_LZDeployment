variable "management_subscription_id" {
  description = "Management subscription ID"
  type        = string
}

variable "sandbox_subscription_id" {
  description = "Sandbox subscription ID for cleanup automation"
  type        = string
}

variable "primary_region" {
  description = "Primary Azure region"
  type        = string
  default     = "southcentralus"
}

variable "primary_region_code" {
  description = "Primary region short code"
  type        = string
  default     = "scus"
}

variable "dr_region" {
  description = "DR Azure region"
  type        = string
  default     = "northcentralus"
}

variable "dr_region_code" {
  description = "DR region short code"
  type        = string
  default     = "ncus"
}

variable "default_tags" {
  description = "Default tags"
  type        = map(string)
  default = {
    owner       = "Platform Team"
    application = "Landing Zone Management"
    environment = "prod"
    cost_center = "IT-Platform"
    managed_by  = "Terraform"
  }
}
