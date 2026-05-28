# Sandbox Isolated Network
# Air-gapped network with no hub peering

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }
  }
  
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.sandbox_subscription_id
}

locals {
  # Auto-generate expiry date 30 days from now
  expiry_date = formatdate("YYYY-MM-DD", timeadd(timestamp(), "720h"))
  
  common_tags = merge(var.default_tags, {
    environment = "sandbox"
    expiry_date = local.expiry_date
    layer       = "sandbox"
  })
}

# Resource group for sandbox network
resource "azurerm_resource_group" "sandbox" {
  name     = "rg-sandbox-${var.primary_region_code}-sandbox-01"
  location = var.primary_region
  tags     = local.common_tags
}

# Isolated sandbox VNet (NO peering)
resource "azurerm_virtual_network" "sandbox" {
  name                = "vnet-sandbox-${var.primary_region_code}-sandbox-01"
  resource_group_name = azurerm_resource_group.sandbox.name
  location            = azurerm_resource_group.sandbox.location
  address_space       = [var.sandbox_address_space]
  tags                = local.common_tags
}

# Sandbox subnet
resource "azurerm_subnet" "sandbox" {
  name                 = "snet-sandbox-default-${var.primary_region_code}-sandbox-01"
  resource_group_name  = azurerm_resource_group.sandbox.name
  virtual_network_name = azurerm_virtual_network.sandbox.name
  address_prefixes     = [cidrsubnet(var.sandbox_address_space, 2, 0)]
}

# NSG for sandbox subnet (allow outbound internet, deny all inbound)
resource "azurerm_network_security_group" "sandbox" {
  name                = "nsg-sandbox-${var.primary_region_code}-sandbox-01"
  resource_group_name = azurerm_resource_group.sandbox.name
  location            = azurerm_resource_group.sandbox.location
  tags                = local.common_tags
  
  security_rule {
    name                       = "Allow-Internet-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
  
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "sandbox" {
  subnet_id                 = azurerm_subnet.sandbox.id
  network_security_group_id = azurerm_network_security_group.sandbox.id
}
