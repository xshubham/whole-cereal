resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                = "Standard"
  admin_enabled      = true

  tags = merge(var.default_tags, {
    Environment = var.environment
  })
}

# Assign AcrPull role to AKS if provided
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.aks_principal_id != "" ? 1 : 0
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_principal_id
}