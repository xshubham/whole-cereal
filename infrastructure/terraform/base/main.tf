terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate random suffix for unique names
resource "random_string" "resource_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${terraform.workspace}"
  location = var.location

  tags = merge(var.default_tags, {
    Environment = terraform.workspace
  })
}

# Include other modules
module "aks" {
  source = "../modules/aks"
  
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  cluster_name       = "${var.cluster_name}-${terraform.workspace}"
  node_count         = lookup(var.node_count, terraform.workspace, 1)
  node_size         = lookup(var.node_size, terraform.workspace, "Standard_D2s_v3")
  kubernetes_version = var.kubernetes_version
  environment       = terraform.workspace
  default_tags      = var.default_tags
}

module "acr" {
  source = "../modules/acr"
  
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  acr_name           = "acr${terraform.workspace}${random_string.resource_suffix.result}"
  environment        = terraform.workspace
  default_tags       = var.default_tags
}

module "monitoring" {
  source = "../modules/monitoring"
  
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  workspace_name     = "${var.log_analytics_workspace_name}-${terraform.workspace}"
  environment        = terraform.workspace
  default_tags       = var.default_tags
}

module "key_vault" {
  source = "../modules/key_vault"
  
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  key_vault_name     = "${var.key_vault_name}-${terraform.workspace}-${random_string.resource_suffix.result}"
  tenant_id          = data.azurerm_client_config.current.tenant_id
  environment        = terraform.workspace
  default_tags       = var.default_tags
}

# Get current client configuration
data "azurerm_client_config" "current" {}