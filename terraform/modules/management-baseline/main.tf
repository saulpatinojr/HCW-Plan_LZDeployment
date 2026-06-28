# Management Baseline Module
# Provides Log Analytics, Automation Account, and monitoring foundations

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }
  }
}

data "azurerm_client_config" "current" {}

# Management Resource Group
resource "azurerm_resource_group" "management" {
  name     = "rg-${var.org_prefix}-management"
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace - Central logging hub
resource "azurerm_log_analytics_workspace" "alz" {
  name                = "law-${var.org_prefix}-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Automation Account - For operational management and runbooks
resource "azurerm_automation_account" "alz" {
  name                = "aa-${var.org_prefix}-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku_name            = "Basic"

  tags = var.tags
}

# Link Log Analytics to Automation Account for integrated monitoring
resource "azurerm_log_analytics_linked_service" "alz" {
  resource_group_name = azurerm_resource_group.management.name
  workspace_id        = azurerm_log_analytics_workspace.alz.id
  linked_service_name = "Automation"

  linked_service_properties {
    resource_id = azurerm_automation_account.alz.id
  }
}

# Application Insights - For application-level monitoring
resource "azurerm_application_insights" "alz" {
  name                = "appi-${var.org_prefix}-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  application_type    = "other"
  workspace_id        = azurerm_log_analytics_workspace.alz.id

  tags = var.tags
}

# Action Group - For alert notifications
resource "azurerm_monitor_action_group" "alz" {
  name                = "ag-${var.org_prefix}-${var.region_code}"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = substr("alz-${var.org_prefix}", 0, 12)

  tags = var.tags
}

# Alert Rule - CPU > 80%
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "alert-cpu-${var.org_prefix}"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_log_analytics_workspace.alz.id]
  description         = "Alert when CPU exceeds 80%"
  severity            = 2
  enabled             = true
  frequency           = "PT5M"
  window_size         = "PT15M"
  aggregation         = "Average"

  criteria {
    metric_name      = "\\Processor(_Total)\\% Processor Time"
    metric_namespace = "Microsoft.Compute/virtualMachines"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.alz.id
  }
}
