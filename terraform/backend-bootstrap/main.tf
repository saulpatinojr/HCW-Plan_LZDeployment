# Terraform Backend Bootstrap
# This creates the storage account for remote state management
# Run this once locally before using remote state

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.management_subscription_id
}

# Random suffix for globally unique storage account name
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# Resource group for state backend
resource "azurerm_resource_group" "state" {
  name     = "rg-tfstate-${var.primary_region_code}-prod-01"
  location = var.primary_region
  tags     = merge(var.default_tags, {
    purpose = "Terraform State Backend"
  })
}

# Storage account for state files
resource "azurerm_storage_account" "state" {
  name                     = "st${var.org_prefix}tfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "RAGZRS"
  account_kind             = "StorageV2"
  
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true
  
  # Security
  public_network_access_enabled = var.allow_public_access_during_setup
  
  blob_properties {
    versioning_enabled = true
    change_feed_enabled = true
    
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
  }
  
  tags = merge(var.default_tags, {
    purpose = "Terraform State Storage"
  })
}

# State containers for each layer
resource "azurerm_storage_container" "state_containers" {
  for_each = toset([
    "global-mgmt-groups",
    "global-policies",
    "platform-connectivity",
    "platform-management",
    "platform-identity",
    "workloads-prod",
    "workloads-nonprod",
    "sandbox-isolation"
  ])
  
  name                  = each.key
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}

# Log Analytics workspace for diagnostics
resource "azurerm_log_analytics_workspace" "state" {
  name                = "log-tfstate-${var.primary_region_code}-prod-01"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = var.default_tags
}

# Diagnostic settings for state storage account
resource "azurerm_monitor_diagnostic_setting" "state" {
  name                       = "diag-state-storage"
  target_resource_id         = azurerm_storage_account.state.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.state.id
  
  enabled_log {
    category = "StorageRead"
  }
  
  enabled_log {
    category = "StorageWrite"
  }
  
  enabled_log {
    category = "StorageDelete"
  }
  
  metric {
    category = "Transaction"
  }
}
