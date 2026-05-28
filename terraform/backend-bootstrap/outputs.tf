output "storage_account_name" {
  description = "Name of the state storage account"
  value       = azurerm_storage_account.state.name
}

output "resource_group_name" {
  description = "Name of the state resource group"
  value       = azurerm_resource_group.state.name
}

output "container_names" {
  description = "Names of state containers"
  value       = keys(azurerm_storage_container.state_containers)
}

output "backend_config_hcl" {
  description = "Backend configuration for downstream Terraform modules"
  value = <<-EOT
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "<LAYER_SPECIFIC_CONTAINER>"
    key                  = "terraform.tfstate"
  EOT
}

output "next_steps" {
  description = "Next steps after bootstrap"
  value = <<-EOT
    Bootstrap complete! Next steps:
    
    1. Copy this backend config to your backend.hcl files:
       ${self.backend_config_hcl}
    
    2. If using private endpoints, configure network access now:
       az storage account update --name ${azurerm_storage_account.state.name} --public-network-access Disabled
    
    3. Configure GitHub OIDC federation with storage account access
    
    4. Deploy management groups: cd ../live/global && terraform init -backend-config=backend.hcl
  EOT
}
