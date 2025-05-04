resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id          = var.tenant_id
  sku_name           = var.environment == "prod" ? "premium" : "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod" ? true : false
  
  enabled_for_disk_encryption = true
  enable_rbac_authorization  = true

  network_acls {
    bypass                    = "AzureServices"
    default_action           = "Deny"
    ip_rules                = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = merge(var.default_tags, {
    Environment = var.environment
  })
}

# Create secrets for application
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.kv.id
}

# Grant AKS managed identity access to Key Vault
resource "azurerm_role_assignment" "aks_kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_principal_id
}