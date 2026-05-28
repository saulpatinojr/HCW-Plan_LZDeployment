variable "region" {
  description = "Azure region"
  type        = string
}

variable "region_code" {
  description = "Short region code (e.g., scus, ncus)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "hub_address_space" {
  description = "Address space for hub VNet (e.g., 10.0.0.0/16)"
  type        = string
}

variable "firewall_type" {
  description = "Firewall type: azfw, palo, or fortinet"
  type        = string
  
  validation {
    condition     = contains(["azfw", "palo", "fortinet"], var.firewall_type)
    error_message = "Firewall type must be one of: azfw, palo, fortinet."
  }
}

variable "azfw_tier" {
  description = "Azure Firewall tier (Standard or Premium)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.azfw_tier)
    error_message = "Azure Firewall tier must be Standard or Premium."
  }
}

variable "nva_trust_ip_placeholder" {
  description = "Placeholder IP for NVA trust interface (used until NVA deployed)"
  type        = string
  default     = "10.0.1.4"
}

variable "deploy_bastion_placeholder" {
  description = "Create Bastion subnet placeholder"
  type        = bool
  default     = true
}

variable "deploy_dns_placeholder" {
  description = "Create DNS resolver subnet placeholders"
  type        = bool
  default     = true
}

variable "management_ip_ranges" {
  description = "IP ranges allowed to access firewall management (CIDR or '*')"
  type        = string
  default     = "*"
}

variable "availability_zones" {
  description = "Availability zones for zonal resources"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
